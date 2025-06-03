class Position {
  final String? id;
  final bool? isBanned;
  final double? yield;
  final String? pos;
  final double? fundingRate;
  final double? markPrice;
  final double? openQuantity;
  final double? profit;
  final double? insure;
  final double? lever;
  final String? lastAddPositionTime;
  
  // 添加可能的额外字段
  final double? marginRatio;
  final String? lastUpdate;

  Position({
    this.id,
    this.isBanned,
    this.yield,
    this.pos,
    this.fundingRate,
    this.markPrice,
    this.openQuantity,
    this.profit,
    this.insure,
    this.lever,
    this.lastAddPositionTime,
    this.marginRatio,
    this.lastUpdate,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as String?,
      isBanned: json['IsBanned'] as bool?,
      yield: _parseDouble(json['Yeild'] ?? json['Yield']),
      pos: json['Pos'] as String?,
      fundingRate: _parseDouble(json['FundingRate']),
      markPrice: _parseDouble(json['MarkPrice']),
      openQuantity: _parseDouble(json['OpenQuantity']),
      profit: _parseDouble(json['Profit']),
      insure: _parseDouble(json['Insure']),
      lever: _parseDouble(json['Lever']),
      lastAddPositionTime: json['LastAddPositionTime'] as String?,
      marginRatio: _parseDouble(json['MarginRatio']),
      lastUpdate: json['LastUpdate'] as String?,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() {
    return 'Position{id: $id, pos: $pos, profit: $profit, insure: $insure}';
  }
}