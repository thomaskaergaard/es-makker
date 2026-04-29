/// Represents the four card suits.
enum Suit {
  spades('♠', 'Spar'),
  hearts('♥', 'Hjerter'),
  diamonds('♦', 'Ruder'),
  clubs('♣', 'Klør');

  const Suit(this.symbol, this.danishName);
  final String symbol;
  final String danishName;
}

/// Represents card ranks from 2 to Ace.
enum Rank {
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, '10'),
  jack(11, 'Kn'),
  queen(12, 'D'),
  king(13, 'K'),
  ace(14, 'Es');

  const Rank(this.value, this.label);
  final int value;
  final String label;
}

/// A single playing card.
class PlayingCard {
  final Suit suit;
  final Rank rank;

  const PlayingCard({required this.suit, required this.rank});

  String get shortName => '${rank.label}${suit.symbol}';
  String get danishName => '${suit.danishName} ${rank.label}';

  /// Whether this card beats [other] given the [leadSuit] and optional [trump].
  /// A card beats another if:
  /// 1. It is trump and the other is not.
  /// 2. Both are trump (or both follow lead), and this has higher rank.
  bool beats(PlayingCard other, Suit leadSuit, Suit? trump) {
    final thisIsTrump = trump != null && suit == trump;
    final otherIsTrump = trump != null && other.suit == trump;

    if (thisIsTrump && !otherIsTrump) return true;
    if (!thisIsTrump && otherIsTrump) return false;

    // Both trump or neither trump – compare within suit
    if (thisIsTrump && otherIsTrump) {
      return rank.value > other.rank.value;
    }

    // Neither is trump: only the lead suit matters
    final thisFollows = suit == leadSuit;
    final otherFollows = other.suit == leadSuit;
    if (thisFollows && !otherFollows) return true;
    if (!thisFollows && otherFollows) return false;
    if (thisFollows && otherFollows) {
      return rank.value > other.rank.value;
    }

    // Neither follows lead – first played wins (other keeps winning)
    return false;
  }

  Map<String, dynamic> toJson() => {
        'suit': suit.name,
        'rank': rank.name,
      };

  factory PlayingCard.fromJson(Map<String, dynamic> json) => PlayingCard(
        suit: Suit.values.byName(json['suit'] as String),
        rank: Rank.values.byName(json['rank'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard && suit == other.suit && rank == other.rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => shortName;
}

/// Result of dealing cards with a middle pile (talon/kitty).
class DealResult {
  final List<List<PlayingCard>> hands;
  final List<PlayingCard> middle;

  const DealResult({required this.hands, required this.middle});
}

/// A standard 52-card deck.
class Deck {
  Deck._();

  static List<PlayingCard> full() {
    return [
      for (final suit in Suit.values)
        for (final rank in Rank.values) PlayingCard(suit: suit, rank: rank),
    ];
  }

  /// Returns a shuffled deck.
  static List<PlayingCard> shuffled() {
    final cards = full();
    cards.shuffle();
    return cards;
  }

  /// Deal cards to [playerCount] players. Returns a list of hands.
  /// Removes leftover cards (for 5/6 players).
  static List<List<PlayingCard>> deal(int playerCount) {
    final cards = shuffled();
    final cardsPerPlayer = cards.length ~/ playerCount;
    final hands = <List<PlayingCard>>[];
    for (var i = 0; i < playerCount; i++) {
      hands.add(
        cards.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer),
      );
    }
    // Sort each hand by suit then rank
    for (final hand in hands) {
      hand.sort((a, b) {
        final suitCmp = a.suit.index.compareTo(b.suit.index);
        if (suitCmp != 0) return suitCmp;
        return a.rank.value.compareTo(b.rank.value);
      });
    }
    return hands;
  }

  /// Number of cards placed in the middle pile (talon) for each player count.
  static int middleCount(int playerCount) => playerCount == 5 ? 2 : 4;

  /// Deal cards to [playerCount] players with a middle pile (talon/kitty).
  ///
  /// Card distribution:
  /// - 4 players: 12 cards each + 4 middle
  /// - 5 players: 10 cards each + 2 middle
  /// - 6 players: 8 cards each + 4 middle
  ///
  /// Returns a [DealResult] with the player hands sorted by suit/rank and the
  /// face-down middle pile.
  static DealResult dealWithMiddle(int playerCount) {
    final mc = middleCount(playerCount);
    final cards = shuffled();
    final middle = cards.sublist(0, mc);
    final rest = cards.sublist(mc);
    final cardsPerPlayer = rest.length ~/ playerCount;
    final hands = <List<PlayingCard>>[];
    for (var i = 0; i < playerCount; i++) {
      final hand = List<PlayingCard>.from(
        rest.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer),
      );
      hand.sort((a, b) {
        final suitCmp = a.suit.index.compareTo(b.suit.index);
        if (suitCmp != 0) return suitCmp;
        return a.rank.value.compareTo(b.rank.value);
      });
      hands.add(hand);
    }
    return DealResult(hands: hands, middle: middle);
  }
}
