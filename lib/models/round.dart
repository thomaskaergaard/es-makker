// Round model – stores each player's score for a single round
class Round {
  final int roundNumber;

  /// Maps player name → score for this round
  final Map<String, int> scores;

  /// The player who won the bid (spiller/caller). Optional.
  final String? caller;

  /// The caller's partner for this round (makker). Optional.
  final String? partner;

  const Round({
    required this.roundNumber,
    required this.scores,
    this.caller,
    this.partner,
  });

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'scores': scores,
        if (caller != null) 'caller': caller,
        if (partner != null) 'partner': partner,
      };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        roundNumber: json['roundNumber'] as int,
        scores: Map<String, int>.from(json['scores'] as Map),
        caller: json['caller'] as String?,
        partner: json['partner'] as String?,
      );

  @override
  String toString() => 'Round($roundNumber, $scores, caller: $caller, partner: $partner)';
}
