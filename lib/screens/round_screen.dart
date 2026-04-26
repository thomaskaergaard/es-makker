import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

/// Screen for entering each player's score for the current round.
class RoundScreen extends StatefulWidget {
  const RoundScreen({
    super.key,
    required this.gameState,
    required this.onRoundSubmitted,
  });

  final GameState gameState;
  final void Function(
    Map<String, int> scores, {
    String? caller,
    String? partner,
  }) onRoundSubmitted;

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  String? _caller;
  String? _partner;

  // Sync state: mirrors the score between caller and partner.
  String? _syncedCaller;
  String? _syncedPartner;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(RoundScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameState.currentRoundNumber !=
        widget.gameState.currentRoundNumber) {
      // Clear fields when a new round starts.
      _removeSyncListeners();
      for (final c in _controllers.values) {
        c.text = '';
      }
      setState(() {
        _caller = null;
        _partner = null;
      });
    }
  }

  void _initControllers() {
    for (final player in widget.gameState.players) {
      _controllers[player.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _removeSyncListeners();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCallerScoreChanged() {
    if (_syncing || _caller == null || _partner == null) return;
    _syncing = true;
    _controllers[_partner]!.text = _controllers[_caller]!.text;
    _syncing = false;
  }

  void _onPartnerScoreChanged() {
    if (_syncing || _caller == null || _partner == null) return;
    _syncing = true;
    _controllers[_caller]!.text = _controllers[_partner]!.text;
    _syncing = false;
  }

  /// Removes any existing sync listeners and attaches new ones for the current
  /// caller/partner pair. Also copies the caller's current score to the partner
  /// immediately when both are set.
  void _attachSyncListeners() {
    _removeSyncListeners();
    if (_caller == null || _partner == null) return;

    // Immediately copy the caller's current value to the partner.
    // Use the _syncing guard so that adding the partner listener below does
    // not bounce the value back to the caller.
    _syncing = true;
    _controllers[_partner]!.text = _controllers[_caller]!.text;
    _syncing = false;

    _controllers[_caller]!.addListener(_onCallerScoreChanged);
    _controllers[_partner]!.addListener(_onPartnerScoreChanged);
    _syncedCaller = _caller;
    _syncedPartner = _partner;
  }

  void _removeSyncListeners() {
    if (_syncedCaller != null) {
      _controllers[_syncedCaller]?.removeListener(_onCallerScoreChanged);
    }
    if (_syncedPartner != null) {
      _controllers[_syncedPartner]?.removeListener(_onPartnerScoreChanged);
    }
    _syncedCaller = null;
    _syncedPartner = null;
  }

  void _submitRound() {
    if (!_formKey.currentState!.validate()) return;

    final scores = <String, int>{};
    for (final player in widget.gameState.players) {
      scores[player.name] =
          int.parse(_controllers[player.name]!.text.trim());
    }

    widget.onRoundSubmitted(scores, caller: _caller, partner: _partner);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roundNumber = widget.gameState.currentRoundNumber;
    final players = widget.gameState.players;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Round header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$roundNumber',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Runde $roundNumber',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Makker-par selection
              _MakkerSelection(
                players: players.map((p) => p.name).toList(),
                caller: _caller,
                partner: _partner,
                onCallerChanged: (v) => setState(() {
                  _caller = v;
                  if (v == null) {
                    _partner = null; // no caller → no partner
                  } else if (_partner == v) {
                    _partner = null; // same player can't be both
                  }
                  _attachSyncListeners();
                }),
                onPartnerChanged: (v) => setState(() {
                  _partner = v;
                  if (v != null && _caller == v) _caller = null;
                  _attachSyncListeners();
                }),
              ),
              const SizedBox(height: 8),
              // Score fields
              ...players.map((player) {
                final isCaller = player.name == _caller;
                final isPartner = player.name == _partner;
                final inMakkerPair = isCaller || isPartner;
                return Card(
                  color: inMakkerPair
                      ? theme.colorScheme.primaryContainer.withAlpha(128)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: inMakkerPair
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: TextStyle(
                              color: inMakkerPair
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                player.name,
                                style: theme.textTheme.bodyLarge,
                              ),
                              if (isCaller)
                                Text(
                                  'Spiller',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else if (isPartner)
                                Text(
                                  'Makker',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _controllers[player.name],
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              _SignedIntegerInputFormatter(),
                            ],
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '0',
                              labelText: 'Point',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Påkrævet';
                              }
                              if (int.tryParse(v.trim()) == null) {
                                return 'Ugyldigt';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // Previous round summary (if available)
              if (widget.gameState.rounds.isNotEmpty) ...[
                _PreviousRoundSummary(gameState: widget.gameState),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _submitRound,
                icon: const Icon(Icons.check),
                label: Text('Gem runde $roundNumber'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for selecting the spiller (caller) and makker (partner) for the round.
class _MakkerSelection extends StatelessWidget {
  const _MakkerSelection({
    required this.players,
    required this.caller,
    required this.partner,
    required this.onCallerChanged,
    required this.onPartnerChanged,
  });

  final List<String> players;
  final String? caller;
  final String? partner;
  final ValueChanged<String?> onCallerChanged;
  final ValueChanged<String?> onPartnerChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partnerEnabled = caller != null;

    DropdownMenuItem<String> noneItem(String label) => DropdownMenuItem<String>(
          value: null,
          child: Text(label, style: const TextStyle(color: Colors.black45)),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Makker-par (valgfrit)',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: caller,
                    decoration: const InputDecoration(labelText: 'Spiller'),
                    items: [
                      noneItem('Ingen'),
                      ...players.map(
                        (p) => DropdownMenuItem<String>(
                          value: p,
                          child: Text(p),
                        ),
                      ),
                    ],
                    onChanged: onCallerChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: partner,
                    decoration: InputDecoration(
                      labelText: 'Makker',
                      enabled: partnerEnabled,
                    ),
                    items: partnerEnabled
                        ? [
                            noneItem('Ingen'),
                            ...players
                                .where((p) => p != caller)
                                .map(
                                  (p) => DropdownMenuItem<String>(
                                    value: p,
                                    child: Text(p),
                                  ),
                                ),
                          ]
                        : [noneItem('Vælg spiller først')],
                    onChanged: partnerEnabled ? onPartnerChanged : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Input formatter that allows only valid signed integer prefixes:
/// an optional leading minus followed by zero or more digits.
class _SignedIntegerInputFormatter extends TextInputFormatter {
  static final _pattern = RegExp(r'^-?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_pattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

/// Shows a compact summary of the last completed round.
class _PreviousRoundSummary extends StatelessWidget {
  const _PreviousRoundSummary({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastRound = gameState.rounds.last;

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seneste runde (${lastRound.roundNumber})',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: lastRound.scores.entries.map((e) {
                final score = e.value;
                final color =
                    score >= 0 ? AppColors.positive : AppColors.negative;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.key,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(width: 4),
                    Text(
                      score >= 0 ? '+$score' : '$score',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
