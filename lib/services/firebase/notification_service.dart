import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get notifications => _firestore.collection('notifications');

  Stream<QuerySnapshot> streamNotifications(String userId) {
    return notifications
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await notifications.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  Future<void> sendNotification({
    required String receiverId,
    required String type, // 'friend_online', 'match_invite', 'rank_promotion', 'friend_request'
    required String title,
    required String message,
  }) async {
    try {
      await notifications.add({
        'receiverId': receiverId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
  Future<void> sendChallengeNotification({
    required String targetUid,
    required String senderNickname,
    required String roomCode,
  }) async {
    await sendNotification(
      receiverId: targetUid,
      type: 'match_invite',
      title: 'Match Challenge!',
      message: '$senderNickname has challenged you to a Party Match! Room Code: $roomCode',
    );
  }
}
