// lib/services/websocket_service.dart - 修复保险倍数问题
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/farm_data.dart';

class WebSocketService {
  WebSocketChannel? _constantChannel;
  WebSocketChannel? _potentialsChannel;
  WebSocketChannel? _positionsChannel;
  
  final StreamController<FarmData> _farmDataController = StreamController<FarmData>.broadcast();
  final StreamController<List<PositionData>> _positionsController = StreamController<List<PositionData>>.broadcast();
  final StreamController<List<OpenPosition>> _openPositionsController = StreamController<List<OpenPosition>>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  // 保存当前的农场数据，用于更新保险倍数
  FarmData? _currentFarmData;

  // 公开的流
  Stream<FarmData> get farmDataStream => _farmDataController.stream;
  Stream<List<PositionData>> get positionsStream => _positionsController.stream;
  Stream<List<OpenPosition>> get openPositionsStream => _openPositionsController.stream;
  Stream<String> get statusStream => _statusController.stream;

  void connect(String token) {
    _connectConstantData(token);
    _connectPotentialsData(token);
    _connectPositionsData(token);
  }

  void _connectConstantData(String token) {
    try {
      final endpoint = 'wss://farm-api.aibfarm.com/okrice.ConstantVaule?token=$token';
      print('连接常量数据: $endpoint');
      
      _statusController.add('连接中...');
      
      _constantChannel = WebSocketChannel.connect(Uri.parse(endpoint));
      
      _constantChannel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            print('收到常量数据: $jsonData');
            
            final farmData = FarmData.fromJson(jsonData);
            _currentFarmData = farmData; // 保存当前数据
            _farmDataController.add(farmData);
            _statusController.add('实时数据');
          } catch (e) {
            print('常量数据解析错误: $e');
            _statusController.add('解析错误');
          }
        },
        onError: (error) {
          print('常量WebSocket错误: $error');
          _statusController.add('连接错误');
          _reconnectConstantData(token);
        },
        onDone: () {
          print('常量WebSocket连接断开，尝试重连...');
          _statusController.add('重新连接中...');
          _reconnectConstantData(token);
        },
      );
    } catch (e) {
      print('常量连接错误: $e');
      _statusController.add('连接失败');
    }
  }

  void _connectPotentialsData(String token) {
    try {
      final endpoint = 'wss://farm-api.aibfarm.com/okrice.potentials?token=$token';
      print('连接潜标数据: $endpoint');
      
      _potentialsChannel = WebSocketChannel.connect(Uri.parse(endpoint));
      
      _potentialsChannel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            print('收到潜标数据: $jsonData');
            
            if (jsonData is List) {
              final positions = jsonData
                  .map<PositionData>((item) => PositionData.fromJson(item))
                  .toList();
              _positionsController.add(positions);
              
              // 🔥 关键修复：从潜标数据更新保险倍数
              _updateMarginRatioFromPositions(jsonData);
            }
          } catch (e) {
            print('潜标数据解析错误: $e');
          }
        },
        onError: (error) {
          print('潜标WebSocket错误: $error');
          _reconnectPotentialsData(token);
        },
        onDone: () {
          print('潜标WebSocket连接断开，尝试重连...');
          _reconnectPotentialsData(token);
        },
      );
    } catch (e) {
      print('潜标连接错误: $e');
    }
  }

  void _connectPositionsData(String token) {
    try {
      final endpoint = 'wss://farm-api.aibfarm.com/okrice.positions?token=$token';
      print('🔗 连接已开仓数据: $endpoint');
      
      _positionsChannel = WebSocketChannel.connect(Uri.parse(endpoint));
      
      _positionsChannel!.stream.listen(
        (data) {
          try {
            print('📦 收到原始数据长度: ${data.length} 字符');
            
            final jsonData = jsonDecode(data);
            print('📋 解析后数据类型: ${jsonData.runtimeType}');
            
            if (jsonData is List) {
              print('📊 原始数据条数: ${jsonData.length}');
              
              // 🔥 关键修复：从已开仓数据更新保险倍数
              _updateMarginRatioFromPositions(jsonData);
              
              final openPositions = <OpenPosition>[];
              int skippedCount = 0;
              int errorCount = 0;
              
              for (int i = 0; i < jsonData.length; i++) {
                final item = jsonData[i];
                try {
                  if (item.containsKey('id') && 
                      item.containsKey('OpenQuantity') && 
                      item.containsKey('Profit') && 
                      item.containsKey('Pos')) {
                    
                    final openPosition = OpenPosition.fromJson(item);
                    
                    if (openPosition.openQuantity > 0) {
                      openPositions.add(openPosition);
                    } else {
                      skippedCount++;
                    }
                  } else {
                    errorCount++;
                  }
                } catch (e) {
                  print('💥 解析单个数据失败 [$i]: $e');
                  errorCount++;
                }
              }
              
              if (openPositions.isNotEmpty) {
                openPositions.sort((a, b) => b.profit.compareTo(a.profit));
                final top10 = openPositions.take(10).toList();
                _openPositionsController.add(top10);
              } else {
                _openPositionsController.add([]);
              }
            } else {
              _openPositionsController.add([]);
            }
          } catch (e) {
            print('💥 已开仓数据解析错误: $e');
            _openPositionsController.add([]);
          }
        },
        onError: (error) {
          print('🔥 已开仓WebSocket错误: $error');
          _reconnectPositionsData(token);
        },
        onDone: () {
          print('🔌 已开仓WebSocket连接断开，尝试重连...');
          _reconnectPositionsData(token);
        },
      );
    } catch (e) {
      print('💥 已开仓连接错误: $e');
    }
  }

  // 🔥 新增方法：从positions数据更新保险倍数
  void _updateMarginRatioFromPositions(List<dynamic> positionsData) {
    if (_currentFarmData != null && positionsData.isNotEmpty) {
      try {
        // 取第一个仓位的MarginRatio作为保险倍数
        final firstPosition = positionsData[0];
        if (firstPosition is Map<String, dynamic> && firstPosition.containsKey('MarginRatio')) {
          final marginRatio = _parseToDouble(firstPosition['MarginRatio']);
          
          print('🔄 更新保险倍数: $marginRatio');
          
          // 创建新的FarmData，只更新保险倍数
          final updatedFarmData = FarmData(
            aviableU: _currentFarmData!.aviableU,
            unPnl: _currentFarmData!.unPnl,
            profitLast24Hour: _currentFarmData!.profitLast24Hour,
            profitLast7Day: _currentFarmData!.profitLast7Day,
            profitLast30Day: _currentFarmData!.profitLast30Day,
            marginRatio: marginRatio, // 使用positions数据中的保险倍数
            settlementAIB: _currentFarmData!.settlementAIB,
          );
          
          _currentFarmData = updatedFarmData;
          _farmDataController.add(updatedFarmData);
        }
      } catch (e) {
        print('更新保险倍数失败: $e');
      }
    }
  }

  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _reconnectConstantData(String token) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_constantChannel?.closeCode != null) {
        _connectConstantData(token);
      }
    });
  }

  void _reconnectPotentialsData(String token) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_potentialsChannel?.closeCode != null) {
        _connectPotentialsData(token);
      }
    });
  }

  void _reconnectPositionsData(String token) {
    Future.delayed(const Duration(seconds: 3), () {
      if (_positionsChannel?.closeCode != null) {
        _connectPositionsData(token);
      }
    });
  }

  void refresh(String token) {
    print('🔄 刷新所有WebSocket连接');
    disconnect();
    Future.delayed(const Duration(milliseconds: 500), () {
      connect(token);
    });
  }

  void disconnect() {
    print('🔌 断开所有WebSocket连接');
    _constantChannel?.sink.close();
    _potentialsChannel?.sink.close();
    _positionsChannel?.sink.close();
    
    _constantChannel = null;
    _potentialsChannel = null;
    _positionsChannel = null;
  }

  void dispose() {
    disconnect();
    _farmDataController.close();
    _positionsController.close();
    _openPositionsController.close();
    _statusController.close();
  }
}