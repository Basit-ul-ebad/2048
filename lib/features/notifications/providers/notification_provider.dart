import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/notification_service.dart';
import '../../../services/firebase/matchmaking_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._notificationService, this._matchmakingService);

  final NotificationService _notificationService;
  final MatchmakingService _matchmakingService;

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _subscription;
  bool _isListening = false;
  String? _currentUserId;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isListening => _isListening;

  Future<String> sendFriendChallenge({
    required String targetUid,
    required String senderId,
    required String senderNickname,
    required int matchDurationSeconds,
  }) async {
    final matchId = await _matchmakingService.createChallengeMatch(
      player1Id: senderId,
      player2Id: targetUid,
      matchDurationSeconds: matchDurationSeconds,
    );

    await _notificationService.sendChallengeNotification(
      targetUid: targetUid,
      senderId: senderId,
      senderNickname: senderNickname,
      matchDurationSeconds: matchDurationSeconds,
      matchId: matchId,
    );
    return matchId;
  }

  Future<void> sendPartyChallenge(String targetUid, String senderNickname, String roomCode) async {
    await _notificationService.sendPartyChallengeNotification(
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

      _unreadCount = _notifications.where((n) => n['isRead'] != true).length;
      notifyListeners();
    });
  }

  Future<void> acceptChallenge({
    required String notificationId,
    required String userId,
    required String matchId,
  }) async {
    await _notificationService.updateChallengeStatus(notificationId, 'accepted');
    await _matchmakingService.leaveQueue(userId);
  }

  Future<void> declineChallenge(String notificationId) async {
    await _notificationService.updateChallengeStatus(notificationId, 'declined');
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
