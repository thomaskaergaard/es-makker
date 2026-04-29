import 'package:flutter/material.dart';
import '../services/session_service.dart';

/// A banner that appears at the top of the screen when the Firebase Realtime
/// Database WebSocket connection is lost. Automatically hides when the
/// connection is restored.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.sessionService});

  final SessionService sessionService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: sessionService.onConnectionState,
      initialData: true,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? true;
        if (connected) return const SizedBox.shrink();

        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: const Icon(Icons.wifi_off, color: Colors.white),
          backgroundColor: Colors.red.shade700,
          content: const Text(
            'Ingen forbindelse – forsøger at genoprette…',
            style: TextStyle(color: Colors.white),
          ),
          actions: const [],
        );
      },
    );
  }
}
