import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _subscription;

  NotificationProvider(this._notificationService);

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void listenToNotifications(String userId) {
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

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
