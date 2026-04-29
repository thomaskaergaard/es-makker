import 'package:flutter/material.dart';
import '../models/playing_card.dart';
import '../models/play_state.dart';
import '../services/session_service.dart';
import 'play_round_screen.dart';

/// Screen where the caller selects trump suit and the card to call for a partner.
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
  int _callerIndex = 0;
  Suit _trump = Suit.spades;
  PlayingCard? _calledCard;

  void _startRound() {
    final playState = PlayState.start(
      playerNames: widget.playerNames,
      trump: _trump,
      callerIndex: _callerIndex,
      calledCard: _calledCard,
    );

    if (widget.isOnline) {
      // Publish play state to Firebase; all devices will navigate to
      // PlayRoundScreen via the GameScreen stream listener.
      widget.sessionService!.startPlayRound(widget.roomCode!, playState);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayRoundScreen(
          initialState: playState,
          onRoundComplete: (scores, {String? caller, String? partner}) {
            Navigator.of(context).pop(); // Pop back from DealScreen
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ny runde – Opsætning'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Caller selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Spiller (melder)',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _callerIndex,
                        decoration:
                            const InputDecoration(labelText: 'Vælg spiller'),
                        items: List.generate(
                          widget.playerNames.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(widget.playerNames[i]),
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _callerIndex = v ?? 0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Trump selection
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
                            'Trumf',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: Suit.values.map((suit) {
                          final selected = _trump == suit;
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
                            onSelected: (_) =>
                                setState(() => _trump = suit),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Called card (partner identification)
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
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vælg det kort der identificerer din makker (valgfrit)',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      _CalledCardPicker(
                        selectedCard: _calledCard,
                        onChanged: (card) =>
                            setState(() => _calledCard = card),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startRound,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Del kort og spil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        // Suit row
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
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                backgroundColor: selected ? Colors.blue.shade100 : null,
                onPressed: () {
                  setState(() => _suit = suit);
                  // Default to Ace
                  widget.onChanged(PlayingCard(suit: suit, rank: Rank.ace));
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
