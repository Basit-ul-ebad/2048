import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class MatchmakingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  DatabaseReference get matchmakingQueue => _db.ref('matchmaking_queue');
  DatabaseReference get onlineMatches => _db.ref('online_matches');

  /// Removes user from queue. Call on screen dispose / cancel.
  Future<void> cancelMatchmaking(String userId) => leaveQueue(userId);

  Future<void> leaveQueue(String userId) async {
    try {
      await matchmakingQueue.child(userId).remove();
    } catch (e) {
      print('Failed to leave queue: $e');
    }
  }

  /// Finds an opponent or enqueues. Returns matchId when matched immediately.
  Future<String?> joinQueue(
    String userId, {
    int matchDurationSeconds = 60,
  }) async {
    try {
      await leaveQueue(userId);

      final snapshot = await matchmakingQueue.get();
      String? opponentUserId;

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        for (final key in data.keys) {
          final candidate = key.toString();
          if (candidate != userId) {
            opponentUserId = candidate;
            break;
          }
        }
      }

      if (opponentUserId != null && opponentUserId != userId) {
        return _createMatch(
          player1Id: opponentUserId,
          player2Id: userId,
          matchDurationSeconds: matchDurationSeconds,
          removeFromQueue: opponentUserId,
        );
      }

      await matchmakingQueue.child(userId).set({
        'userId': userId,
        'joinedAt': ServerValue.timestamp,
        'matchDuration': matchDurationSeconds,
      });
      return null;
    } catch (e) {
      print('Failed to join queue: $e');
      return null;
    }
  }

  Future<String?> _createMatch({
    required String player1Id,
    required String player2Id,
    required int matchDurationSeconds,
    required String removeFromQueue,
  }) async {
    if (player1Id == player2Id) {
      print('Rejected self-match for $player1Id');
      return null;
    }

    await matchmakingQueue.child(removeFromQueue).remove();
    await leaveQueue(player2Id);

    final matchId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTime = now + (matchDurationSeconds * 1000);

    final emptyBoard = List<int>.filled(16, 0);

    await onlineMatches.child(matchId).set({
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1_score': 0,
      'player2_score': 0,
      'player1_board': emptyBoard,
      'player2_board': emptyBoard,
      'gameState': 'playing',
      'duration': matchDurationSeconds,
      'startTime': now,
      'endTime': endTime,
      'createdAt': ServerValue.timestamp,
    });

    return matchId;
  }

  /// Creates a direct friend challenge match (no queue).
  Future<String> createChallengeMatch({
    required String player1Id,
    required String player2Id,
    required int matchDurationSeconds,
  }) async {
    if (player1Id == player2Id) {
      throw ArgumentError('Cannot create match with same player');
    }

    final matchId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final endTime = now + (matchDurationSeconds * 1000);
    final emptyBoard = List<int>.filled(16, 0);

    await onlineMatches.child(matchId).set({
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1_score': 0,
      'player2_score': 0,
      'player1_board': emptyBoard,
      'player2_board': emptyBoard,
      'gameState': 'playing',
      'duration': matchDurationSeconds,
      'startTime': now,
      'endTime': endTime,
      'createdAt': ServerValue.timestamp,
    });

    return matchId;
  }
}
