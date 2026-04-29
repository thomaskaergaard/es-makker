import 'playing_card.dart';

/// A single trick: each entry maps a player index to the card they played.
class Trick {
  final List<TrickEntry> entries;

  const Trick({this.entries = const []});

  bool get hasEntries => entries.isNotEmpty;
  Suit? get leadSuit => entries.isNotEmpty ? entries.first.card.suit : null;

  Trick addEntry(TrickEntry entry) =>
      Trick(entries: [...entries, entry]);

  /// Returns the index of the player who won this trick.
  int winnerIndex(Suit? trump) {
    var best = entries.first;
    for (var i = 1; i < entries.length; i++) {
      if (entries[i].card.beats(best.card, leadSuit!, trump)) {
        best = entries[i];
      }
    }
    return best.playerIndex;
  }
}

class TrickEntry {
  final int playerIndex;
  final PlayingCard card;

  const TrickEntry({required this.playerIndex, required this.card});
}

/// The state of an active card game round.
class PlayState {
  final List<String> playerNames;
  final List<List<PlayingCard>> hands;
  final Suit? trump;
  final int callerIndex;
  final int? partnerIndex;
  final PlayingCard? calledCard; // the card that identifies the partner
  final List<Trick> completedTricks;
  final Trick currentTrick;
  final int currentPlayerIndex;
  final bool partnerRevealed;

  const PlayState({
    required this.playerNames,
    required this.hands,
    required this.trump,
    required this.callerIndex,
    this.partnerIndex,
    this.calledCard,
    this.completedTricks = const [],
    this.currentTrick = const Trick(),
    required this.currentPlayerIndex,
    this.partnerRevealed = false,
  });

  int get playerCount => playerNames.length;
  int get totalTricks => hands.isEmpty ? 0 : completedTricks.length + (currentTrick.entries.isEmpty ? 0 : 1);
  int get tricksPerRound => 52 ~/ playerCount;
  bool get roundOver => completedTricks.length == tricksPerRound;

  /// Whether a player can play a given card.
  bool canPlay(int playerIndex, PlayingCard card) {
    if (playerIndex != currentPlayerIndex) return false;
    if (!hands[playerIndex].contains(card)) return false;

    // If leading, anything goes
    if (currentTrick.entries.isEmpty) return true;

    // Must follow suit if possible
    final leadSuit = currentTrick.leadSuit!;
    final hand = hands[playerIndex];
    final hasLeadSuit = hand.any((c) => c.suit == leadSuit);
    if (hasLeadSuit) return card.suit == leadSuit;

    // Can't follow suit – anything goes
    return true;
  }

  /// Returns valid cards the current player can play.
  List<PlayingCard> validCards() {
    return hands[currentPlayerIndex]
        .where((c) => canPlay(currentPlayerIndex, c))
        .toList();
  }

  /// Play a card and return the new state.
  PlayState playCard(int playerIndex, PlayingCard card) {
    assert(canPlay(playerIndex, card));

    // Remove card from hand
    final newHands = [
      for (var i = 0; i < hands.length; i++)
        if (i == playerIndex)
          hands[i].where((c) => c != card).toList()
        else
          List<PlayingCard>.from(hands[i]),
    ];

    final newTrick = currentTrick.addEntry(
      TrickEntry(playerIndex: playerIndex, card: card),
    );

    // Check if partner is revealed
    var revealed = partnerRevealed;
    int? newPartnerIndex = partnerIndex;
    if (calledCard != null && card == calledCard && !partnerRevealed) {
      revealed = true;
      newPartnerIndex = playerIndex;
    }

    // Check if trick is complete
    if (newTrick.entries.length == playerCount) {
      final winnerIdx = newTrick.winnerIndex(trump);
      return PlayState(
        playerNames: playerNames,
        hands: newHands,
        trump: trump,
        callerIndex: callerIndex,
        partnerIndex: newPartnerIndex,
        calledCard: calledCard,
        completedTricks: [...completedTricks, newTrick],
        currentTrick: const Trick(),
        currentPlayerIndex: winnerIdx,
        partnerRevealed: revealed,
      );
    }

    // Move to next player
    final nextPlayer = (playerIndex + 1) % playerCount;
    return PlayState(
      playerNames: playerNames,
      hands: newHands,
      trump: trump,
      callerIndex: callerIndex,
      partnerIndex: newPartnerIndex,
      calledCard: calledCard,
      completedTricks: completedTricks,
      currentTrick: newTrick,
      currentPlayerIndex: nextPlayer,
      partnerRevealed: revealed,
    );
  }

  /// Count tricks won by each player.
  Map<int, int> get tricksWon {
    final counts = <int, int>{};
    for (var i = 0; i < playerCount; i++) {
      counts[i] = 0;
    }
    for (final trick in completedTricks) {
      final winner = trick.winnerIndex(trump);
      counts[winner] = (counts[winner] ?? 0) + 1;
    }
    return counts;
  }

  /// Calculate scores: caller+partner get +tricks, opponents get -tricks
  /// (simplified scoring: each trick = 1 point for the winning side,
  /// -1 for the losing side).
  Map<String, int> calculateScores() {
    final won = tricksWon;
    final callerTeamTricks = (won[callerIndex] ?? 0) +
        (partnerIndex != null ? (won[partnerIndex!] ?? 0) : 0);
    final totalTricksCount = tricksPerRound;
    final opponentTricks = totalTricksCount - callerTeamTricks;

    // Caller team wins if they got more tricks
    final callerTeamWon = callerTeamTricks > opponentTricks;
    final points = callerTeamWon ? callerTeamTricks : -callerTeamTricks;
    final opponentPoints = -points;

    final scores = <String, int>{};
    for (var i = 0; i < playerCount; i++) {
      final isCallerTeam = i == callerIndex || i == partnerIndex;
      scores[playerNames[i]] = isCallerTeam ? points : opponentPoints;
    }
    return scores;
  }

  /// Create initial play state from setup.
  factory PlayState.start({
    required List<String> playerNames,
    required Suit trump,
    required int callerIndex,
    PlayingCard? calledCard,
  }) {
    final hands = Deck.deal(playerNames.length);
    return PlayState(
      playerNames: playerNames,
      hands: hands,
      trump: trump,
      callerIndex: callerIndex,
      calledCard: calledCard,
      currentPlayerIndex: (callerIndex + 1) % playerNames.length,
    );
  }
}
