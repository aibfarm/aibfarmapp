// lib/components/open_positions_table.dart
import 'package:flutter/material.dart';
import '../models/farm_data.dart';

class OpenPositionsTable extends StatefulWidget {
  final List<OpenPosition> openPositions;

  const OpenPositionsTable({super.key, required this.openPositions});

  @override
  State<OpenPositionsTable> createState() => _OpenPositionsTableState();
}

class _OpenPositionsTableState extends State<OpenPositionsTable>
    with TickerProviderStateMixin {
  
  // 存储每个币种的前一个利润，用于检测变化
  final Map<String, double> _previousProfits = {};
  
  // 存储每个币种的动画控制器
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<Color?>> _colorAnimations = {};

  @override
  void initState() {
    super.initState();
    _initializeProfits();
  }

  @override
  void didUpdateWidget(OpenPositionsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkProfitChanges();
  }

  @override
  void dispose() {
    // 清理所有动画控制器
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeProfits() {
    for (var position in widget.openPositions) {
      _previousProfits[position.coin] = position.profit;
      _setupAnimationForCoin(position.coin);
    }
  }

  void _setupAnimationForCoin(String coin) {
    if (!_animationControllers.containsKey(coin)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: this,
      );
      
      _animationControllers[coin] = controller;
      
      _colorAnimations[coin] = ColorTween(
        begin: Colors.transparent,
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }
  }

  void _checkProfitChanges() {
    for (var position in widget.openPositions) {
      final coin = position.coin;
      final currentProfit = position.profit;
      final previousProfit = _previousProfits[coin];

      _setupAnimationForCoin(coin);

      if (previousProfit != null && previousProfit != currentProfit) {
        // 检测利润变化方向
        if (currentProfit > previousProfit) {
          // 利润增加 - 绿色闪烁
          _triggerFlashAnimation(coin, Colors.green);
        } else if (currentProfit < previousProfit) {
          // 利润减少 - 红色闪烁  
          _triggerFlashAnimation(coin, Colors.red);
        }
      }

      // 更新存储的利润
      _previousProfits[coin] = currentProfit;
    }
  }

  void _triggerFlashAnimation(String coin, Color flashColor) {
    final controller = _animationControllers[coin];
    if (controller != null) {
      _colorAnimations[coin] = ColorTween(
        begin: flashColor.withOpacity(0.7),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      controller.reset();
      controller.forward();
    }
  }

  Widget _buildAnimatedCell({
    required String coin,
    required String text,
    required TextStyle textStyle,
    required int flex,
    bool animate = false,
  }) {
    if (!animate) {
      return Expanded(
        flex: flex,
        child: Text(text, style: textStyle),
      );
    }

    return Expanded(
      flex: flex,
      child: AnimatedBuilder(
        animation: _colorAnimations[coin] ?? 
                   const AlwaysStoppedAnimation(Colors.transparent),
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: _colorAnimations[coin]?.value ?? Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(text, style: textStyle),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 确保所有币种都有动画控制器
    for (var position in widget.openPositions) {
      _setupAnimationForCoin(position.coin);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '已开仓【后继续 -- 加仓 或 减仓获利】',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        if (widget.openPositions.isEmpty)
          Container(
            height: 80,
            child: const Center(
              child: Text(
                '暂无已开仓数据',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          )
        else
          Card(
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('币种', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('收益', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('持仓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('利润', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('价位', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 表格数据
                  ...widget.openPositions.map((position) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    ),
                    child: Row(
                      children: [
                        // 币种
                        Expanded(
                          flex: 2, 
                          child: Text(
                            position.coin,
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.w600, 
                              color: position.positionSideColor,
                            ),
                          )
                        ),
                        // 收益
                        Expanded(
                          flex: 2, 
                          child: Text(
                            '${position.yield.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: position.yield >= 0 ? Colors.green : Colors.red,
                            ),
                          )
                        ),
                        // 持仓 - 使用保证金*杠杆计算持仓价值
                        Expanded(
                          flex: 2, 
                          child: Text(
                            '\$${(position.insure * position.lever).toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 10),
                          )
                        ),
                        // 利润 - 添加闪烁动画
                        _buildAnimatedCell(
                          coin: position.coin,
                          text: '\$${position.profit.toStringAsFixed(1)}',
                          textStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: position.profit >= 0 ? Colors.green : Colors.red,
                          ),
                          flex: 2,
                          animate: true,
                        ),
                        // 价位
                        Expanded(
                          flex: 2, 
                          child: Text(
                            position.markPrice.toStringAsFixed(4),
                            style: const TextStyle(fontSize: 10),
                          )
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
      ],
    );
  }
}