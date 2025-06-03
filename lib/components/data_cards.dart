// lib/components/data_cards.dart
import 'package:flutter/material.dart';
import '../models/farm_data.dart';

class DataCards extends StatelessWidget {
  final FarmData farmData;

  const DataCards({super.key, required this.farmData});

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '资金概览',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // 主要数据 - 两列布局
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
              value: '\$${farmData.aviableU.toStringAsFixed(2)}',
              color: Colors.green,
              icon: Icons.account_balance_wallet,
            ),
            _buildDataCard(
              title: '浮动盈亏',
              value: '\$${farmData.unPnl.toStringAsFixed(2)}',
              color: farmData.unPnl >= 0 ? Colors.green : Colors.red,
              icon: Icons.trending_up,
            ),
            _buildDataCard(
              title: '保险倍数',
              value: '${farmData.marginRatio.toStringAsFixed(0)}倍',
              color: Colors.blue,
              icon: Icons.security,
            ),
            _buildDataCard(
              title: '香火钱',
              value: '${farmData.settlementAIB.toStringAsFixed(0)}AIB',
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
        
        // 盈利数据 - 三列布局
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
              value: '\$${farmData.profitLast24Hour.toStringAsFixed(2)}',
              color: farmData.profitLast24Hour >= 0 ? Colors.green : Colors.red,
              icon: Icons.access_time,
              isSmall: true,
            ),
            _buildDataCard(
              title: '7天',
              value: '\$${farmData.profitLast7Day.toStringAsFixed(2)}',
              color: farmData.profitLast7Day >= 0 ? Colors.green : Colors.red,
              icon: Icons.date_range,
              isSmall: true,
            ),
            _buildDataCard(
              title: '30天',
              value: '\$${farmData.profitLast30Day.toStringAsFixed(2)}',
              color: farmData.profitLast30Day >= 0 ? Colors.green : Colors.red,
              icon: Icons.calendar_month,
              isSmall: true,
            ),
          ],
        ),
      ],
    );
  }
}