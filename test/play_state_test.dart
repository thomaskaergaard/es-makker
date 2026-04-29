import 'package:test/test.dart';
import 'package:es_makker/models/playing_card.dart';
import 'package:es_makker/models/play_state.dart';

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
  });
}
