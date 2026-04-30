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
        players: _toList(json['players'])
            .map((p) => Player.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList(),
        rounds: _toList(json['rounds'])
            .map((r) => Round.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );

  /// Firebase Realtime Database stores JSON arrays as maps with sequential
  /// integer keys (e.g. `{0: {...}, 1: {...}}`). This helper converts such
  /// maps back to a [List] while also handling normal [List] values and nulls.
  static List<dynamic> _toList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value;
    if (value is Map) {
      final sorted = value.entries.toList()
        ..sort((a, b) => (a.key as int).compareTo(b.key as int));
      return sorted.map((e) => e.value).toList();
    }
    return const [];
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameState.fromJsonString(String jsonString) =>
      GameState.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
