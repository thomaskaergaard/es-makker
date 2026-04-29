import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../services/local_storage_service.dart';
import '../services/session_service.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';
import 'rules_screen.dart';

/// First screen – lets users configure the number of players and their names.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const int _minPlayers = 2;
  static const int _maxPlayers = 6;

  int _playerCount = 4;
  final List<TextEditingController> _nameControllers = [];
  final _formKey = GlobalKey<FormState>();
  final _localStorage = LocalStorageService();
  GameState? _savedGame;

  @override
  void initState() {
    super.initState();
    _savedGame = _localStorage.loadGameState();
    _updateControllers(_playerCount);
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateControllers(int count) {
    while (_nameControllers.length < count) {
      final index = _nameControllers.length + 1;
      _nameControllers.add(
        TextEditingController(text: 'Spiller $index'),
      );
    }
    while (_nameControllers.length > count) {
      _nameControllers.removeLast().dispose();
    }
  }

  void _startGame() {
    if (!_formKey.currentState!.validate()) return;

    final players = _nameControllers
        .map((c) => Player(name: c.text.trim()))
        .toList();

    // Check for duplicate names.
    final names = players.map((p) => p.name).toSet();
    if (names.length != players.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spillernavne skal være unikke.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Clear any previously saved local game before starting a new one.
    _localStorage.clearGameState();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameState: GameState(players: players),
        ),
      ),
    );
  }

  void _resumeGame() {
    if (_savedGame == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(gameState: _savedGame!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Es Makker – Opsætning'),
        actions: [
          IconButton(
            tooltip: 'Online spil',
            icon: const Icon(Icons.wifi),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LobbyScreen(sessionService: SessionService()),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Regler',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RulesScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Header card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antal spillere',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filled(
                              onPressed: _playerCount > _minPlayers
                                  ? () => setState(() {
                                        _playerCount--;
                                        _updateControllers(_playerCount);
                                      })
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '$_playerCount',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton.filled(
                              onPressed: _playerCount < _maxPlayers
                                  ? () => setState(() {
                                        _playerCount++;
                                        _updateControllers(_playerCount);
                                      })
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Player name fields
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spillernavne',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(_playerCount, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _nameControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Spiller ${i + 1}',
                                prefixIcon: const Icon(Icons.person),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Navn må ikke være tomt';
                                }
                                if (v.trim().length > 30) {
                                  return 'Navn er for langt';
                                }
                                return null;
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_savedGame != null) ...[
                  OutlinedButton.icon(
                    onPressed: _resumeGame,
                    icon: const Icon(Icons.restore),
                    label: Text(
                      'Fortsæt spil '
                      '(${_savedGame!.players.map((p) => p.name).join(', ')} '
                      '– runde ${_savedGame!.currentRoundNumber})',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start nyt spil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
