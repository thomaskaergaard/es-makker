import 'package:flutter/material.dart';
import '../models/bid.dart';
import '../models/playing_card.dart';
import '../models/play_state.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'play_round_screen.dart';

enum _DealPhase { bidding, callerSetup }

/// Screen that handles dealing cards, the bidding phase, and caller setup
/// before a round begins.
///
/// Flow:
/// 1. Cards are dealt automatically (12 per player + 4 talon for 4 players).
/// 2. Players bid in turn (2i9 → 3i9 → … → 4i10) or pass.
/// 3. The bid winner (caller) sees the talon, selects trump and a partner card.
/// 4. The round starts ([PlayRoundScreen] is pushed).
class DealScreen extends StatefulWidget {
  const DealScreen({
    super.key,
    required this.playerNames,
    required this.onRoundComplete,
    this.sessionService,
    this.roomCode,
    this.myPlayerIndex,
  });

  final List<String> playerNames;
  final void Function(Map<String, int> scores, {String? caller, String? partner})
      onRoundComplete;

  /// Non-null when in online mode.
  final SessionService? sessionService;
  final String? roomCode;
  final int? myPlayerIndex;

  bool get isOnline => sessionService != null && roomCode != null;

  @override
  State<DealScreen> createState() => _DealScreenState();
}

class _DealScreenState extends State<DealScreen> {
  // ── Dealt cards ────────────────────────────────────────────────────────────
  late DealResult _deal;

  // ── Phase ──────────────────────────────────────────────────────────────────
  _DealPhase _phase = _DealPhase.bidding;

  // ── Bidding state ──────────────────────────────────────────────────────────
  int _currentBidderIndex = 0;
  Bid? _highestBid;
  int? _highestBidderIndex;
  late List<bool> _passed; // _passed[i] == true if player i has passed

  // ── Caller setup state ─────────────────────────────────────────────────────
  int _callerIndex = 0;
  Suit _trump = Suit.spades;
  PlayingCard? _calledCard;

  @override
  void initState() {
    super.initState();
    _initDeal();
  }

  // ── Dealing ────────────────────────────────────────────────────────────────

  void _initDeal() {
    _deal = Deck.dealWithMiddle(widget.playerNames.length);
    _passed = List.filled(widget.playerNames.length, false);
    _currentBidderIndex = 0;
    _highestBid = null;
    _highestBidderIndex = null;
    _phase = _DealPhase.bidding;
  }

  // ── Bidding ────────────────────────────────────────────────────────────────

  void _onBid(Bid bid) {
    setState(() {
      _highestBid = bid;
      _highestBidderIndex = _currentBidderIndex;
      _advanceBidder();
    });
  }

  void _onPass() {
    setState(() {
      _passed[_currentBidderIndex] = true;
      _advanceBidder();
    });
  }

  void _advanceBidder() {
    final active = List.generate(widget.playerNames.length, (i) => i)
        .where((i) => !_passed[i])
        .toList();

    // All players passed → re-deal
    if (active.isEmpty) {
      _showReDealSnackBar();
      _initDeal();
      return;
    }

    // One player left AND there is a bid → they win
    if (active.length == 1 && _highestBid != null) {
      _finishBidding(active.first);
      return;
    }

    // Advance to the next non-passed player
    var next = (_currentBidderIndex + 1) % widget.playerNames.length;
    while (_passed[next]) {
      next = (next + 1) % widget.playerNames.length;
    }
    _currentBidderIndex = next;

    // If we've returned to the highest bidder and all others have passed, done
    if (_highestBid != null &&
        _currentBidderIndex == _highestBidderIndex &&
        active.length == 1) {
      _finishBidding(_highestBidderIndex!);
    }
  }

  void _finishBidding(int winnerIndex) {
    _callerIndex = winnerIndex;
    _trump = Suit.spades;
    _calledCard = null;
    _phase = _DealPhase.callerSetup;
  }

