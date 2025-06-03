import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  WebSocketChannel? _wsChannel;
  WebSocketChannel? _positionsChannel;
  String _dataSource = '等待连接...';
  
  // 只保存真实数据，不设置模拟数据
  Map<String, dynamic>? _farmData;
  List<Map<String, dynamic>> _positions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    _positionsChannel?.sink.close();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token == null || userJson == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    setState(() {
      _user = jsonDecode(userJson);
      _isLoading = false;
    });

    // 立即尝试连接WebSocket获取真实数据
    _connectToRealData(token);
  }

  // 安全的数值转换函数
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _connectToRealData(String token) {
    // 连接常量数据
    final constantEndpoint = 'wss://farm-api.aibfarm.com/okrice.ConstantVaule?token=$token';
    _tryConnectEndpoint([constantEndpoint], 0);
    
    // 连接仓位数据
    final positionsEndpoint = 'wss://farm-api.aibfarm.com/okrice.positions?token=$token';
    _connectPositions(positionsEndpoint, token);
  }

  void _connectPositions(String endpoint, String token) {
    try {
      print('连接仓位数据: $endpoint');
      
      _positionsChannel = WebSocketChannel.connect(Uri.parse(endpoint));
      
      _positionsChannel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            if (jsonData is List) {
              setState(() {
                _positions = jsonData.map<Map<String, dynamic>>((item) {
                  // 提取币种名称（去掉-USDT-SWAP后缀）
                  String coinName = item['id']?.toString() ?? '';
                  if (coinName.contains('-USDT-SWAP')) {
                    coinName = coinName.split('-USDT-SWAP')[0];
                  }
                  
                  return {
                    'coin': coinName,
                    'limitPrice': _parseToDouble(item['AddPositionPrice']),
                    'currentPrice': _parseToDouble(item['MarkPrice']),
                    'margin': _parseToDouble(item['Insure']),
                    'marginRatio': _parseToDouble(item['MarginRatio']),
                  };
                }).toList();
                
                // 更新保险倍数（使用第一个仓位的MarginRatio）
                if (_positions.isNotEmpty && _farmData != null) {
                  _farmData!['MarginRatio'] = _positions[0]['marginRatio'];
                }
              });
            }
          } catch (e) {
            print('仓位数据解析错误: $e');
          }
        },
        onError: (error) {
          print('仓位WebSocket错误: $error');
          _positionsChannel?.sink.close();
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              _connectPositions(endpoint, token);
            }
          });
        },
        onDone: () {
          print('仓位WebSocket连接断开，尝试重连...');
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectPositions(endpoint, token);
            }
          });
        },
      );
    } catch (e) {
      print('仓位连接错误: $e');
    }
  }

  void _tryConnectEndpoint(List<String> endpoints, int index) {
    if (index >= endpoints.length) {
      setState(() {
        _dataSource = '连接失败';
      });
      return;
    }

    try {
      final endpoint = endpoints[index];
      print('尝试连接: $endpoint');
      
      setState(() {
        _dataSource = '连接中...';
      });

      _wsChannel = WebSocketChannel.connect(Uri.parse(endpoint));
      
      _wsChannel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            print('收到真实数据: $jsonData');
            
            setState(() {
              // 安全解析真实数据
              _farmData = {
                'AviableU': _parseToDouble(jsonData['AviableU']),
                'UnPnl': _parseToDouble(jsonData['UnPnl']),
                'ProfitLast24Hour': _parseToDouble(jsonData['ProfitLast24Hour']),
                'ProfitLast7Day': _parseToDouble(jsonData['ProfitLast7Day']),
                'ProfitLast30Day': _parseToDouble(jsonData['ProfitLast30Day']),
                'MarginRatio': _parseToDouble(jsonData['MarginRatio']),
                'SettlementAIB': _parseToDouble(jsonData['SettlementAIB']),
              };
              _dataSource = '实时数据';
            });
          } catch (e) {
            print('数据解析错误: $e');
            setState(() {
              _dataSource = '解析错误';
            });
          }
        },
        onError: (error) {
          print('WebSocket错误 $index: $error');
          _wsChannel?.sink.close();
          setState(() {
            _dataSource = '连接错误';
          });
          _tryConnectEndpoint(endpoints, index + 1);
        },
        onDone: () {
          print('WebSocket连接断开，尝试重连...');
          setState(() {
            _dataSource = '重新连接中...';
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _tryConnectEndpoint(endpoints, 0);
            }
          });
        },
      );
    } catch (e) {
      print('连接错误 $index: $e');
      setState(() {
        _dataSource = '连接失败';
      });
      _tryConnectEndpoint(endpoints, index + 1);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _wsChannel?.sink.close();
    _positionsChannel?.sink.close();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _connectToRealData(token);
    }
  }

  Widget _buildDataCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    bool isSmall = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: isSmall ? 14 : 18),
                SizedBox(width: isSmall ? 4 : 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmall ? 8 : 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 6 : 8),
            // 关键：只对数值做弹性处理，防止溢出
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionsTable() {
    if (_positions.isEmpty) {
      return Container(
        height: 80,
        child: const Center(
          child: Text(
            '暂无仓位数据',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('币种', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 3, child: Text('限价', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 3, child: Text('价位', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 3, child: Text('保证金', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // 表格数据
            ..._positions.map((position) => Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2, 
                    child: Text(
                      position['coin'].toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue),
                    )
                  ),
                  Expanded(
                    flex: 3, 
                    child: Text(
                      position['limitPrice'].toStringAsFixed(4),
                      style: TextStyle(
                        fontSize: 10,
                        color: position['limitPrice'] > position['currentPrice'] ? Colors.red : Colors.green,
                      ),
                    )
                  ),
                  Expanded(
                    flex: 3, 
                    child: Text(
                      position['currentPrice'].toStringAsFixed(4),
                      style: const TextStyle(fontSize: 10),
                    )
                  ),
                  Expanded(
                    flex: 3, 
                    child: Text(
                      '\$${position['margin'].toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 10, color: Colors.purple),
                    )
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AIBFarm 仪表板'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎区域
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '欢迎回来',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user?['name'] ?? '用户',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                '资金概览',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 12),
              
              // 显示数据
              if (_farmData != null) ...[
                // 主要数据
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildDataCard(
                      title: '可用资金',
                      value: '\$${_farmData!['AviableU'].toStringAsFixed(2)}',
                      color: Colors.green,
                      icon: Icons.account_balance_wallet,
                    ),
                    _buildDataCard(
                      title: '浮动盈亏',
                      value: '\$${_farmData!['UnPnl'].toStringAsFixed(2)}',
                      color: _farmData!['UnPnl'] >= 0 ? Colors.green : Colors.red,
                      icon: Icons.trending_up,
                    ),
                    _buildDataCard(
                      title: '保险倍数',
                      value: '${_farmData!['MarginRatio'].toStringAsFixed(0)}倍',
                      color: Colors.blue,
                      icon: Icons.security,
                    ),
                    _buildDataCard(
                      title: '香火钱',
                      value: '${_farmData!['SettlementAIB'].toStringAsFixed(0)}AIB',
                      color: Colors.purple,
                      icon: Icons.monetization_on,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  '盈利统计',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 12),
                
                // 盈利数据
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  children: [
                    _buildDataCard(
                      title: '24小时',
                      value: '\$${_farmData!['ProfitLast24Hour'].toStringAsFixed(2)}',
                      color: _farmData!['ProfitLast24Hour'] >= 0 ? Colors.green : Colors.red,
                      icon: Icons.access_time,
                      isSmall: true,
                    ),
                    _buildDataCard(
                      title: '7天',
                      value: '\$${_farmData!['ProfitLast7Day'].toStringAsFixed(2)}',
                      color: _farmData!['ProfitLast7Day'] >= 0 ? Colors.green : Colors.red,
                      icon: Icons.date_range,
                      isSmall: true,
                    ),
                    _buildDataCard(
                      title: '30天',
                      value: '\$${_farmData!['ProfitLast30Day'].toStringAsFixed(2)}',
                      color: _farmData!['ProfitLast30Day'] >= 0 ? Colors.green : Colors.red,
                      icon: Icons.calendar_month,
                      isSmall: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 仓位跟踪表格
                const Text(
                  '加仓潜标【跟踪】',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 12),
                
                // 仓位数据表格
                _buildPositionsTable(),
              ] else ...[
                // 等待数据时显示
                Container(
                  height: 200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('等待真实数据...'),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // 连接状态
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _dataSource == '实时数据' 
                              ? Colors.green 
                              : (_dataSource.contains('连接') 
                                  ? Colors.orange 
                                  : Colors.red),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '数据来源: $_dataSource',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}