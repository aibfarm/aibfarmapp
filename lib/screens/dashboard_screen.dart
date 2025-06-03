// lib/screens/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../models/farm_data.dart';
import '../components/data_cards.dart';
import '../components/positions_table.dart' as PotentialsTable;
import '../components/open_positions_table.dart' as OpenPos;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  
  final WebSocketService _wsService = WebSocketService();
  
  FarmData? _farmData;
  List<PositionData> _positions = [];
  List<OpenPosition> _openPositions = [];
  String _dataSource = '等待连接...';

  @override
  void initState() {
    super.initState();
    print('🚀 DashboardScreen initState');
    // 先设置监听器，再加载用户数据
    _setupWebSocketListeners();
    _loadUserData();
  }

  @override
  void dispose() {
    print('🔚 DashboardScreen dispose');
    _wsService.dispose();
    super.dispose();
  }

  void _setupWebSocketListeners() {
    print('🔌 设置WebSocket监听器');
    
    // 监听农场数据
    _wsService.farmDataStream.listen((farmData) {
      print('📊 收到农场数据流更新');
      if (mounted) {
        setState(() {
          _farmData = farmData;
        });
      }
    });

    // 监听仓位数据（潜标）
    _wsService.positionsStream.listen((positions) {
      print('📋 收到潜标数据流更新: ${positions.length}条');
      if (mounted) {
        setState(() {
          _positions = positions;
        });
      }
    });

    // 监听已开仓数据 - 关键修正
    _wsService.openPositionsStream.listen((openPositions) {
      print('🎯 [Dashboard] 收到已开仓数据流更新: ${openPositions.length}条');
      if (openPositions.isNotEmpty) {
        print('🎯 [Dashboard] 前3个币种: ${openPositions.take(3).map((p) => '${p.coin}:\$${p.profit.toStringAsFixed(2)}').join(', ')}');
      }
      
      if (mounted) {
        setState(() {
          _openPositions = openPositions;
          print('🎯 [Dashboard] UI状态已更新，_openPositions长度: ${_openPositions.length}');
        });
        
        // 强制触发重新构建
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            print('🎯 [Dashboard] 强制重建，当前_openPositions: ${_openPositions.length}');
          }
        });
      } else {
        print('⚠️ [Dashboard] Widget已销毁，跳过UI更新');
      }
    }, onError: (error) {
      print('❌ [Dashboard] 已开仓数据流错误: $error');
    });

    // 监听连接状态
    _wsService.statusStream.listen((status) {
      print('📡 连接状态更新: $status');
      if (mounted) {
        setState(() {
          _dataSource = status;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    print('👤 加载用户数据');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token == null || userJson == null) {
      print('❌ Token或用户数据缺失，跳转到登录页');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _user = jsonDecode(userJson);
        _isLoading = false;
      });
    }

    print('✅ 用户数据加载完成，开始连接WebSocket');
    
    // 确保在下一帧连接WebSocket，让监听器有时间准备
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _wsService.connect(token);
      }
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _wsService.disconnect();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _refreshData() async {
    print('🔄 手动刷新数据');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _wsService.refresh(token);
    }
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    if (_dataSource == '实时数据') {
      statusColor = Colors.green;
    } else if (_dataSource.contains('连接')) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '数据来源: $_dataSource',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 16),
            // 显示已开仓数据计数
            Text(
              '已开仓: ${_openPositions.length}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
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
    );
  }

  Widget _buildLoadingState() {
    return Container(
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
    );
  }

  Widget _buildDebugInfo() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('调试信息:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('农场数据: ${_farmData != null ? "✅" : "❌"}', style: TextStyle(fontSize: 10)),
            Text('潜标数据: ${_positions.length}条', style: TextStyle(fontSize: 10)),
            Text('已开仓数据: ${_openPositions.length}条', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
            if (_openPositions.isNotEmpty) 
              Text('前3个: ${_openPositions.take(3).map((p) => p.coin).join(', ')}', style: TextStyle(fontSize: 10, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [Dashboard] 构建UI，已开仓数据: ${_openPositions.length}条');
    
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
              _buildWelcomeCard(),
              
              const SizedBox(height: 16),
              
              // 调试信息 - 帮助排查问题
              _buildDebugInfo(),
              
              const SizedBox(height: 16),
              
              // 数据展示
              if (_farmData != null) ...[
                DataCards(farmData: _farmData!),
                const SizedBox(height: 16),
                
                // 已开仓数据表格 - 强制显示，即使数据为空
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('已开仓组件测试 (数据条数: ${_openPositions.length})', 
                               style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('当前状态: ${_openPositions.isEmpty ? "❌ 无数据" : "✅ 有数据"}',
                               style: TextStyle(color: _openPositions.isEmpty ? Colors.red : Colors.green)),
                          if (_openPositions.isNotEmpty)
                            Text('币种列表: ${_openPositions.map((p) => p.coin).take(5).join(', ')}'),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    OpenPos.OpenPositionsTable(openPositions: _openPositions),
                  ],
                ),
                
                const SizedBox(height: 16),
                PotentialsTable.PositionsTable(positions: _positions),
              ] else ...[
                _buildLoadingState(),
              ],
              
              const SizedBox(height: 16),
              
              // 连接状态
              _buildStatusIndicator(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}