class TakeProfit {
  final String? id;
  final String? pos;
  final double? highestYield;
  final double? takeProfitYield;
  final double? yield;
  final double? yieldGainLV;
  final double? insure;
  final double? insureLV;
  final double? markPrice;
  final double? profit;
  final double? fundingFee;

  TakeProfit({
    this.id,
    this.pos,
    this.highestYield,
    this.takeProfitYield,
    this.yield,
    this.yieldGainLV,
    this.insure,
    this.insureLV,
    this.markPrice,
    this.profit,
    this.fundingFee,
  });

  factory TakeProfit.fromJson(Map<String, dynamic> json) {
    return TakeProfit(
      id: json['id'] as String?,
      pos: json['Pos'] as String?,
      highestYield: (json['HighestYeild'] as num?)?.toDouble(),
      takeProfitYield: (json['TakeProfitYeild'] as num?)?.toDouble(),
      yield: (json['Yeild'] as num?)?.toDouble(),
      yieldGainLV: (json['YieldGainLV'] as num?)?.toDouble(),
      insure: (json['Insure'] as num?)?.toDouble(),
      insureLV: (json['InsureLV'] as num?)?.toDouble(),
      markPrice: (json['MarkPrice'] as num?)?.toDouble(),
      profit: (json['Profit'] as num?)?.toDouble(),
      fundingFee: (json['FundingFee'] as num?)?.toDouble(),
    );
  }
}