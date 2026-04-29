import 'dart:convert';
import 'player.dart';
import 'round.dart';

/// Holds the full state of a game session.
class GameState {
  final List<Player> players;
  final List<Round> rounds;

  const GameState({required this.players, this.rounds = const []});

  int get currentRoundNumber => rounds.length + 1;

  /// Returns the cumulative score for each player across all completed rounds.
  Map<String, int> get totalScores {
    final totals = <String, int>{
      for (final p in players) p.name: 0,
    };
    for (final round in rounds) {
      for (final entry in round.scores.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  /// Returns a new [GameState] with the given round added.
  GameState addRound(
    Map<String, int> scores, {
    String? caller,
    String? partner,
  }) {
    return GameState(
      players: players,
      rounds: [
        ...rounds,
        Round(
          roundNumber: currentRoundNumber,
          scores: scores,
          caller: caller,
          partner: partner,
        ),
      ],
    );
  }

  /// Returns a new [GameState] with the last round removed.
  GameState undoLastRound() {
    if (rounds.isEmpty) return this;
    return GameState(
      players: players,
      rounds: rounds.sublist(0, rounds.length - 1),
    );
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        rounds: ((json['rounds'] as List?) ?? const [])
            .map((r) => Round.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory GameState.fromJsonString(String jsonString) =>
      GameState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
