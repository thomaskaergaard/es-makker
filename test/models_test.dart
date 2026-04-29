import 'package:test/test.dart';
import 'package:es_makker/models/player.dart';
import 'package:es_makker/models/round.dart';
import 'package:es_makker/models/game_state.dart';
import 'package:es_makker/models/bid.dart';

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

  group('Round', () {
    test('creates round without caller/partner', () {
      const round = Round(roundNumber: 1, scores: {'Alice': 10});
      expect(round.caller, isNull);
      expect(round.partner, isNull);
    });

    test('creates round with caller and partner', () {
      const round = Round(
        roundNumber: 1,
        scores: {'Alice': 5, 'Bob': 5, 'Carol': -5, 'Dave': -5},
        caller: 'Alice',
        partner: 'Bob',
      );
      expect(round.caller, 'Alice');
      expect(round.partner, 'Bob');
    });

    test('serialises and deserialises caller/partner correctly', () {
      const round = Round(
        roundNumber: 2,
        scores: {'Alice': 10, 'Bob': -10},
        caller: 'Alice',
        partner: 'Bob',
      );
      final json = round.toJson();
      final restored = Round.fromJson(json);
      expect(restored.caller, 'Alice');
      expect(restored.partner, 'Bob');
      expect(restored.roundNumber, 2);
    });

    test('serialises round without caller/partner (omits keys)', () {
      const round = Round(roundNumber: 1, scores: {'Alice': 5});
      final json = round.toJson();
      expect(json.containsKey('caller'), isFalse);
      expect(json.containsKey('partner'), isFalse);
    });

    test('deserialises round without caller/partner as null', () {
      final round = Round.fromJson({'roundNumber': 1, 'scores': {'Alice': 5}});
      expect(round.caller, isNull);
      expect(round.partner, isNull);
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

    test('adds a round with caller and partner', () {
      final state = GameState(players: players);
      final newState = state.addRound(
        {'Alice': 10, 'Bob': -10},
        caller: 'Alice',
        partner: 'Bob',
      );
      expect(newState.rounds.first.caller, 'Alice');
      expect(newState.rounds.first.partner, 'Bob');
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

    test('serialises and deserialises rounds with caller/partner', () {
      final state = GameState(players: players).addRound(
        {'Alice': 10, 'Bob': -10},
        caller: 'Alice',
        partner: 'Bob',
      );
      final restored = GameState.fromJsonString(state.toJsonString());
      expect(restored.rounds.first.caller, 'Alice');
      expect(restored.rounds.first.partner, 'Bob');
    });
  });

  group('Bid', () {
    test('label formats correctly', () {
      expect(const Bid(pointsPerTrick: 2, tricksNeeded: 9).label, '2 i 9');
      expect(const Bid(pointsPerTrick: 4, tricksNeeded: 10).label, '4 i 10');
    });

    test('allBids has 6 entries in ascending order', () {
      expect(Bid.allBids.length, 6);
      for (var i = 1; i < Bid.allBids.length; i++) {
        expect(Bid.allBids[i].isHigherThan(Bid.allBids[i - 1]), isTrue);
      }
    });

    test('isHigherThan: 3i9 is higher than 2i9', () {
      const low = Bid(pointsPerTrick: 2, tricksNeeded: 9);
      const high = Bid(pointsPerTrick: 3, tricksNeeded: 9);
      expect(high.isHigherThan(low), isTrue);
      expect(low.isHigherThan(high), isFalse);
    });

    test('isHigherThan: 2i10 is higher than 4i9', () {
      const fourIn9 = Bid(pointsPerTrick: 4, tricksNeeded: 9);
      const twoIn10 = Bid(pointsPerTrick: 2, tricksNeeded: 10);
      expect(twoIn10.isHigherThan(fourIn9), isTrue);
      expect(fourIn9.isHigherThan(twoIn10), isFalse);
    });

    test('equality', () {
      const a = Bid(pointsPerTrick: 2, tricksNeeded: 9);
      const b = Bid(pointsPerTrick: 2, tricksNeeded: 9);
      const c = Bid(pointsPerTrick: 3, tricksNeeded: 9);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('serialises and deserialises', () {
      const bid = Bid(pointsPerTrick: 3, tricksNeeded: 10);
      final json = bid.toJson();
      final restored = Bid.fromJson(json);
      expect(restored, bid);
    });
  });
}
