// lib/models/farm_data.dart
import 'package:flutter/material.dart';

class FarmData {
  final double aviableU;
  final double unPnl;
  final double profitLast24Hour;
  final double profitLast7Day;
  final double profitLast30Day;
  final double marginRatio;
  final double settlementAIB;

  FarmData({
    required this.aviableU,
    required this.unPnl,
    required this.profitLast24Hour,
    required this.profitLast7Day,
    required this.profitLast30Day,
    required this.marginRatio,
    required this.settlementAIB,
  });

  factory FarmData.fromJson(Map<String, dynamic> json) {
    return FarmData(
      aviableU: _parseToDouble(json['AviableU']),
      unPnl: _parseToDouble(json['UnPnl']),
      profitLast24Hour: _parseToDouble(json['ProfitLast24Hour']),
      profitLast7Day: _parseToDouble(json['ProfitLast7Day']),
      profitLast30Day: _parseToDouble(json['ProfitLast30Day']),
      marginRatio: _parseToDouble(json['MarginRatio']),
      settlementAIB: _parseToDouble(json['SettlementAIB']),
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class PositionData {
  final String coin;
  final double addPositionPrice;   // 限价
  final double markPrice;          // 价位
  final double insure;             // 保证金
  final double marginRatio;        // 保险倍数

  PositionData({
    required this.coin,
    required this.addPositionPrice,
    required this.markPrice,
    required this.insure,
    required this.marginRatio,
  });

  factory PositionData.fromJson(Map<String, dynamic> json) {
    // 提取币种名称（去掉-USDT-SWAP后缀）
    String coinName = json['id']?.toString() ?? '';
    if (coinName.contains('-USDT-SWAP')) {
      coinName = coinName.split('-USDT-SWAP')[0];
    }

    return PositionData(
      coin: coinName,
      addPositionPrice: FarmData._parseToDouble(json['AddPositionPrice']),
      markPrice: FarmData._parseToDouble(json['MarkPrice']),
      insure: FarmData._parseToDouble(json['Insure']),
      marginRatio: FarmData._parseToDouble(json['MarginRatio']),
    );
  }
}

// 已开仓数据模型 - 修正版本，匹配HTML中的字段
class OpenPosition {
  final String coin;
  final double yield;          // 收益% (HTML中是Yeild)
  final double markPrice;      // 价位 (MarkPrice)
  final double openQuantity;   // 持仓数量 (OpenQuantity)
  final double profit;         // 利润 (Profit)
  final String positionSide;   // 多空方向 (Pos: long/short)
  final double fundingRate;    // 费率 (FundingRate)
  final double insure;         // 保证金 (Insure)
  final double lever;          // 杠杆 (Lever)
  final bool isBanned;         // 是否被禁用 (IsBanned)

  OpenPosition({
    required this.coin,
    required this.yield,
    required this.markPrice,
    required this.openQuantity,
    required this.profit,
    required this.positionSide,
    required this.fundingRate,
    required this.insure,
    required this.lever,
    required this.isBanned,
  });

  factory OpenPosition.fromJson(Map<String, dynamic> json) {
    // 提取币种名称（去掉-USDT-SWAP后缀）
    String coinName = json['id']?.toString() ?? '';
    if (coinName.contains('-USDT-SWAP')) {
      coinName = coinName.split('-USDT-SWAP')[0];
    }

    return OpenPosition(
      coin: coinName,
      yield: FarmData._parseToDouble(json['Yeild']),  // 注意HTML中的拼写是Yeild
      markPrice: FarmData._parseToDouble(json['MarkPrice']),
      openQuantity: FarmData._parseToDouble(json['OpenQuantity']),
      profit: FarmData._parseToDouble(json['Profit']),
      positionSide: json['Pos']?.toString() ?? '',
      fundingRate: FarmData._parseToDouble(json['FundingRate']),
      insure: FarmData._parseToDouble(json['Insure']),
      lever: FarmData._parseToDouble(json['Lever']),
      isBanned: json['IsBanned'] == true,
    );
  }

  // 获取多空方向的中文显示
  String get positionSideText {
    switch (positionSide) {
      case 'long':
        return '多';
      case 'short':
        return '空';
      default:
        return positionSide;
    }
  }

  // 获取多空方向的颜色
  Color get positionSideColor {
    switch (positionSide) {
      case 'long':
        return Colors.green;
      case 'short':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}