import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _subscription;
  bool _isListening = false;
  String? _currentUserId;

  NotificationProvider(this._notificationService);

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isListening => _isListening;

  Future<void> sendChallenge(String targetUid, String senderNickname, String roomCode) async {
    await _notificationService.sendChallengeNotification(
      targetUid: targetUid,
      senderNickname: senderNickname,
      roomCode: roomCode,
    );
  }

  void listenToNotifications(String userId) {
    if (_isListening && _currentUserId == userId) return;
    _isListening = true;
    _currentUserId = userId;

    _subscription?.cancel();
    _subscription = _notificationService.streamNotifications(userId).listen((snapshot) {
      _notifications = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();

      _unreadCount = _notifications.where((n) => n['isRead'] == false).length;
      notifyListeners();
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _currentUserId = null;
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
