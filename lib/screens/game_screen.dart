import 'dart:async';

import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/play_state.dart';
import '../services/session_service.dart';
import '../widgets/connection_banner.dart';
import 'deal_screen.dart';
import 'play_round_screen.dart';
import 'round_screen.dart';
import 'rules_screen.dart';
import 'scoreboard_screen.dart';
import 'setup_screen.dart';

/// Main game screen with tabs for [RoundScreen] and [ScoreboardScreen].
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.gameState,
    this.sessionService,
    this.roomCode,
    this.myPlayerIndex,
  });

  final GameState gameState;

  /// Non-null when playing in online mode.
  final SessionService? sessionService;
  final String? roomCode;

  /// This device's player index in online mode (null = local / all players).
  final int? myPlayerIndex;

  bool get isOnline => sessionService != null && roomCode != null;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  int _tabIndex = 0;
  StreamSubscription<SessionSnapshot>? _sessionSub;
  bool _navigatedToPlay = false;

  @override
  void initState() {
    super.initState();
    _gameState = widget.gameState;
    if (widget.isOnline) {
      _sessionSub = widget.sessionService!
          .watchSession(widget.roomCode!)
          .listen(_onSessionUpdate);
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  void _onSessionUpdate(SessionSnapshot snapshot) {
    if (!mounted) return;

    // Sync game state from Firebase.
    if (snapshot.gameState != null) {
      setState(() => _gameState = snapshot.gameState!);
    }

    // Auto-navigate to PlayRoundScreen when a play round starts.
    if (snapshot.playState != null && !_navigatedToPlay) {
      _navigatedToPlay = true;
      final playState = snapshot.playState!;
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => _buildOnlinePlayRoundScreen(playState),
            ),
          )
          .then((_) => _navigatedToPlay = false);
    }
  }

  Widget _buildOnlinePlayRoundScreen(PlayState playState) {
    return PlayRoundScreen(
      initialState: playState,
      onRoundComplete: (scores, {String? caller, String? partner}) {
        _onRoundSubmitted(scores, caller: caller, partner: partner);
        widget.sessionService!.endPlayRound(widget.roomCode!);
      },
      sessionService: widget.sessionService,
      roomCode: widget.roomCode,
      myPlayerIndex: widget.myPlayerIndex,
    );
  }

  void _onRoundSubmitted(
    Map<String, int> scores, {
    String? caller,
    String? partner,
  }) {
    final newState =
        _gameState.addRound(scores, caller: caller, partner: partner);
    setState(() {
      _gameState = newState;
      _tabIndex = 1;
    });
    if (widget.isOnline) {
      widget.sessionService!.updateGameState(widget.roomCode!, newState);
    }
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
        final newState = _gameState.undoLastRound();
        setState(() => _gameState = newState);
        if (widget.isOnline) {
          widget.sessionService!
              .updateGameState(widget.roomCode!, newState);
        }
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
        if (widget.isOnline) {
          widget.sessionService!.endSession(widget.roomCode!);
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      }
    });
  }

  void _onPlayRound() {
    final playerNames = _gameState.players.map((p) => p.name).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DealScreen(
          playerNames: playerNames,
          onRoundComplete: (scores, {String? caller, String? partner}) {
            _onRoundSubmitted(scores, caller: caller, partner: partner);
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
        title: widget.isOnline
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Es Makker'),
                  Text(
                    'Rum: ${widget.roomCode}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              )
            : const Text('Es Makker'),
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
      body: Column(
        children: [
          if (widget.isOnline)
            ConnectionBanner(sessionService: widget.sessionService!),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                RoundScreen(
                  gameState: _gameState,
                  onRoundSubmitted: _onRoundSubmitted,
                ),
                ScoreboardScreen(gameState: _gameState),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPlayRound,
        icon: const Icon(Icons.style),
        label: const Text('Spil runde'),
        tooltip: 'Spil en runde med kort',
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
