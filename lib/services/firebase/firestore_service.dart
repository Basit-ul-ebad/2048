import 'package:cloud_firestore/cloud_firestore.dart';

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
}
