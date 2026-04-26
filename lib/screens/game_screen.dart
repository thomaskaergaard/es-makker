import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'round_screen.dart';
import 'rules_screen.dart';
import 'scoreboard_screen.dart';
import 'setup_screen.dart';

/// Main game screen with tabs for [RoundScreen] and [ScoreboardScreen].
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameState});

  final GameState gameState;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _gameState = widget.gameState;
  }

  void _onRoundSubmitted(
    Map<String, int> scores, {
    String? caller,
    String? partner,
  }) {
    setState(() {
      _gameState = _gameState.addRound(scores, caller: caller, partner: partner);
      _tabIndex = 1; // Switch to scoreboard after adding a round.
    });
  }

  void _onUndoLastRound() {
    if (_gameState.rounds.isEmpty) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fortryd runde?'),
        content: Text(
          'Er du sikker på, at du vil slette runde '
          '${_gameState.rounds.last.roundNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fortryd'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _gameState = _gameState.undoLastRound();
        });
      }
    });
  }

  void _onNewGame() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nyt spil?'),
        content: const Text(
          'Er du sikker på, at du vil starte et nyt spil? '
          'Alle runder og point vil blive slettet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nyt spil'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _Tab(
        label: 'Runde ${_gameState.currentRoundNumber}',
        icon: Icons.edit_note,
      ),
      _Tab(
        label: 'Stilling',
        icon: Icons.leaderboard,
        badge: _gameState.rounds.isNotEmpty
            ? '${_gameState.rounds.length}'
            : null,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Es Makker'),
        actions: [
          IconButton(
            tooltip: 'Regler',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RulesScreen()),
            ),
          ),
          if (_gameState.rounds.isNotEmpty)
            IconButton(
              tooltip: 'Fortryd seneste runde',
              icon: const Icon(Icons.undo),
              onPressed: _onUndoLastRound,
            ),
          IconButton(
            tooltip: 'Nyt spil',
            icon: const Icon(Icons.refresh),
            onPressed: _onNewGame,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(tabs),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          RoundScreen(
            gameState: _gameState,
            onRoundSubmitted: _onRoundSubmitted,
          ),
          ScoreboardScreen(gameState: _gameState),
        ],
      ),
    );
  }

  Widget _buildTabBar(List<_Tab> tabs) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final tab = tabs[i];
        final selected = _tabIndex == i;
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => _tabIndex = i),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tab.icon,
                    size: 18,
                    color: selected
                        ? Colors.white
                        : Colors.white.withAlpha(153),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withAlpha(153),
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (tab.badge != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tab.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final String? badge;
  const _Tab({required this.label, required this.icon, this.badge});
}
