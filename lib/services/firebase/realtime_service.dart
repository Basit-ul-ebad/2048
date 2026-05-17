import 'package:firebase_database/firebase_database.dart';

class RealtimeService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DateTime _lastSyncTime = DateTime.now();
  final int _debounceMs = 120;

  DatabaseReference get onlineMatches => _db.ref('online_matches');

  Stream<DatabaseEvent> streamMatchState(String matchId) {
    return onlineMatches.child(matchId).onValue;
  }

  Future<void> syncBoardState({
    required String matchId,
    required String playerId,
    required List<int> board,
    required int score,
    bool forceSync = false,
  }) async {
    final now = DateTime.now();
    if (!forceSync && now.difference(_lastSyncTime).inMilliseconds < _debounceMs) {
      return;
    }

    _lastSyncTime = now;

    try {
      await onlineMatches.child(matchId).update({
        '${playerId}_board': board,
        '${playerId}_score': score,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      print('Failed to sync board: $e');
    }
  }

  Future<void> updateGameState(
    String matchId,
    String state, {
    String? winnerId,
  }) async {
    final updates = <String, dynamic>{'gameState': state};
    if (winnerId != null) {
      updates['winnerId'] = winnerId;
    }
    await onlineMatches.child(matchId).update(updates);
  }

  Future<void> sendEmote({
    required String matchId,
    required String playerId,
    required String emote,
  }) async {
    try {
      await onlineMatches.child(matchId).update({
        '${playerId}_emote': emote,
        '${playerId}_emoteTime': ServerValue.timestamp,
      });
    } catch (e) {
      print('Failed to send emote: $e');
    }
  }

  /// Reads score/board supporting snake_case and legacy camelCase keys.
  static int? readScore(Map<dynamic, dynamic> data, String prefix) {
    final v = data['${prefix}_score'] ?? data['${prefix}Score'];
    if (v == null) return null;
    return (v as num).toInt();
  }

  static List<int> readBoard(Map<dynamic, dynamic> data, String prefix) {
    final v = data['${prefix}_board'] ?? data['${prefix}Board'];
    if (v == null) return List.filled(16, 0);
    return List<int>.from(v as List);
  }
}
