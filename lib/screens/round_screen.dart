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
  final void Function(Map<String, int> scores) onRoundSubmitted;

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

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
      for (final c in _controllers.values) {
        c.text = '';
      }
    }
  }

  void _initControllers() {
    for (final player in widget.gameState.players) {
      _controllers[player.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submitRound() {
    if (!_formKey.currentState!.validate()) return;

    final scores = <String, int>{};
    for (final player in widget.gameState.players) {
      scores[player.name] =
          int.parse(_controllers[player.name]!.text.trim());
    }

    widget.onRoundSubmitted(scores);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roundNumber = widget.gameState.currentRoundNumber;

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
              // Score fields
              ...widget.gameState.players.map((player) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            player.name[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            player.name,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _controllers[player.name],
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^-?\d*')),
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
