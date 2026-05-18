import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../../services/analytics/analytics_service.dart';

class FriendsProvider extends ChangeNotifier {
  FriendsProvider(this._firestoreService, this._analytics);

  final FirestoreService _firestoreService;
  final AnalyticsService _analytics;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get requests => _requests;
  bool get isLoading => _isLoading;

  Future<void> fetchFriendsAndRequests(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final friendsSnapshot = await _firestoreService.users.doc(uid).collection('friends').get();
      final tempFriends = <Map<String, dynamic>>[];
      for (final doc in friendsSnapshot.docs) {
        final friendDoc = await _firestoreService.getUserProfile(doc.id);
        if (friendDoc.exists) {
          tempFriends.add({'uid': friendDoc.id, ...friendDoc.data() as Map<String, dynamic>});
        }
      }
      _friends = tempFriends;

      final requestsSnapshot = await _firestoreService.users.firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final tempRequests = <Map<String, dynamic>>[];
      for (final doc in requestsSnapshot.docs) {
        final senderDoc = await _firestoreService.getUserProfile(doc.data()['senderId']);
        if (senderDoc.exists) {
          tempRequests.add({
            'requestId': doc.id,
            'uid': senderDoc.id,
            ...senderDoc.data() as Map<String, dynamic>,
          });
        }
      }
      _requests = tempRequests;
    } catch (e) {
      // ignore
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendFriendRequest(String currentUid, String targetNickname) async {
    try {
      final nicknameDoc = await _firestoreService.nicknameIndex.doc(targetNickname).get();
      if (!nicknameDoc.exists) return false;

      final targetUid = (nicknameDoc.data() as Map<String, dynamic>)['userId'];
      if (targetUid == currentUid) return false;

      await _firestoreService.users.firestore.collection('friend_requests').add({
        'senderId': currentUid,
        'receiverId': targetUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _analytics.logFriendRequestSent();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> acceptRequest(String requestId, String currentUid, String friendUid) async {
    try {
      final db = _firestoreService.users.firestore;

      await db.collection('friend_requests').doc(requestId).update({'status': 'accepted'});

      await db.collection('users').doc(currentUid).collection('friends').doc(friendUid).set({
        'addedAt': FieldValue.serverTimestamp(),
      });
      await db.collection('users').doc(friendUid).collection('friends').doc(currentUid).set({
        'addedAt': FieldValue.serverTimestamp(),
      });

      await db.collection('users').doc(currentUid).update({'friendsCount': FieldValue.increment(1)});
      await db.collection('users').doc(friendUid).update({'friendsCount': FieldValue.increment(1)});

      await _analytics.logFriendRequestAccepted();
      await _analytics.logFriendAdded();

      await fetchFriendsAndRequests(currentUid);
    } catch (e) {
      // ignore
    }
  }

  Future<void> rejectRequest(String requestId, String currentUid) async {
    try {
      await _firestoreService.users.firestore
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'rejected'});
      await fetchFriendsAndRequests(currentUid);
    } catch (e) {
      // ignore
    }
  }
}
