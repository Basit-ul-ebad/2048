import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/game/models/board_model.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _highScoreKey = 'high_score';
  static const String _playersKey = 'players';
  static const String _matchRecordsKey = 'match_records';
  static const String _gameStateKey = 'game_state';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- High Score (Single Player) ---
  int getHighScore() {
    return _prefs?.getInt(_highScoreKey) ?? 0;
  }

  Future<void> saveHighScore(int score) async {
    await _prefs?.setInt(_highScoreKey, score);
  }

  // --- Game State (Single Player) ---
  BoardModel? getGameState() {
    final stateStr = _prefs?.getString(_gameStateKey);
    if (stateStr != null) {
      try {
        return BoardModel.fromJson(jsonDecode(stateStr));
      } catch (e) {
        // Ignore parsing errors
      }
    }
    return null;
  }

  Future<void> saveGameState(BoardModel board) async {
    await _prefs?.setString(_gameStateKey, jsonEncode(board.toJson()));
  }

  Future<void> clearGameState() async {
    await _prefs?.remove(_gameStateKey);
  }

  // --- Player Profiles ---
  List<String> getPlayers() {
    return _prefs?.getStringList(_playersKey) ?? [];
  }

  Future<void> addPlayer(String name) async {
    final players = getPlayers();
    if (!players.contains(name)) {
      players.add(name);
      await _prefs?.setStringList(_playersKey, players);
    }
  }

  // --- Match Records (Multiplayer) ---
  // Key format: "Player1_vs_Player2" (alphabetically sorted so order doesn't matter)
  String _getMatchRecordKey(String p1, String p2) {
    if (p1.compareTo(p2) < 0) {
      return '${_matchRecordsKey}_${p1}_vs_$p2';
    } else {
      return '${_matchRecordsKey}_${p2}_vs_$p1';
    }
  }

  // Returns wins for player1 and player2
  Map<String, int> getMatchRecord(String player1, String player2) {
    if (player1 == player2) return {player1: 0};
    
    final key = _getMatchRecordKey(player1, player2);
    final recordStr = _prefs?.getString(key);
    
    if (recordStr != null) {
      try {
        final Map<String, dynamic> record = jsonDecode(recordStr);
        return {
          player1: (record[player1] as num?)?.toInt() ?? 0,
          player2: (record[player2] as num?)?.toInt() ?? 0,
        };
      } catch (e) {
        // Fallback for parsing errors
      }
    }
    
    return {
      player1: 0,
      player2: 0,
    };
  }

  Future<void> recordMatchScore(String winner, String loser) async {
    if (winner.isEmpty || loser.isEmpty || winner == loser) return;
    
    final currentRecord = getMatchRecord(winner, loser);
    currentRecord[winner] = (currentRecord[winner] ?? 0) + 1;
    
    final key = _getMatchRecordKey(winner, loser);
    await _prefs?.setString(key, jsonEncode(currentRecord));
  }
}
