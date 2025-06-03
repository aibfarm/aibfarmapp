class Potential {
  final String? id;
  final bool? isBanned;
  final double? addPositionPrice;
  final double? markPrice;
  final double? insure;
  final double? insureLV;
  final double? yield;
  final double? yieldLossLV;
  final double? positionFundAmount;
  final int? attempCounter;
  final String? lastAddPositionTime;

  Potential({
    this.id,
    this.isBanned,
    this.addPositionPrice,
    this.markPrice,
    this.insure,
    this.insureLV,
    this.yield,
    this.yieldLossLV,
    this.positionFundAmount,
    this.attempCounter,
    this.lastAddPositionTime,
  });

  factory Potential.fromJson(Map<String, dynamic> json) {
    return Potential(
      id: json['id'] as String?,
      isBanned: json['IsBanned'] as bool?,
      addPositionPrice: (json['AddPositionPrice'] as num?)?.toDouble(),
      markPrice: (json['MarkPrice'] as num?)?.toDouble(),
      insure: (json['Insure'] as num?)?.toDouble(),
      insureLV: (json['InsureLV'] as num?)?.toDouble(),
      yield: (json['Yeild'] as num?)?.toDouble(),
      yieldLossLV: (json['YieldLossLV'] as num?)?.toDouble(),
      positionFundAmount: (json['PositionFundAmount'] as num?)?.toDouble(),
      attempCounter: json['AttempCounter'] as int?,
      lastAddPositionTime: json['LastAddPositionTime'] as String?,
    );
  }
}