import 'package:test/test.dart';
import 'package:es_makker/models/playing_card.dart';
import 'package:es_makker/models/play_state.dart';
import 'package:es_makker/models/bid.dart';

void main() {
  group('PlayingCard', () {
    test('equals and hashCode', () {
      const a = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      const b = PlayingCard(suit: Suit.spades, rank: Rank.ace);
      const c = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('shortName', () {
      const card = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      expect(card.shortName, 'K♥');
    });

    test('beats: trump beats non-trump', () {
      const trump = PlayingCard(suit: Suit.spades, rank: Rank.two);
      const nonTrump = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      expect(trump.beats(nonTrump, Suit.hearts, Suit.spades), isTrue);
    });

    test('beats: higher rank wins within same suit', () {
      const high = PlayingCard(suit: Suit.hearts, rank: Rank.king);
      const low = PlayingCard(suit: Suit.hearts, rank: Rank.five);
      expect(high.beats(low, Suit.hearts, null), isTrue);
      expect(low.beats(high, Suit.hearts, null), isFalse);
    });

    test('beats: following lead beats non-following', () {
      const follows = PlayingCard(suit: Suit.hearts, rank: Rank.two);
      const doesNot = PlayingCard(suit: Suit.clubs, rank: Rank.ace);
      expect(follows.beats(doesNot, Suit.hearts, null), isTrue);
    });
  });

  group('Deck', () {
    test('full deck has 52 cards', () {
      expect(Deck.full().length, 52);
    });

    test('shuffled deck has 52 cards', () {
      expect(Deck.shuffled().length, 52);
    });

    test('deal distributes cards correctly for 4 players', () {
      final hands = Deck.deal(4);
      expect(hands.length, 4);
      for (final hand in hands) {
        expect(hand.length, 13);
      }
    });

    test('deal distributes cards correctly for 5 players', () {
      final hands = Deck.deal(5);
      expect(hands.length, 5);
      for (final hand in hands) {
        expect(hand.length, 10);
      }
    });

    test('deal distributes cards correctly for 6 players', () {
      final hands = Deck.deal(6);
      expect(hands.length, 6);
      for (final hand in hands) {
        expect(hand.length, 8);
      }
    });

    group('dealWithMiddle', () {
      test('4 players: 12 cards each + 4 in middle', () {
        final result = Deck.dealWithMiddle(4);
        expect(result.hands.length, 4);
        for (final hand in result.hands) {
          expect(hand.length, 12);
        }
        expect(result.middle.length, 4);
      });

      test('5 players: 10 cards each + 2 in middle', () {
        final result = Deck.dealWithMiddle(5);
        expect(result.hands.length, 5);
        for (final hand in result.hands) {
          expect(hand.length, 10);
        }
        expect(result.middle.length, 2);
      });

      test('6 players: 8 cards each + 4 in middle', () {
        final result = Deck.dealWithMiddle(6);
        expect(result.hands.length, 6);
        for (final hand in result.hands) {
          expect(hand.length, 8);
        }
        expect(result.middle.length, 4);
      });

      test('total cards equals 52', () {
        final result = Deck.dealWithMiddle(4);
        final total = result.hands.fold<int>(
              0, (sum, h) => sum + h.length) +
            result.middle.length;
        expect(total, 52);
      });

      test('no duplicate cards', () {
        final result = Deck.dealWithMiddle(4);
        final all = [
          ...result.hands.expand((h) => h),
          ...result.middle,
        ];
        final unique = all.toSet();
        expect(unique.length, 52);
      });

      test('hands are sorted by suit then rank', () {
        final result = Deck.dealWithMiddle(4);
        for (final hand in result.hands) {
          for (var i = 1; i < hand.length; i++) {
            final prev = hand[i - 1];
            final curr = hand[i];
            final suitCmp =
                prev.suit.index.compareTo(curr.suit.index);
            if (suitCmp == 0) {
              expect(prev.rank.value <= curr.rank.value, isTrue,
                  reason: 'Hand not sorted by rank within suit');
            } else {
              expect(suitCmp <= 0, isTrue,
                  reason: 'Hand not sorted by suit');
            }
          }
        }
      });
    });
  });

  group('Trick', () {
    test('winner is determined correctly with no trump', () {
      const trick = Trick(entries: [
        TrickEntry(
            playerIndex: 0,
            card: PlayingCard(suit: Suit.hearts, rank: Rank.five)),
        TrickEntry(
            playerIndex: 1,
            card: PlayingCard(suit: Suit.hearts, rank: Rank.king)),
        TrickEntry(
            playerIndex: 2,
            card: PlayingCard(suit: Suit.clubs, rank: Rank.ace)),
        TrickEntry(
            playerIndex: 3,
            card: PlayingCard(suit: Suit.hearts, rank: Rank.ten)),
      ]);
      expect(trick.winnerIndex(null), 1); // King of hearts wins
    });

    test('winner with trump', () {
      const trick = Trick(entries: [
        TrickEntry(
            playerIndex: 0,
            card: PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
        TrickEntry(
            playerIndex: 1,
            card: PlayingCard(suit: Suit.spades, rank: Rank.two)),
      ]);
      expect(trick.winnerIndex(Suit.spades), 1); // 2 of spades (trump) wins
    });
  });

  group('PlayState', () {
    test('canPlay returns false for wrong player', () {
      final state = PlayState.start(
        playerNames: ['A', 'B', 'C', 'D'],
        trump: Suit.spades,
        callerIndex: 0,
      );
      // Current player is (callerIndex + 1) % 4 = 1
      final card = state.hands[0].first;
      expect(state.canPlay(0, card), isFalse);
    });

    test('canPlay returns true for current player with valid card', () {
      final state = PlayState.start(
        playerNames: ['A', 'B', 'C', 'D'],
        trump: Suit.spades,
        callerIndex: 0,
      );
      final currentPlayer = state.currentPlayerIndex;
      final card = state.hands[currentPlayer].first;
      expect(state.canPlay(currentPlayer, card), isTrue);
    });

    test('playing a card removes it from hand', () {
      final state = PlayState.start(
        playerNames: ['A', 'B', 'C', 'D'],
        trump: Suit.spades,
        callerIndex: 0,
      );
      final cp = state.currentPlayerIndex;
      final card = state.hands[cp].first;
      final handSize = state.hands[cp].length;
      final next = state.playCard(cp, card);
      expect(next.hands[cp].length, handSize - 1);
      expect(next.hands[cp].contains(card), isFalse);
    });

    test('playing all cards in a trick advances to next trick', () {
      var state = PlayState.start(
        playerNames: ['A', 'B', 'C', 'D'],
        trump: Suit.spades,
        callerIndex: 0,
      );
      // Play one full trick
      for (var i = 0; i < 4; i++) {
        final cp = state.currentPlayerIndex;
        final validCards = state.validCards();
        state = state.playCard(cp, validCards.first);
      }
      expect(state.completedTricks.length, 1);
      expect(state.currentTrick.entries.isEmpty, isTrue);
    });

    test('calculateScores returns scores for all players', () {
      final state = PlayState.start(
        playerNames: ['A', 'B', 'C', 'D'],
        trump: Suit.spades,
        callerIndex: 0,
      );
      // Just test that it returns scores (even if no tricks played)
      final scores = state.calculateScores();
      expect(scores.length, 4);
      expect(scores.containsKey('A'), isTrue);
      expect(scores.containsKey('B'), isTrue);
    });

    test('partner is revealed when called card is played', () {
      // Create a state with a specific called card
      final hands = Deck.deal(4);
      // Pick a card from player 2's hand as the called card
      final calledCard = hands[2].first;

      var state = PlayState(
        playerNames: ['A', 'B', 'C', 'D'],
        hands: hands,
        trump: Suit.spades,
        callerIndex: 0,
        calledCard: calledCard,
        currentPlayerIndex: 2, // Let player 2 go first for this test
      );

      expect(state.partnerRevealed, isFalse);
      expect(state.partnerIndex, isNull);

      state = state.playCard(2, calledCard);

      expect(state.partnerRevealed, isTrue);
      expect(state.partnerIndex, 2);
    });

    group('tricksPerRound with dealWithMiddle hands', () {
      test('is 12 for 4 players dealt via dealWithMiddle', () {
        final deal = Deck.dealWithMiddle(4);
        final state = PlayState.start(
          playerNames: ['A', 'B', 'C', 'D'],
          trump: Suit.spades,
          callerIndex: 0,
          hands: deal.hands,
        );
        expect(state.tricksPerRound, 12);
      });

      test('remains 12 after playing one full trick', () {
        final deal = Deck.dealWithMiddle(4);
        var state = PlayState.start(
          playerNames: ['A', 'B', 'C', 'D'],
          trump: Suit.spades,
          callerIndex: 0,
          hands: deal.hands,
        );
        for (var i = 0; i < 4; i++) {
          final cp = state.currentPlayerIndex;
          state = state.playCard(cp, state.validCards().first);
        }
        expect(state.tricksPerRound, 12);
        expect(state.completedTricks.length, 1);
      });

      test('roundOver is true after 12 tricks', () {
        final deal = Deck.dealWithMiddle(4);
        var state = PlayState.start(
          playerNames: ['A', 'B', 'C', 'D'],
          trump: Suit.spades,
          callerIndex: 0,
          hands: deal.hands,
        );
        // Play all 12 tricks
        for (var trick = 0; trick < 12; trick++) {
          for (var i = 0; i < 4; i++) {
            final cp = state.currentPlayerIndex;
            state = state.playCard(cp, state.validCards().first);
          }
        }
        expect(state.roundOver, isTrue);
        expect(state.completedTricks.length, 12);
      });
    });

    group('bid-based scoring', () {
      test('bid made: caller team scores ± contract value', () {
        // Explicitly set caller=0, partner=2 so teams are balanced (2v2)
        final deal = Deck.dealWithMiddle(4);
        var state = PlayState(
          playerNames: ['A', 'B', 'C', 'D'],
          hands: deal.hands,
          trump: Suit.spades,
          callerIndex: 0,
          partnerIndex: 2,
          currentPlayerIndex: 1,
          bid: const Bid(pointsPerTrick: 2, tricksNeeded: 9),
        );
        // play all tricks
        while (!state.roundOver) {
          final cp = state.currentPlayerIndex;
          state = state.playCard(cp, state.validCards().first);
        }
        final scores = state.calculateScores();
        // Contract value = 9 × 2 = 18; all scores are ±18
        for (final s in scores.values) {
          expect(s == 18 || s == -18, isTrue);
        }
        // A and C (caller+partner) share the same score
        expect(scores['A'], scores['C']);
        // B and D (opponents) share the same score
        expect(scores['B'], scores['D']);
        // The two teams have opposite scores
        expect(scores['A'], isNot(scores['B']));
        // Totals cancel out (2 × 18 + 2 × −18 = 0)
        final total = scores.values.fold<int>(0, (a, b) => a + b);
        expect(total, 0);
      });

      test('bid serialises and deserialises with PlayState', () {
        final deal = Deck.dealWithMiddle(4);
        final state = PlayState.start(
          playerNames: ['A', 'B', 'C', 'D'],
          trump: Suit.spades,
          callerIndex: 0,
          hands: deal.hands,
          bid: const Bid(pointsPerTrick: 3, tricksNeeded: 10),
        );
        final json = state.toJson();
        final restored = PlayState.fromJson(json);
        expect(restored.bid, const Bid(pointsPerTrick: 3, tricksNeeded: 10));
      });

      test('state without bid serialises and deserialises correctly', () {
        final state = PlayState.start(
          playerNames: ['A', 'B', 'C', 'D'],
          trump: Suit.spades,
          callerIndex: 0,
        );
        final json = state.toJson();
        final restored = PlayState.fromJson(json);
        expect(restored.bid, isNull);
      });
    });
  });
}

