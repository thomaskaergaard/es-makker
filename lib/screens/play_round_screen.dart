import 'dart:async';

import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import '../models/play_state.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

/// The main card-playing screen. Displays the current trick, player's hand,
/// and allows playing cards.
///
/// In **online mode** ([sessionService] and [roomCode] are non-null):
/// - [myPlayerIndex] restricts the view to a single player's hand.
/// - The [PlayState] is synced via Firebase; any card played by this device
///   is written to Firebase and all devices receive the update.
class PlayRoundScreen extends StatefulWidget {
  const PlayRoundScreen({
    super.key,
    required this.initialState,
    required this.onRoundComplete,
    this.sessionService,
    this.roomCode,
    this.myPlayerIndex,
  });

  final PlayState initialState;
  final void Function(Map<String, int> scores,
      {String? caller, String? partner}) onRoundComplete;

  /// Non-null when in online mode.
  final SessionService? sessionService;
  final String? roomCode;

  /// The index of the player controlling this device. Null = local (all players).
  final int? myPlayerIndex;

  bool get isOnline => sessionService != null && roomCode != null;

  @override
  State<PlayRoundScreen> createState() => _PlayRoundScreenState();
}

class _PlayRoundScreenState extends State<PlayRoundScreen> {
  late PlayState _state;
  int _viewingPlayer = 0; // which player's hand is shown (local mode only)
  StreamSubscription<SessionSnapshot>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    if (widget.isOnline) {
      // In online mode, each player only sees their own hand.
      _viewingPlayer = widget.myPlayerIndex ?? 0;
      _sessionSub = widget.sessionService!
          .watchSession(widget.roomCode!)
          .listen(_onSessionUpdate);
    } else {
      _viewingPlayer = _state.currentPlayerIndex;
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  void _onSessionUpdate(SessionSnapshot snapshot) {
    if (!mounted) return;
    if (snapshot.playState != null) {
      setState(() => _state = snapshot.playState!);
      if (_state.roundOver) _showRoundResults();
    }
  }

  void _playCard(PlayingCard card) {
    if (!_state.canPlay(_viewingPlayer, card)) return;

    final newState = _state.playCard(_viewingPlayer, card);

    if (widget.isOnline) {
      // Optimistic local update, then sync to Firebase.
      setState(() => _state = newState);
      widget.sessionService!
          .updatePlayState(widget.roomCode!, newState);
    } else {
      setState(() {
        _state = newState;
        _viewingPlayer = _state.currentPlayerIndex;
      });
    }

    if (newState.roundOver) {
      _showRoundResults();
    }
  }

  void _showRoundResults() {
    final scores = _state.calculateScores();
    final callerName = _state.playerNames[_state.callerIndex];
    final partnerName = _state.partnerIndex != null
        ? _state.playerNames[_state.partnerIndex!]
        : null;
    final won = _state.tricksWon;

    // Pre-compute the combined trick total for the caller's team.
    final callerTeamTricks = (won[_state.callerIndex] ?? 0) +
        (_state.partnerIndex != null
            ? (won[_state.partnerIndex!] ?? 0)
            : 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Runde færdig!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (partnerName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Makker-par: $callerName & $partnerName',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              const Divider(),
              ...scores.entries.map((e) {
                final playerIndex = _state.playerNames.indexOf(e.key);
                final isCallerTeam = playerIndex == _state.callerIndex ||
                    playerIndex == _state.partnerIndex;
                // Caller-team members share the combined trick count so both
                // partners see the same total (which determines the bid result).
                final tricks =
                    isCallerTeam ? callerTeamTricks : (won[playerIndex] ?? 0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$tricks stik',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            e.value >= 0 ? '+${e.value}' : '${e.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: e.value >= 0
                                  ? AppColors.positive
                                  : AppColors.negative,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onRoundComplete(
                  scores,
                  caller: callerName,
                  partner: partnerName,
                );
              },
              child: const Text('Gem og fortsæt'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPlayerName = _state.playerNames[_state.currentPlayerIndex];
    final isMyTurn = _viewingPlayer == _state.currentPlayerIndex;

    // In online mode: only show the current player's own hand.
    // In local mode: allow switching between all players via tabs.
    final canSwitchPlayers = !widget.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Runde – ${_state.playerNames[_state.callerIndex]} melder',
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                'Trumf: ${_state.trump?.symbol ?? "Ingen"} ${_state.trump?.danishName ?? ""}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Player tabs (online: read-only indicator; local: interactive)
          _PlayerTabs(
            playerNames: _state.playerNames,
            currentPlayerIndex: _state.currentPlayerIndex,
            viewingPlayer: _viewingPlayer,
            tricksWon: _state.tricksWon,
            callerIndex: _state.callerIndex,
            partnerIndex: _state.partnerRevealed ? _state.partnerIndex : null,
            onPlayerSelected:
                canSwitchPlayers ? (i) => setState(() => _viewingPlayer = i) : null,
          ),
          // Current trick
          _CurrentTrickDisplay(
            trick: _state.currentTrick,
            playerNames: _state.playerNames,
            trump: _state.trump,
            completedTricks: _state.completedTricks.length,
            totalTricks: _state.tricksPerRound,
          ),
          const Divider(height: 1),
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isMyTurn
                ? theme.colorScheme.primaryContainer
                : Colors.grey.shade200,
            child: Text(
              widget.isOnline
                  ? (isMyTurn
                      ? 'Din tur! Vælg et kort.'
                      : 'Venter på $currentPlayerName…')
                  : (isMyTurn
                      ? '${_state.playerNames[_viewingPlayer]} – din tur! Vælg et kort.'
                      : 'Venter på $currentPlayerName... (du ser ${_state.playerNames[_viewingPlayer]}s kort)'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Player's hand
          Expanded(
            child: _HandDisplay(
              hand: _state.hands[_viewingPlayer],
              validCards: isMyTurn ? _state.validCards() : [],
              onCardPlayed: isMyTurn ? _playCard : null,
              trump: _state.trump,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tabs showing each player; highlights whose turn it is.
class _PlayerTabs extends StatelessWidget {
  const _PlayerTabs({
    required this.playerNames,
    required this.currentPlayerIndex,
    required this.viewingPlayer,
    required this.tricksWon,
    required this.callerIndex,
    required this.partnerIndex,
    required this.onPlayerSelected,
  });

  final List<String> playerNames;
  final int currentPlayerIndex;
  final int viewingPlayer;
  final Map<int, int> tricksWon;
  final int callerIndex;
  final int? partnerIndex;
  final ValueChanged<int>? onPlayerSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Combine caller+partner tricks so both teammates see the shared team total.
    final callerTeamTricks = (tricksWon[callerIndex] ?? 0) +
        (partnerIndex != null ? (tricksWon[partnerIndex!] ?? 0) : 0);

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: List.generate(playerNames.length, (i) {
            final isCurrent = i == currentPlayerIndex;
            final isViewing = i == viewingPlayer;
            final isCaller = i == callerIndex;
            final isPartner = i == partnerIndex;
            final isCallerTeam = isCaller || isPartner;

            String label = playerNames[i];
            if (isCaller) label += ' ⭐';
            if (isPartner) label += ' 🤝';

            // Caller-team members share the combined trick count;
            // opponents show their own individual count.
            final displayTricks =
                isCallerTeam ? callerTeamTricks : (tricksWon[i] ?? 0);

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: onPlayerSelected != null ? () => onPlayerSelected!(i) : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isViewing
                        ? theme.colorScheme.primary
                        : isCurrent
                            ? theme.colorScheme.primaryContainer
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: isCurrent && !isViewing
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isViewing ? Colors.white : Colors.black87,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$displayTricks stik',
                        style: TextStyle(
                          color: isViewing
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Displays the cards played in the current trick.
class _CurrentTrickDisplay extends StatelessWidget {
  const _CurrentTrickDisplay({
    required this.trick,
    required this.playerNames,
    required this.trump,
    required this.completedTricks,
    required this.totalTricks,
  });

  final Trick trick;
  final List<String> playerNames;
  final Suit? trump;
  final int completedTricks;
  final int totalTricks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: Column(
        children: [
          Text(
            'Stik ${completedTricks + 1} af $totalTricks',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (trick.entries.isEmpty)
            Text(
              'Venter på udspil...',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: trick.entries.map((entry) {
                return _MiniCard(
                  card: entry.card,
                  label: playerNames[entry.playerIndex],
                  trump: trump,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// A small card representation showing suit symbol and rank.
class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.card,
    required this.label,
    this.trump,
  });

  final PlayingCard card;
  final String label;
  final Suit? trump;

  Color _suitColor(Suit suit) {
    return (suit == Suit.hearts || suit == Suit.diamonds)
        ? Colors.red.shade700
        : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final isTrump = trump != null && card.suit == trump;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isTrump ? Colors.amber.shade700 : Colors.grey.shade400,
              width: isTrump ? 2.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1)),
            ],

          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.rank.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _suitColor(card.suit),
                ),
              ),
              Text(
                card.suit.symbol,
                style: TextStyle(
                  fontSize: 20,
                  color: _suitColor(card.suit),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }
}

/// Displays a player's hand and allows them to play cards.
class _HandDisplay extends StatelessWidget {
  const _HandDisplay({
    required this.hand,
    required this.validCards,
    required this.onCardPlayed,
    this.trump,
  });

  final List<PlayingCard> hand;
  final List<PlayingCard> validCards;
  final ValueChanged<PlayingCard>? onCardPlayed;
  final Suit? trump;

  Color _suitColor(Suit suit) {
    return (suit == Suit.hearts || suit == Suit.diamonds)
        ? Colors.red.shade700
        : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) {
      return const Center(
        child: Text('Ingen kort tilbage', style: TextStyle(color: Colors.black54)),
      );
    }

    // Group cards by suit
    final bySuit = <Suit, List<PlayingCard>>{};
    for (final card in hand) {
      bySuit.putIfAbsent(card.suit, () => []).add(card);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bySuit.entries.map((entry) {
          final suit = entry.key;
          final cards = entry.value;
          final isTrumpSuit = trump != null && suit == trump;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${suit.symbol} ${suit.danishName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _suitColor(suit),
                      ),
                    ),
                    if (isTrumpSuit)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: Text(
                            'TRUMF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: cards.map((card) {
                    final isValid = validCards.contains(card);
                    final canTap = onCardPlayed != null && isValid;
                    return GestureDetector(
                      onTap: canTap ? () => onCardPlayed!(card) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 52,
                        height: 72,
                        decoration: BoxDecoration(
                          color: canTap ? Colors.white : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canTap
                                ? _suitColor(card.suit)
                                : Colors.grey.shade400,
                            width: canTap ? 2 : 1,
                          ),
                          boxShadow: canTap
                              ? [
                                  BoxShadow(
                                    color: _suitColor(card.suit)
                                        .withAlpha(64),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.rank.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: canTap
                                    ? _suitColor(card.suit)
                                    : Colors.grey,
                              ),
                            ),
                            Text(
                              card.suit.symbol,
                              style: TextStyle(
                                fontSize: 18,
                                color: canTap
                                    ? _suitColor(card.suit)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
