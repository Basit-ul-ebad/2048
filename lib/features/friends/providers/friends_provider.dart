import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/firestore_service.dart';

class FriendsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = false;

  FriendsProvider(this._firestoreService);

  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get requests => _requests;
  bool get isLoading => _isLoading;

  Future<void> fetchFriendsAndRequests(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Friends
      final friendsSnapshot = await _firestoreService.users.doc(uid).collection('friends').get();
      List<Map<String, dynamic>> tempFriends = [];
      for (var doc in friendsSnapshot.docs) {
        final friendDoc = await _firestoreService.getUserProfile(doc.id);
        if (friendDoc.exists) {
          tempFriends.add({'uid': friendDoc.id, ...friendDoc.data() as Map<String, dynamic>});
        }
      }
      _friends = tempFriends;

      // 2. Fetch Requests
      final requestsSnapshot = await _firestoreService.users.firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      
      List<Map<String, dynamic>> tempRequests = [];
      for (var doc in requestsSnapshot.docs) {
        final senderDoc = await _firestoreService.getUserProfile(doc.data()['senderId']);
        if (senderDoc.exists) {
          tempRequests.add({
            'requestId': doc.id,
            'uid': senderDoc.id,
            ...senderDoc.data() as Map<String, dynamic>
          });
        }
      }
      _requests = tempRequests;

    } catch (e) {
      print('Failed to fetch friends: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendFriendRequest(String currentUid, String targetNickname) async {
    try {
      // Find user by nickname
      final nicknameDoc = await _firestoreService.nicknameIndex.doc(targetNickname).get();
      if (!nicknameDoc.exists) return false;

      final targetUid = (nicknameDoc.data() as Map<String, dynamic>)['userId'];
      if (targetUid == currentUid) return false;

      // Send request
      await _firestoreService.users.firestore.collection('friend_requests').add({
        'senderId': currentUid,
        'receiverId': targetUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Failed to send request: $e');
      return false;
    }
  }

  Future<void> acceptRequest(String requestId, String currentUid, String friendUid) async {
    try {
      final db = _firestoreService.users.firestore;
      
      // 1. Update request status
      await db.collection('friend_requests').doc(requestId).update({'status': 'accepted'});

      // 2. Add to both friends lists
      await db.collection('users').doc(currentUid).collection('friends').doc(friendUid).set({'addedAt': FieldValue.serverTimestamp()});
      await db.collection('users').doc(friendUid).collection('friends').doc(currentUid).set({'addedAt': FieldValue.serverTimestamp()});

      // 3. Update count
      await db.collection('users').doc(currentUid).update({'friendsCount': FieldValue.increment(1)});
      await db.collection('users').doc(friendUid).update({'friendsCount': FieldValue.increment(1)});

      await fetchFriendsAndRequests(currentUid);
    } catch (e) {
      print('Failed to accept request: $e');
    }
  }

  Future<void> rejectRequest(String requestId, String currentUid) async {
    try {
      await _firestoreService.users.firestore.collection('friend_requests').doc(requestId).update({'status': 'rejected'});
      await fetchFriendsAndRequests(currentUid);
    } catch (e) {
      print('Failed to reject request: $e');
    }
  }
}
