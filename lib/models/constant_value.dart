class ConstantValue {
  final String? okriceVersion;
  final bool? tradingON;
  final double? aviableU;
  final double? unPnl;
  final double? profitLast24Hour;
  final double? profitLast7Day;
  final double? profitLast30Day;
  final double? settlementAIB;
  final String? masterName;
  final double? masterRate;
  final String? nickname;
  final String? masterID;
  final String? betaCandidate;
  final double? marginRatio;

  ConstantValue({
    this.okriceVersion,
    this.tradingON,
    this.aviableU,
    this.unPnl,
    this.profitLast24Hour,
    this.profitLast7Day,
    this.profitLast30Day,
    this.settlementAIB,
    this.masterName,
    this.masterRate,
    this.nickname,
    this.masterID,
    this.betaCandidate,
    this.marginRatio,
  });

  factory ConstantValue.fromJson(Map<String, dynamic> json) {
    return ConstantValue(
      okriceVersion: json['OKRICE_VERSION'] as String?,
      tradingON: json['TradingON'] as bool?,
      aviableU: (json['AviableU'] as num?)?.toDouble(),
      unPnl: (json['UnPnl'] as num?)?.toDouble(),
      profitLast24Hour: (json['ProfitLast24Hour'] as num?)?.toDouble(),
      profitLast7Day: (json['ProfitLast7Day'] as num?)?.toDouble(),
      profitLast30Day: (json['ProfitLast30Day'] as num?)?.toDouble(),
      settlementAIB: (json['SettlementAIB'] as num?)?.toDouble(),
      masterName: json['MasterName'] as String?,
      masterRate: (json['MasterRate'] as num?)?.toDouble(),
      nickname: json['Nickname'] as String?,
      masterID: json['MasterID'] as String?,
      betaCandidate: json['BetaCandidate'] as String?,
      marginRatio: (json['MarginRatio'] as num?)?.toDouble(),
    );
  }
}