import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/round.dart';
import '../theme/app_theme.dart';

/// Displays cumulative scores and round-by-round history.
class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key, required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    if (gameState.rounds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'Ingen runder endnu.\nGå til "Runde" fanen for at tilføje point.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TotalScoresCard(gameState: gameState),
        const SizedBox(height: 16),
        _RoundHistoryCard(gameState: gameState),
      ],
    );
  }
}

/// Card showing the current standings (sorted by total score, highest first).
class _TotalScoresCard extends StatelessWidget {
  const _TotalScoresCard({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = gameState.totalScores;

    final sorted = gameState.players.toList()
      ..sort((a, b) => totals[b.name]!.compareTo(totals[a.name]!));

    return Card(
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
                  'Stilling',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${gameState.rounds.length} '
                  '${gameState.rounds.length == 1 ? 'runde' : 'runder'}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
            const Divider(height: 24),
            ...sorted.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final player = entry.value;
              final score = totals[player.name]!;
              final isLeader = rank == 1;
              return _ScoreRow(
                rank: rank,
                name: player.name,
                score: score,
                highlight: isLeader,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.highlight,
  });

  final int rank;
  final String name;
  final int score;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rankIcon = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : '$rank.';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(rankIcon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight:
                    highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            score >= 0 ? '+$score' : '$score',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: score >= 0 ? AppColors.positive : AppColors.negative,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card showing a table with per-round scores.
class _RoundHistoryCard extends StatelessWidget {
  const _RoundHistoryCard({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final players = gameState.players;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Rundehistorik',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.primaryContainer),
                columnSpacing: 24,
                columns: [
                  const DataColumn(
                    label: Text('Runde',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...players.map(
                    (p) => DataColumn(
                      label: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                rows: [
                  ...gameState.rounds.map(
                    (round) => _buildRoundRow(context, round),
                  ),
                  _buildTotalsRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRoundRow(BuildContext context, Round round) {
    final makkerLabel = (round.caller != null && round.partner != null)
        ? '${round.caller} & ${round.partner}'
        : round.caller != null
            ? round.caller!
            : null;

    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${round.roundNumber}'),
              if (makkerLabel != null)
                Text(
                  makkerLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ),
        ...gameState.players.map((p) {
          final score = round.scores[p.name] ?? 0;
          return DataCell(
            Text(
              score >= 0 ? '+$score' : '$score',
              style: TextStyle(
                color: score >= 0 ? AppColors.positive : AppColors.negative,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ],
    );
  }

  DataRow _buildTotalsRow(BuildContext context) {
    final theme = Theme.of(context);
    final totals = gameState.totalScores;

    return DataRow(
      color: WidgetStateProperty.all(
          theme.colorScheme.secondaryContainer),
      cells: [
        const DataCell(
          Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...gameState.players.map((p) {
          final score = totals[p.name] ?? 0;
          return DataCell(
            Text(
              score >= 0 ? '+$score' : '$score',
              style: TextStyle(
                color: score >= 0 ? AppColors.positive : AppColors.negative,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          );
        }),
      ],
    );
  }
}
