import 'package:test/test.dart';
import 'package:es_makker/models/player.dart';
import 'package:es_makker/models/game_state.dart';

void main() {
  group('Player', () {
    test('creates player with name', () {
      const player = Player(name: 'Alice');
      expect(player.name, 'Alice');
    });

    test('serialises and deserialises correctly', () {
      const player = Player(name: 'Bob');
      final json = player.toJson();
      final restored = Player.fromJson(json);
      expect(restored.name, player.name);
    });
  });

  group('GameState', () {
    final players = [
      const Player(name: 'Alice'),
      const Player(name: 'Bob'),
    ];

    test('starts at round 1 with no rounds', () {
      final state = GameState(players: players);
      expect(state.currentRoundNumber, 1);
      expect(state.rounds, isEmpty);
    });

    test('adds a round and increments round number', () {
      final state = GameState(players: players);
      final newState = state.addRound({'Alice': 10, 'Bob': -5});
      expect(newState.rounds.length, 1);
      expect(newState.currentRoundNumber, 2);
    });

    test('calculates total scores correctly', () {
      final state = GameState(players: players)
          .addRound({'Alice': 10, 'Bob': -5})
          .addRound({'Alice': 5, 'Bob': 20});
      final totals = state.totalScores;
      expect(totals['Alice'], 15);
      expect(totals['Bob'], 15);
    });

    test('undo removes last round', () {
      final state = GameState(players: players)
          .addRound({'Alice': 10, 'Bob': -5})
          .addRound({'Alice': 5, 'Bob': 20});
      final undone = state.undoLastRound();
      expect(undone.rounds.length, 1);
      expect(undone.currentRoundNumber, 2);
      expect(undone.totalScores['Alice'], 10);
      expect(undone.totalScores['Bob'], -5);
    });

    test('undo on empty state returns same state', () {
      final state = GameState(players: players);
      final result = state.undoLastRound();
      expect(result.rounds, isEmpty);
    });

    test('serialises and deserialises correctly', () {
      final state = GameState(players: players)
          .addRound({'Alice': 10, 'Bob': -5});
      final json = state.toJsonString();
      final restored = GameState.fromJsonString(json);
      expect(restored.players.length, 2);
      expect(restored.rounds.length, 1);
      expect(restored.totalScores['Alice'], 10);
    });
  });
}
