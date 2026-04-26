// Round model – stores each player's score for a single round
class Round {
  final int roundNumber;

  /// Maps player name → score for this round
  final Map<String, int> scores;

  const Round({required this.roundNumber, required this.scores});

  Map<String, dynamic> toJson() => {
        'roundNumber': roundNumber,
        'scores': scores,
      };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        roundNumber: json['roundNumber'] as int,
        scores: Map<String, int>.from(json['scores'] as Map),
      );

  @override
  String toString() => 'Round($roundNumber, $scores)';
}
