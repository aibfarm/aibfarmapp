// lib/components/positions_table.dart
import 'package:flutter/material.dart';
import '../models/farm_data.dart';

class PositionsTable extends StatefulWidget {
  final List<PositionData> positions;

  const PositionsTable({super.key, required this.positions});

  @override
  State<PositionsTable> createState() => _PositionsTableState();
}

class _PositionsTableState extends State<PositionsTable>
    with TickerProviderStateMixin {
  
  // 存储每个币种的前一个价格，用于检测变化
  final Map<String, double> _previousPrices = {};
  
  // 存储每个币种的动画控制器
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<Color?>> _colorAnimations = {};

  @override
  void initState() {
    super.initState();
    _initializePrices();
  }

  @override
  void didUpdateWidget(PositionsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkPriceChanges();
  }

  @override
  void dispose() {
    // 清理所有动画控制器
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializePrices() {
    for (var position in widget.positions) {
      _previousPrices[position.coin] = position.markPrice;
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
      
      // 创建颜色动画，默认为透明
      _colorAnimations[coin] = ColorTween(
        begin: Colors.transparent,
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }
  }

  void _checkPriceChanges() {
    for (var position in widget.positions) {
      final coin = position.coin;
      final currentPrice = position.markPrice;
      final previousPrice = _previousPrices[coin];

      _setupAnimationForCoin(coin);

      if (previousPrice != null && previousPrice != currentPrice) {
        // 检测价格变化方向
        if (currentPrice > previousPrice) {
          // 价格上涨 - 绿色闪烁
          _triggerFlashAnimation(coin, Colors.green);
        } else if (currentPrice < previousPrice) {
          // 价格下跌 - 红色闪烁  
          _triggerFlashAnimation(coin, Colors.red);
        }
      }

      // 更新存储的价格
      _previousPrices[coin] = currentPrice;
    }
  }

  void _triggerFlashAnimation(String coin, Color flashColor) {
    final controller = _animationControllers[coin];
    if (controller != null) {
      // 重新设置颜色动画
      _colorAnimations[coin] = ColorTween(
        begin: flashColor.withOpacity(0.7),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      // 重置并开始动画
      controller.reset();
      controller.forward();
    }
  }

  Widget _buildAnimatedPriceCell({
    required String coin,
    required String priceText,
    required TextStyle textStyle,
    required int flex,
  }) {
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
            child: Text(
              priceText,
              style: textStyle,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 确保新币种有动画控制器
    for (var position in widget.positions) {
      _setupAnimationForCoin(position.coin);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '加仓潜标【跟踪】',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        if (widget.positions.isEmpty)
          Container(
            height: 80,
            child: const Center(
              child: Text(
                '暂无潜标数据',
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
                  ...widget.positions.map((position) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    ),
                    child: Row(
                      children: [
                        // 币种 - 不需要动画
                        Expanded(
                          flex: 2, 
                          child: Text(
                            position.coin,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue),
                          )
                        ),
                        // 限价 - 不需要动画
                        Expanded(
                          flex: 3, 
                          child: Text(
                            position.addPositionPrice.toStringAsFixed(4),
                            style: TextStyle(
                              fontSize: 10,
                              color: position.addPositionPrice > position.markPrice ? Colors.red : Colors.green,
                            ),
                          )
                        ),
                        // 价位 - 添加闪烁动画
                        _buildAnimatedPriceCell(
                          coin: position.coin,
                          priceText: position.markPrice.toStringAsFixed(4),
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          flex: 3,
                        ),
                        // 保证金 - 不需要动画
                        Expanded(
                          flex: 3, 
                          child: Text(
                            '\$${position.insure.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 10, color: Colors.purple),
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