  void _showReDealSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alle passede – der deles om.')),
      );
    });
  }

  // ── Start round ────────────────────────────────────────────────────────────

  void _startRound() {
    final playState = PlayState.start(
      playerNames: widget.playerNames,
      trump: _trump,
      callerIndex: _callerIndex,
      calledCard: _calledCard,
      hands: _deal.hands,
      bid: _highestBid,
    );

    if (widget.isOnline) {
      widget.sessionService!.startPlayRound(widget.roomCode!, playState);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayRoundScreen(
          initialState: playState,
          onRoundComplete: (scores, {String? caller, String? partner}) {
            Navigator.of(context).pop();
            widget.onRoundComplete(scores, caller: caller, partner: partner);
            if (widget.isOnline) {
              widget.sessionService!.endPlayRound(widget.roomCode!);
            }
          },
          sessionService: widget.sessionService,
          roomCode: widget.roomCode,
          myPlayerIndex: widget.myPlayerIndex,
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase == _DealPhase.bidding
            ? 'Opbud – ${widget.playerNames[_currentBidderIndex]}s tur'
            : 'Opbud afsluttet'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _phase == _DealPhase.bidding
              ? _BiddingPhase(
                  playerNames: widget.playerNames,
                  hands: _deal.hands,
                  currentBidderIndex: _currentBidderIndex,
                  highestBid: _highestBid,
                  highestBidderIndex: _highestBidderIndex,
                  passed: _passed,
                  onBid: _onBid,
                  onPass: _onPass,
                )
              : _CallerSetupPhase(
                  playerNames: widget.playerNames,
                  callerIndex: _callerIndex,
                  bid: _highestBid!,
                  callerHand: _deal.hands[_callerIndex],
                  talon: _deal.middle,
                  trump: _trump,
                  calledCard: _calledCard,
                  onTrumpChanged: (suit) => setState(() => _trump = suit),
                  onCalledCardChanged: (card) =>
                      setState(() => _calledCard = card),
                  onStart: _startRound,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bidding phase widget
// ─────────────────────────────────────────────────────────────────────────────

class _BiddingPhase extends StatelessWidget {
  const _BiddingPhase({
    required this.playerNames,
    required this.hands,
    required this.currentBidderIndex,
    required this.highestBid,
    required this.highestBidderIndex,
    required this.passed,
    required this.onBid,
    required this.onPass,
  });

  final List<String> playerNames;
  final List<List<PlayingCard>> hands;
  final int currentBidderIndex;
  final Bid? highestBid;
  final int? highestBidderIndex;
  final List<bool> passed;
  final ValueChanged<Bid> onBid;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentName = playerNames[currentBidderIndex];
    final currentHand = hands[currentBidderIndex];

    // Bids available to the current bidder: all bids strictly higher than the
    // current highest (or all bids if no bid has been made yet).
    final availableBids = Bid.allBids
        .where((b) => highestBid == null || b.isHigherThan(highestBid!))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Current bid banner ───────────────────────────────────────────────
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.gavel, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuværende bud',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                      Text(
                        highestBid == null
                            ? 'Ingen bud endnu'
                            : '${highestBid!.label}  –  ${playerNames[highestBidderIndex!]}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Player status row ────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(playerNames.length, (i) {
                final isCurrent = i == currentBidderIndex;
                final hasPassed = passed[i];
                final hasHighestBid = i == highestBidderIndex;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: hasPassed
                          ? Colors.grey.shade300
                          : isCurrent
                              ? theme.colorScheme.primary
                              : hasHighestBid
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.grey.shade100,
                      child: Text(
                        playerNames[i][0].toUpperCase(),
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : hasPassed
                                  ? Colors.grey
                                  : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playerNames[i],
                      style: theme.textTheme.labelSmall,
                    ),
                    Text(
                      hasPassed
                          ? 'Pas'
                          : hasHighestBid
                              ? highestBid!.label
                              : '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: hasPassed
                            ? Colors.grey
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Current bidder's hand ────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.style, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$currentName – din hånd',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HandReadOnly(hand: currentHand),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Available bids ───────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.leaderboard, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$currentName – vælg bud eller pas',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...availableBids.map(
                      (bid) => ElevatedButton(
                        onPressed: () => onBid(bid),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          bid.label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onPass,
                      icon: const Icon(Icons.do_not_disturb),
                      label: const Text('Pas'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Caller setup phase widget
// ─────────────────────────────────────────────────────────────────────────────

class _CallerSetupPhase extends StatelessWidget {
  const _CallerSetupPhase({
    required this.playerNames,
    required this.callerIndex,
    required this.bid,
    required this.callerHand,
    required this.talon,
    required this.trump,
    required this.calledCard,
    required this.onTrumpChanged,
    required this.onCalledCardChanged,
    required this.onStart,
  });

  final List<String> playerNames;
  final int callerIndex;
  final Bid bid;
  final List<PlayingCard> callerHand;
  final List<PlayingCard> talon;
  final Suit trump;
  final PlayingCard? calledCard;
  final ValueChanged<Suit> onTrumpChanged;
  final ValueChanged<PlayingCard?> onCalledCardChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final callerName = playerNames[callerIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Winner banner ────────────────────────────────────────────────────
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$callerName vandt buddet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Bud: ${bid.label}  –  ${bid.tricksNeeded} stik krævet, '
                        '${bid.pointsPerTrick} point pr. stik',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Talon (middle pile) ──────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Talon (${talon.length} kort)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Kun $callerName kan se disse kort',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: talon
                      .map((card) => _CardTile(card: card, trump: trump))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Caller's hand ────────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.style, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$callerName – din hånd',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HandReadOnly(hand: callerHand, trump: trump),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Trump selection ──────────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Trumf',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: Suit.values.map((suit) {
                    final selected = trump == suit;
                    return ChoiceChip(
                      label: Text(
                        '${suit.symbol} ${suit.danishName}',
                        style: TextStyle(
                          fontSize: 16,
                          color: selected ? Colors.white : null,
                        ),
                      ),
                      selected: selected,
                      selectedColor: theme.colorScheme.primary,
                      onSelected: (_) => onTrumpChanged(suit),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Called card (partner identification) ─────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Meld kort (makker)',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Vælg det kort der identificerer din makker (valgfrit)',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                _CalledCardPicker(
                  selectedCard: calledCard,
                  onChanged: onCalledCardChanged,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Begynd runde'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable card-display widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Displays a hand of cards grouped by suit (read-only, no interaction).
class _HandReadOnly extends StatelessWidget {
  const _HandReadOnly({required this.hand, this.trump});

  final List<PlayingCard> hand;
  final Suit? trump;

  Color _suitColor(Suit suit) =>
      (suit == Suit.hearts || suit == Suit.diamonds)
          ? Colors.red.shade700
          : Colors.black87;

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) {
      return const Text('Ingen kort',
          style: TextStyle(color: Colors.black54));
    }
    final bySuit = <Suit, List<PlayingCard>>{};
    for (final card in hand) {
      bySuit.putIfAbsent(card.suit, () => []).add(card);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bySuit.entries.map((entry) {
        final suit = entry.key;
        final isTrump = trump == suit;
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
                  if (isTrump)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.amber.shade700),
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
                children: entry.value
                    .map((card) => _CardTile(card: card, trump: trump))
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// A compact read-only card tile.
class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, this.trump});

  final PlayingCard card;
  final Suit? trump;

  Color _suitColor(Suit suit) =>
      (suit == Suit.hearts || suit == Suit.diamonds)
          ? Colors.red.shade700
          : Colors.black87;

  @override
  Widget build(BuildContext context) {
    final isTrump = trump != null && card.suit == trump;
    return Container(
      width: 44,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isTrump ? Colors.amber.shade700 : Colors.grey.shade400,
          width: isTrump ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.rank.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _suitColor(card.suit),
            ),
          ),
          Text(
            card.suit.symbol,
            style: TextStyle(
              fontSize: 16,
              color: _suitColor(card.suit),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Called card picker (partner identification)
// ─────────────────────────────────────────────────────────────────────────────

/// A compact card picker: select suit then rank.
class _CalledCardPicker extends StatefulWidget {
  const _CalledCardPicker({
    required this.selectedCard,
    required this.onChanged,
  });

  final PlayingCard? selectedCard;
  final ValueChanged<PlayingCard?> onChanged;

  @override
  State<_CalledCardPicker> createState() => _CalledCardPickerState();
}

class _CalledCardPickerState extends State<_CalledCardPicker> {
  Suit? _suit;

  @override
  void initState() {
    super.initState();
    _suit = widget.selectedCard?.suit;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Ingen'),
              backgroundColor:
                  widget.selectedCard == null ? Colors.grey.shade300 : null,
              onPressed: () {
                setState(() => _suit = null);
                widget.onChanged(null);
              },
            ),
            ...Suit.values.map((suit) {
              final selected = _suit == suit;
              return ActionChip(
                label: Text(
                  '${suit.symbol} ${suit.danishName}',
                  style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                backgroundColor: selected ? Colors.blue.shade100 : null,
                onPressed: () {
                  setState(() => _suit = suit);
                  widget.onChanged(
                      PlayingCard(suit: suit, rank: Rank.ace));
                },
              );
            }),
          ],
        ),
        if (_suit != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: Rank.values.reversed.map((rank) {
              final card = PlayingCard(suit: _suit!, rank: rank);
              final selected = widget.selectedCard == card;
              return ChoiceChip(
                label: Text(rank.label),
                selected: selected,
                onSelected: (_) => widget.onChanged(card),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

