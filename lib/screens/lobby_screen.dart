import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'waiting_room_screen.dart';

/// Screen where players choose to create or join an online game session.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.sessionService});

  final SessionService sessionService;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _createNameController = TextEditingController(text: 'Spiller 1');
  final _createFormKey = GlobalKey<FormState>();
  bool _isPublic = false;

  final _joinNameController = TextEditingController(text: 'Spiller');
  final _joinCodeController = TextEditingController();
  final _joinFormKey = GlobalKey<FormState>();

  final _browseNameController = TextEditingController(text: 'Spiller');

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createNameController.dispose();
    _joinNameController.dispose();
    _joinCodeController.dispose();
    _browseNameController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (!_createFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final roomCode = await widget.sessionService.createSession(
        _createNameController.text.trim(),
        isPublic: _isPublic,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            sessionService: widget.sessionService,
            roomCode: roomCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Kunne ikke oprette spillet. Tjek din internetforbindelse.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinGame() async {
    if (!_joinFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final code = _joinCodeController.text.trim().toUpperCase();
      final ok = await widget.sessionService
          .joinSession(code, _joinNameController.text.trim());
      if (!mounted) return;
      if (!ok) {
        _showError(
            'Rummet "$code" blev ikke fundet eller er allerede startet.');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            sessionService: widget.sessionService,
            roomCode: code,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Kunne ikke deltage. Tjek din internetforbindelse.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _joinPublicGame(String roomCode) async {
    final playerName = _browseNameController.text.trim();
    if (playerName.isEmpty) {
      _showError('Angiv dit navn for at deltage.');
      return;
    }
    setState(() => _loading = true);
    try {
      final ok =
          await widget.sessionService.joinSession(roomCode, playerName);
      if (!mounted) return;
      if (!ok) {
        _showError(
            'Rummet "$roomCode" blev ikke fundet eller er allerede startet.');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            sessionService: widget.sessionService,
            roomCode: roomCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Kunne ikke deltage. Tjek din internetforbindelse.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online spil'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Opret spil'),
            Tab(icon: Icon(Icons.login), text: 'Deltag i spil'),
            Tab(icon: Icon(Icons.public), text: 'Offentlige spil'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CreateTab(
                      formKey: _createFormKey,
                      nameController: _createNameController,
                      onSubmit: _createGame,
                      theme: theme,
                      isPublic: _isPublic,
                      onPublicChanged: (v) => setState(() => _isPublic = v),
                    ),
                    _JoinTab(
                      formKey: _joinFormKey,
                      nameController: _joinNameController,
                      codeController: _joinCodeController,
                      onSubmit: _joinGame,
                      theme: theme,
                    ),
                    _PublicGamesTab(
                      sessionService: widget.sessionService,
                      nameController: _browseNameController,
                      onJoin: _joinPublicGame,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CreateTab extends StatelessWidget {
  const _CreateTab({
    required this.formKey,
    required this.nameController,
    required this.onSubmit,
    required this.theme,
    required this.isPublic,
    required this.onPublicChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final VoidCallback onSubmit;
  final ThemeData theme;
  final bool isPublic;
  final ValueChanged<bool> onPublicChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Icon(Icons.wifi, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Opret et nyt spil og del rumkoden med de andre spillere.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dit navn',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Navn',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Navn må ikke være tomt';
                      }
                      if (v.trim().length > 30) return 'Navn er for langt';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Offentligt spil'),
                    subtitle: const Text(
                      'Andre spillere kan finde og deltage i dit spil '
                      'uden at kende rumkoden.',
                    ),
                    value: isPublic,
                    onChanged: onPublicChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.add),
            label: const Text('Opret spil'),
          ),
        ],
      ),
    );
  }
}

class _JoinTab extends StatelessWidget {
  const _JoinTab({
    required this.formKey,
    required this.nameController,
    required this.codeController,
    required this.onSubmit,
    required this.theme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final VoidCallback onSubmit;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Icon(Icons.group_add, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Indtast rumkoden fra den spiller, der har oprettet spillet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oplysninger',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Dit navn',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Navn må ikke være tomt';
                      }
                      if (v.trim().length > 30) return 'Navn er for langt';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Rumkode',
                      prefixIcon: Icon(Icons.vpn_key),
                      hintText: 'f.eks. AB3X7Z',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Indtast rumkoden';
                      }
                      if (v.trim().length != 6) {
                        return 'Rumkoden skal være 6 tegn';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.login),
            label: const Text('Deltag'),
          ),
        ],
      ),
    );
  }
}

class _PublicGamesTab extends StatelessWidget {
  const _PublicGamesTab({
    required this.sessionService,
    required this.nameController,
    required this.onJoin,
    required this.theme,
  });

  final SessionService sessionService;
  final TextEditingController nameController;
  final void Function(String roomCode) onJoin;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Icon(Icons.public, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Find et offentligt spil og deltag uden rumkode.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dit navn',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Navn',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tilgængelige spil',
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<PublicSessionInfo>>(
          stream: sessionService.watchPublicSessions(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Fejl: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final sessions = snap.data!;
            if (sessions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.onSurface.withAlpha(100)),
                      const SizedBox(height: 12),
                      Text(
                        'Ingen offentlige spil lige nu.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Opret et offentligt spil, eller prøv igen senere.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.black38),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: sessions
                  .map((s) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              s.hostName.isNotEmpty
                                  ? s.hostName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${s.hostName}\'s spil',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Rum: ${s.roomCode}'),
                          trailing: FilledButton(
                            onPressed: () => onJoin(s.roomCode),
                            child: const Text('Deltag'),
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
