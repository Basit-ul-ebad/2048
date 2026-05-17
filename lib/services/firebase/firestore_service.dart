import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get nicknameIndex => _firestore.collection('nickname_index');
  CollectionReference get globalLeaderboard => _firestore.collection('leaderboard').doc('global').collection('topPlayers');

  // User Profile
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String nickname,
  }) async {
    // 1. Create User Document
    await users.doc(uid).set({
      'nickname': nickname,
      'email': email,
      'highestScore': 0,
      'currentLevel': 1,
      'exp': 0,
      'coins': 0,
      'rank': 'Bronze',
      'wins': 0,
      'losses': 0,
      'friendsCount': 0,
      'aiWins': 0,
      'aiLosses': 0,
      'hardestAiBeaten': -1,
      'aiGamesPlayed': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Reserve Nickname
    await nicknameIndex.doc(nickname).set({
      'userId': uid,
    });
  }

  Future<bool> isNicknameAvailable(String nickname) async {
    final doc = await nicknameIndex.doc(nickname).get();
    return !doc.exists;
  }

  Future<DocumentSnapshot> getUserProfile(String uid) {
    return users.doc(uid).get();
  }

  /// Ensures the signed-in user's basic auth fields exist on their profile doc.
  Future<void> syncUserProfile(User user) async {
    await users.doc(user.uid).set(
          {
            if (user.email != null) 'email': user.email,
            if (user.displayName != null) 'displayName': user.displayName,
            if (user.photoURL != null) 'photoUrl': user.photoURL,
            'lastSyncedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
  }

  /// Finished single-player (or other) runs saved under `users/{uid}/runs`.
  Stream<QuerySnapshot<Map<String, dynamic>>> runsForUser(String uid) {
    return users
        .doc(uid)
        .collection('runs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Sync Score
  Future<void> updateHighestScore(String uid, int score) async {
    await users.doc(uid).update({
      'highestScore': FieldValue.increment(0), // Ensures we don't accidentally decrease it.
    });
    // For simplicity, we just set the highest score directly if it's higher.
    final doc = await users.doc(uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      int currentHighest = data['highestScore'] ?? 0;
      if (score > currentHighest) {
        await users.doc(uid).update({'highestScore': score});
        
        // Also update leaderboard (Simplified for client-side, normally use Cloud Functions)
        await globalLeaderboard.doc(uid).set({
          'userId': uid,
          'nickname': data['nickname'],
          'highestScore': score,
          'level': data['currentLevel'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  // XP & Achievements System
  Future<void> addMatchResults(String uid, int finalScore) async {
    try {
      final doc = await users.doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      int currentExp = data['exp'] ?? 0;
      int currentLevel = data['currentLevel'] ?? 1;
      int currentCoins = data['coins'] ?? 0;
      int totalGames = data['totalGames'] ?? 0;

      // Calculate new values
      int gainedExp = (finalScore / 100).floor();
      // Bonus exp just for playing
      gainedExp += 10;
      
      int newExp = currentExp + gainedExp;
      
      // Level up logic (1000 exp per level)
      int newLevel = (newExp / 1000).floor() + 1;
      
      // Calculate rank
      String newRank = 'Bronze';
      if (newLevel >= 50) newRank = 'Diamond';
      else if (newLevel >= 30) newRank = 'Gold';
      else if (newLevel >= 10) newRank = 'Silver';

      // Coins reward
      int gainedCoins = (finalScore / 200).floor();
      gainedCoins += 5; // Base reward
      
      await users.doc(uid).update({
        'exp': newExp,
        'currentLevel': newLevel,
        'rank': newRank,
        'coins': currentCoins + gainedCoins,
        'totalGames': totalGames + 1,
      });

    } catch (e) {
      print('Error updating match results: $e');
    }
  }
}
