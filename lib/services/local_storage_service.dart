// This app is Flutter Web only. dart:html is used for browser localStorage
// to persist local game state across page reloads. If support for other
// platforms is needed in the future, replace with the shared_preferences
// package.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../models/game_state.dart';

/// Persists and restores a local (offline) [GameState] in browser localStorage.
class LocalStorageService {
  static const _gameStateKey = 'es_makker_local_game';

  /// Saves [gameState] to localStorage, replacing any previously saved state.
  void saveGameState(GameState gameState) {
    html.window.localStorage[_gameStateKey] = gameState.toJsonString();
  }

  /// Returns the saved [GameState], or `null` if nothing is stored or the
  /// stored data cannot be parsed.
  GameState? loadGameState() {
    final stored = html.window.localStorage[_gameStateKey];
    if (stored == null || stored.isEmpty) return null;
    try {
      return GameState.fromJsonString(stored);
    } catch (_) {
      return null;
    }
  }

  /// Removes any saved game state from localStorage.
  void clearGameState() {
    html.window.localStorage.remove(_gameStateKey);
  }
}
