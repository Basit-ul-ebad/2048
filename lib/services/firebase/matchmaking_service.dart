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
        final opponentUserId = data.keys.first;

        if (opponentUserId == userId) {
          // Already in queue
          return null; 
        }

        // 2. Remove opponent from queue
        await matchmakingQueue.child(opponentUserId).remove();

        // 3. Create a Match
        final matchId = _uuid.v4();
        await onlineMatches.child(matchId).set({
          'player1Id': opponentUserId,
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
        // 4. Nobody in queue, join queue using userId as the key
        await matchmakingQueue.child(userId).set({
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
    try {
      await matchmakingQueue.child(userId).remove();
    } catch (e) {
      print('Failed to leave queue: $e');
    }
  }
}
