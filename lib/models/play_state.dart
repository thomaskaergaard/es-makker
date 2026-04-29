import 'playing_card.dart';
import 'bid.dart';

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

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory Trick.fromJson(Map<String, dynamic> json) => Trick(
        entries: ((json['entries'] as List?) ?? const [])
            .map((e) => TrickEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class TrickEntry {
  final int playerIndex;
  final PlayingCard card;

  const TrickEntry({required this.playerIndex, required this.card});

  Map<String, dynamic> toJson() => {
        'playerIndex': playerIndex,
        'card': card.toJson(),
      };

  factory TrickEntry.fromJson(Map<String, dynamic> json) => TrickEntry(
        playerIndex: json['playerIndex'] as int,
        card: PlayingCard.fromJson(
            Map<String, dynamic>.from(json['card'] as Map)),
      );
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
  final Bid? bid;

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
    this.bid,
  });

  int get playerCount => playerNames.length;
  int get totalTricks => hands.isEmpty ? 0 : completedTricks.length + (currentTrick.entries.isEmpty ? 0 : 1);

  /// Number of tricks in this round, derived from the initial hand size.
  ///
  /// Accounts for cards already played (removed from hands) during both
  /// completed tricks and the current in-progress trick.
  int get tricksPerRound {
    if (hands.isEmpty) return 52 ~/ playerCount;
    // For player 0: initial hand size = remaining cards + completed tricks
    // + any card already played in the current incomplete trick.
    final inCurrentTrick = currentTrick.entries
        .where((e) => e.playerIndex == 0)
        .length;
    return hands[0].length + completedTricks.length + inCurrentTrick;
  }

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
        bid: bid,
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
      bid: bid,
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

  /// Calculate scores based on the bid (if set) or a simple trick-count fallback.
  ///
  /// With a bid:
  /// - Caller's team wins [bid.tricksNeeded] or more tricks → each team member
  ///   scores `bid.tricksNeeded × bid.pointsPerTrick` (positive).
  /// - Caller's team wins fewer tricks → each team member scores
  ///   `-(bid.tricksNeeded × bid.pointsPerTrick)` (negative).
  /// - Opponents always score the opposite of the caller's team.
  ///
  /// Without a bid (legacy / manual-entry mode): caller team wins if they hold
  /// a majority of tricks; each trick is worth 1 point.
  Map<String, int> calculateScores() {
    final won = tricksWon;
    final callerTeamTricks = (won[callerIndex] ?? 0) +
        (partnerIndex != null ? (won[partnerIndex!] ?? 0) : 0);
    final totalTricksCount = tricksPerRound;

    final int teamPoints;
    if (bid != null) {
      // Bid-based scoring
      final contractValue = bid!.tricksNeeded * bid!.pointsPerTrick;
      teamPoints = callerTeamTricks >= bid!.tricksNeeded
          ? contractValue
          : -contractValue;
    } else {
      // Legacy fallback: majority wins, 1 point per trick
      final opponentTricks = totalTricksCount - callerTeamTricks;
      final callerTeamWon = callerTeamTricks > opponentTricks;
      teamPoints = callerTeamWon ? callerTeamTricks : -callerTeamTricks;
    }

    final scores = <String, int>{};
    for (var i = 0; i < playerCount; i++) {
      final isCallerTeam = i == callerIndex || i == partnerIndex;
      scores[playerNames[i]] = isCallerTeam ? teamPoints : -teamPoints;
    }
    return scores;
  }

  /// Create initial play state from setup.
  ///
  /// Optionally accepts [hands] that have been pre-dealt (e.g. after the
  /// bidding phase). If [hands] is omitted the cards are dealt from a freshly
  /// shuffled deck via [Deck.deal].
  factory PlayState.start({
    required List<String> playerNames,
    required Suit trump,
    required int callerIndex,
    PlayingCard? calledCard,
    List<List<PlayingCard>>? hands,
    Bid? bid,
  }) {
    final dealtHands = hands ?? Deck.deal(playerNames.length);
    return PlayState(
      playerNames: playerNames,
      hands: dealtHands,
      trump: trump,
      callerIndex: callerIndex,
      calledCard: calledCard,
      currentPlayerIndex: (callerIndex + 1) % playerNames.length,
      bid: bid,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerNames': playerNames,
        'hands': hands
            .map((h) => h.map((c) => c.toJson()).toList())
            .toList(),
        'trump': trump?.name,
        'callerIndex': callerIndex,
        'partnerIndex': partnerIndex,
        'calledCard': calledCard?.toJson(),
        'completedTricks':
            completedTricks.map((t) => t.toJson()).toList(),
        'currentTrick': currentTrick.toJson(),
        'currentPlayerIndex': currentPlayerIndex,
        'partnerRevealed': partnerRevealed,
        if (bid != null) 'bid': bid!.toJson(),
      };

  factory PlayState.fromJson(Map<String, dynamic> json) => PlayState(
        playerNames: List<String>.from(json['playerNames'] as List),
        hands: (json['hands'] as List)
            .map((h) => (h as List)
                .map((c) => PlayingCard.fromJson(
                    Map<String, dynamic>.from(c as Map)))
                .toList())
            .toList(),
        trump: json['trump'] != null
            ? Suit.values.byName(json['trump'] as String)
            : null,
        callerIndex: json['callerIndex'] as int,
        partnerIndex: json['partnerIndex'] as int?,
        calledCard: json['calledCard'] != null
            ? PlayingCard.fromJson(
                Map<String, dynamic>.from(json['calledCard'] as Map))
            : null,
        completedTricks: ((json['completedTricks'] as List?) ?? const [])
            .map((t) =>
                Trick.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
        currentTrick: Trick.fromJson(
            Map<String, dynamic>.from(json['currentTrick'] as Map)),
        currentPlayerIndex: json['currentPlayerIndex'] as int,
        partnerRevealed: json['partnerRevealed'] as bool? ?? false,
        bid: json['bid'] != null
            ? Bid.fromJson(Map<String, dynamic>.from(json['bid'] as Map))
            : null,
      );
}
