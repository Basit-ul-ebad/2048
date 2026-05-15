import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class MatchmakingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  DatabaseReference get matchmakingQueue => _db.ref('matchmaking_queue');
  DatabaseReference get onlineMatches => _db.ref('online_matches');

  // Find or Create Match
  Future<String?> joinQueue(String userId) async {
    try {
      // 1. Look for existing player in queue
      final snapshot = await matchmakingQueue.limitToFirst(1).get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final queueId = data.keys.first;
        final opponentId = data[queueId]['userId'];

        if (opponentId == userId) {
          // Already in queue
          return null; 
        }

        // 2. Remove opponent from queue
        await matchmakingQueue.child(queueId).remove();

        // 3. Create a Match
        final matchId = _uuid.v4();
        await onlineMatches.child(matchId).set({
          'player1Id': opponentId,
          'player2Id': userId,
          'player1Score': 0,
          'player2Score': 0,
          'player1Board': List.filled(16, 0),
          'player2Board': List.filled(16, 0),
          'gameState': 'playing',
          'createdAt': ServerValue.timestamp,
        });

        return matchId;
      } else {
        // 4. Nobody in queue, join queue
        final queueId = _uuid.v4();
        await matchmakingQueue.child(queueId).set({
          'userId': userId,
          'joinedAt': ServerValue.timestamp,
        });

        // Listen for someone matching us
        // Real implementation would use Cloud Functions for atomic matching,
        // but for client-side we listen to our own queue document being deleted
        // and check if a match was created with our ID.
        return null;
      }
    } catch (e) {
      print('Failed to join queue: $e');
      return null;
    }
  }

  Future<void> leaveQueue(String userId) async {
    final snapshot = await matchmakingQueue.orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (var key in data.keys) {
        await matchmakingQueue.child(key).remove();
      }
    }
  }
}
