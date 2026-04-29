/// Represents a bid in Es Makker.
///
/// A bid specifies:
/// - [tricksNeeded]: the minimum number of tricks the caller's team must win.
/// - [pointsPerTrick]: how many points each trick counts for scoring.
///
/// Bids are ordered: 2i9 < 3i9 < 4i9 < 2i10 < 3i10 < 4i10.
class Bid {
  final int pointsPerTrick;
  final int tricksNeeded;

  const Bid({required this.pointsPerTrick, required this.tricksNeeded});

  /// All valid bids in ascending order (lowest to highest).
  static const List<Bid> allBids = [
    Bid(pointsPerTrick: 2, tricksNeeded: 9),
    Bid(pointsPerTrick: 3, tricksNeeded: 9),
    Bid(pointsPerTrick: 4, tricksNeeded: 9),
    Bid(pointsPerTrick: 2, tricksNeeded: 10),
    Bid(pointsPerTrick: 3, tricksNeeded: 10),
    Bid(pointsPerTrick: 4, tricksNeeded: 10),
  ];

  /// Danish label, e.g. "2 i 9" or "3 i 10".
  String get label => '$pointsPerTrick i $tricksNeeded';

  int get _rank => allBids.indexWhere(
        (b) =>
            b.tricksNeeded == tricksNeeded &&
            b.pointsPerTrick == pointsPerTrick,
      );

  /// Returns true if this bid is strictly higher than [other].
  bool isHigherThan(Bid other) => _rank > other._rank;

  Map<String, dynamic> toJson() => {
        'pointsPerTrick': pointsPerTrick,
        'tricksNeeded': tricksNeeded,
      };

  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
        pointsPerTrick: json['pointsPerTrick'] as int,
        tricksNeeded: json['tricksNeeded'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bid &&
          pointsPerTrick == other.pointsPerTrick &&
          tricksNeeded == other.tricksNeeded;

  @override
  int get hashCode => Object.hash(pointsPerTrick, tricksNeeded);

  @override
  String toString() => label;
}
