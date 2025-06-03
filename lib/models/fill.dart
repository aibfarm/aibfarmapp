class Fill {
  final String? instId;
  final String? side;
  final String? posSide;
  final double? fillPx;
  final double? fillPnl;
  final double? fillSz;
  final int? ts;

  Fill({
    this.instId,
    this.side,
    this.posSide,
    this.fillPx,
    this.fillPnl,
    this.fillSz,
    this.ts,
  });

  factory Fill.fromJson(Map<String, dynamic> json) {
    return Fill(
      instId: json['instId'] as String?,
      side: json['side'] as String?,
      posSide: json['posSide'] as String?,
      fillPx: (json['fillPx'] as num?)?.toDouble(),
      fillPnl: (json['fillPnl'] as num?)?.toDouble(),
      fillSz: (json['fillSz'] as num?)?.toDouble(),
      ts: json['ts'] as int?,
    );
  }
}