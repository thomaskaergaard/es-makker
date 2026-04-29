import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import 'game_screen.dart';

/// Screen shown while waiting for all players to join before the game starts.
/// The host can start the game once at least 2 players have joined.
/// Non-host players are automatically forwarded when the host starts.
class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({
    super.key,
    required this.sessionService,
    required this.roomCode,
  });

  final SessionService sessionService;
  final String roomCode;

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  bool _starting = false;
  bool _navigated = false;

  void _startGame(List<SessionPlayer> players) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await widget.sessionService.startGame(widget.roomCode, players);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke starte spillet: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _starting = false);
    }
  }

  void _navigateToGame(SessionSnapshot snapshot) {
    if (_navigated || !mounted) return;
    _navigated = true;
    final gameState = snapshot.gameState!;
    final myPlayerIndex = snapshot.myPlayerIndex;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameState: gameState,
          sessionService: widget.sessionService,
          roomCode: widget.roomCode,
          myPlayerIndex: myPlayerIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venter på spillere'),
      ),
      body: StreamBuilder<SessionSnapshot>(
        stream: widget.sessionService.watchSession(widget.roomCode),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Fejl: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = snap.data!;
          if (!session.exists) {
            return const Center(child: Text('Rummet blev ikke fundet.'));
          }

          // Auto-navigate when host has started the game.
          if (session.phase == 'playing' && session.gameState != null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _navigateToGame(session));
          }

          final players = session.sortedPlayers;
          final isHost = session.isHost;
          final canStart = isHost && players.length >= 2 && !_starting;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Room code card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.vpn_key,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Rumkode',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.roomCode,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: widget.roomCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Rumkode kopieret!')),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Kopiér kode'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Del koden med de andre spillere',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Players list card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Spillere (${players.length})',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...players.map((p) {
                            final isMe =
                                p.playerId == session.myPlayerId;
                            final isGameHost =
                                p.playerId == session.hostPlayerId;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isMe
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primaryContainer,
                                child: Text(
                                  p.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isMe
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme
                                            .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                p.name + (isMe ? ' (dig)' : ''),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: isMe
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isGameHost
                                  ? Chip(
                                      label: const Text('Vært'),
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onPrimary,
                                      ),
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap,
                                    )
                                  : null,
                            );
                          }),
                          if (players.length < 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Mindst 2 spillere kræves for at starte.',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.black54),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (isHost)
                    ElevatedButton.icon(
                      onPressed:
                          canStart ? () => _startGame(players) : null,
                      icon: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Start spil'),
                    )
                  else
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Venter på at værten starter spillet…',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
