import 'package:firebase_database/firebase_database.dart';

class RealtimeService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Debouncing properties
  DateTime _lastSyncTime = DateTime.now();
  final int _debounceMs = 150; // Optimization Layer

  DatabaseReference get onlineMatches => _db.ref('online_matches');

  // Listen to match changes
  Stream<DatabaseEvent> streamMatchState(String matchId) {
    return onlineMatches.child(matchId).onValue;
  }

  // Optimized board sync (Throttling/Debouncing)
  Future<void> syncBoardState({
    required String matchId,
    required String playerId,
    required List<int> board,
    required int score,
    bool forceSync = false,
  }) async {
    final now = DateTime.now();
    if (!forceSync && now.difference(_lastSyncTime).inMilliseconds < _debounceMs) {
      return; // Skip sync to optimize performance
    }
    
    _lastSyncTime = now;
    
    try {
      final updates = {
        '${playerId}_board': board,
        '${playerId}_score': score,
        'lastUpdated': ServerValue.timestamp,
      };
      
      await onlineMatches.child(matchId).update(updates);
    } catch (e) {
      print('Failed to sync board: $e');
    }
  }

  // Update overall game state (win/lose/draw)
  Future<void> updateGameState(String matchId, String state, {String? winnerId}) async {
    final updates = <String, dynamic>{
      'gameState': state,
    };
    if (winnerId != null) {
      updates['winnerId'] = winnerId;
    }
    await onlineMatches.child(matchId).update(updates);
  }

  // Phase 2: Emote System
  Future<void> sendEmote({required String matchId, required String playerId, required String emote}) async {
    try {
      await onlineMatches.child(matchId).update({
        '${playerId}_emote': emote,
        '${playerId}_emoteTime': ServerValue.timestamp,
      });
    } catch (e) {
      print('Failed to send emote: $e');
    }
  }
}
