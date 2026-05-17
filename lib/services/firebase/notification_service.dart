import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/match_constants.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get notifications => _firestore.collection('notifications');

  Stream<QuerySnapshot> streamNotifications(String userId) {
    return notifications
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  Future<void> updateChallengeStatus(String notificationId, String status) async {
    await notifications.doc(notificationId).update({
      'status': status,
      'isRead': true,
    });
  }

  Future<void> sendNotification({
    required String receiverId,
    required String type,
    required String title,
    required String message,
    String? senderId,
    int? matchDuration,
    String? matchId,
  }) async {
    try {
      await notifications.add({
        'receiverId': receiverId,
        'senderId': senderId,
        'type': type,
        'title': title,
        'message': message,
        'matchDuration': matchDuration,
        'matchId': matchId,
        'status': 'unread',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  Future<void> sendChallengeNotification({
    required String targetUid,
    required String senderId,
    required String senderNickname,
    required int matchDurationSeconds,
    required String matchId,
  }) async {
    await sendNotification(
      receiverId: targetUid,
      senderId: senderId,
      type: 'challenge',
      title: 'Challenge from $senderNickname',
      message: '${MatchDurations.label(matchDurationSeconds)} match — tap Accept to play',
      matchDuration: matchDurationSeconds,
      matchId: matchId,
    );
  }

  Future<void> sendPartyChallengeNotification({
    required String targetUid,
    required String senderNickname,
    required String roomCode,
  }) async {
    await sendNotification(
      receiverId: targetUid,
      type: 'match_invite',
      title: 'Party invite',
      message: '$senderNickname invited you to party $roomCode',
    );
  }
}
