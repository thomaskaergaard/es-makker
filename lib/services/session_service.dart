import 'dart:math';
// This app is Flutter Web only. dart:html is used for browser localStorage
// to persist the player ID across sessions. If support for other platforms
// is needed in the future, replace with the shared_preferences package.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:firebase_database/firebase_database.dart';

import '../models/game_state.dart';
import '../models/play_state.dart';
import '../models/player.dart';

/// Manages online game sessions via Firebase Realtime Database.
///
/// Each session is stored at `sessions/{roomCode}` with the structure:
/// ```
/// {
///   "phase": "waiting" | "playing" | "finished",
///   "hostPlayerId": "...",
///   "players": {
///     "{playerId}": { "name": "Alice", "index": 0 }
///   },
///   "gameState": { ...serialized GameState... },
///   "playState": { ...serialized PlayState... } | null
/// }
/// ```
class SessionService {
  static const _playerIdKey = 'es_makker_player_id';

  final FirebaseDatabase _db;
  late final String _playerId;

  SessionService({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance {
    _playerId = _getOrCreatePlayerId();
  }

  String get playerId => _playerId;

  // ---------------------------------------------------------------------------
  // Connection state
  // ---------------------------------------------------------------------------

  /// Stream that emits `true` when connected to Firebase and `false` when
  /// disconnected. Useful for showing a banner when the WebSocket drops.
  Stream<bool> get onConnectionState {
    return _db
        .ref('.info/connected')
        .onValue
        .map((event) => event.snapshot.value == true);
  }

  // ---------------------------------------------------------------------------
  // Player identity (persisted in browser localStorage)
  // ---------------------------------------------------------------------------

  String _getOrCreatePlayerId() {
    final stored = html.window.localStorage[_playerIdKey];
    if (stored != null && stored.isNotEmpty) return stored;
    final id = _randomString(20);
    html.window.localStorage[_playerIdKey] = id;
    return id;
  }

  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }

  // ---------------------------------------------------------------------------
  // Room codes
  // ---------------------------------------------------------------------------

  /// Generates a 6-character room code (uppercase, no ambiguous characters).
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ---------------------------------------------------------------------------
  // Firebase references
  // ---------------------------------------------------------------------------

  DatabaseReference _sessionRef(String roomCode) =>
      _db.ref('sessions/$roomCode');

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  /// Creates a new session and returns the room code.
  Future<String> createSession(String hostName) async {
    final roomCode = generateRoomCode();
    final hostPlayer = SessionPlayer(
      playerId: _playerId,
      name: hostName,
      index: 0,
    );
    await _sessionRef(roomCode).set({
      'phase': 'waiting',
      'hostPlayerId': _playerId,
      'players': {
        _playerId: hostPlayer.toMap(),
      },
      'gameState': null,
      'playState': null,
    });
    return roomCode;
  }

  /// Joins an existing session. Returns `false` if the room is not found or
  /// is no longer accepting players.
  Future<bool> joinSession(String roomCode, String playerName) async {
    final ref = _sessionRef(roomCode);
    final snap = await ref.get();
    if (!snap.exists) return false;

    final data = Map<String, dynamic>.from(snap.value as Map);
    if (data['phase'] != 'waiting') return false;

    final players =
        Map<String, dynamic>.from(data['players'] as Map? ?? {});

    // Already in this session – just return true.
    if (players.containsKey(_playerId)) return true;

    final nextIndex = players.length;
    final newPlayer = SessionPlayer(
      playerId: _playerId,
      name: playerName,
      index: nextIndex,
    );
    await ref.child('players/$_playerId').set(newPlayer.toMap());
    return true;
  }

  /// Starts the game. Only the host should call this.
  Future<void> startGame(String roomCode, List<SessionPlayer> players) async {
    final sortedPlayers = [...players]..sort((a, b) => a.index.compareTo(b.index));
    final gameState = GameState(
      players: sortedPlayers.map((p) => Player(name: p.name)).toList(),
    );
    await _sessionRef(roomCode).update({
      'phase': 'playing',
      'gameState': gameState.toJson(),
    });
  }

  /// Pushes an updated [GameState] (e.g. after a round score is submitted).
  Future<void> updateGameState(String roomCode, GameState gameState) async {
    await _sessionRef(roomCode).child('gameState').set(gameState.toJson());
  }

  /// Writes an initial [PlayState] to start a card-play round.
  Future<void> startPlayRound(String roomCode, PlayState playState) async {
    await _sessionRef(roomCode).child('playState').set(playState.toJson());
  }

  /// Updates the [PlayState] after a card has been played.
  Future<void> updatePlayState(String roomCode, PlayState playState) async {
    await _sessionRef(roomCode).child('playState').set(playState.toJson());
  }

  /// Clears the [PlayState] when a card-play round finishes.
  Future<void> endPlayRound(String roomCode) async {
    await _sessionRef(roomCode).child('playState').set(null);
  }

  /// Marks the session as finished.
  Future<void> endSession(String roomCode) async {
    await _sessionRef(roomCode).update({'phase': 'finished'});
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Returns a stream of [SessionSnapshot]s for the given room.
  Stream<SessionSnapshot> watchSession(String roomCode) {
    return _sessionRef(roomCode).onValue.map((event) {
      if (!event.snapshot.exists) {
        return SessionSnapshot.notFound(myPlayerId: _playerId);
      }
      final data =
          Map<String, dynamic>.from(event.snapshot.value as Map);
      return SessionSnapshot.fromMap(roomCode, _playerId, data);
    });
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class SessionPlayer {
  final String playerId;
  final String name;
  final int index;

  const SessionPlayer({
    required this.playerId,
    required this.name,
    required this.index,
  });

  Map<String, dynamic> toMap() => {'name': name, 'index': index};

  factory SessionPlayer.fromMap(String playerId, Map<String, dynamic> data) =>
      SessionPlayer(
        playerId: playerId,
        name: data['name'] as String,
        index: data['index'] as int,
      );
}

class SessionSnapshot {
  final bool exists;
  final String? roomCode;
  final String? hostPlayerId;
  final String myPlayerId;
  final Map<String, SessionPlayer> players;
  final String phase;
  final GameState? gameState;
  final PlayState? playState;

  const SessionSnapshot({
    required this.exists,
    this.roomCode,
    this.hostPlayerId,
    required this.myPlayerId,
    this.players = const {},
    this.phase = 'waiting',
    this.gameState,
    this.playState,
  });

  factory SessionSnapshot.notFound({required String myPlayerId}) =>
      SessionSnapshot(exists: false, myPlayerId: myPlayerId);

  bool get isHost => myPlayerId == hostPlayerId;

  SessionPlayer? get myPlayer => players[myPlayerId];

  int? get myPlayerIndex => myPlayer?.index;

  List<SessionPlayer> get sortedPlayers {
    final list = players.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  factory SessionSnapshot.fromMap(
    String roomCode,
    String myPlayerId,
    Map<String, dynamic> data,
  ) {
    final playersData =
        Map<String, dynamic>.from(data['players'] as Map? ?? {});
    final players = <String, SessionPlayer>{};
    for (final entry in playersData.entries) {
      players[entry.key] = SessionPlayer.fromMap(
        entry.key,
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    GameState? gameState;
    if (data['gameState'] != null) {
      try {
        gameState = GameState.fromJson(
            Map<String, dynamic>.from(data['gameState'] as Map));
      } catch (_) {}
    }

    PlayState? playState;
    if (data['playState'] != null) {
      try {
        playState = PlayState.fromJson(
            Map<String, dynamic>.from(data['playState'] as Map));
      } catch (_) {}
    }

    return SessionSnapshot(
      exists: true,
      roomCode: roomCode,
      hostPlayerId: data['hostPlayerId'] as String?,
      myPlayerId: myPlayerId,
      players: players,
      phase: data['phase'] as String? ?? 'waiting',
      gameState: gameState,
      playState: playState,
    );
  }
}
