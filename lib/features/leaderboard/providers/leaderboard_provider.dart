import 'package:flutter/material.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../../services/analytics/analytics_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider(this._firestoreService, this._analytics);

  final FirestoreService _firestoreService;
  final AnalyticsService _analytics;

  List<Map<String, dynamic>> _topPlayers = [];
  bool _isLoading = false;
  int? _lastKnownRank;

  List<Map<String, dynamic>> get topPlayers => _topPlayers;
  bool get isLoading => _isLoading;

  Future<void> fetchLeaderboard({String? currentUserId}) async {
    _isLoading = true;
    notifyListeners();

    await _analytics.logLeaderboardOpened();

    try {
      final snapshot = await _firestoreService.globalLeaderboard
          .orderBy('highestScore', descending: true)
          .limit(100)
          .get();

      _topPlayers = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      if (currentUserId != null) {
        final index = _topPlayers.indexWhere((p) => p['userId'] == currentUserId);
        if (index >= 0) {
          final newRank = index + 1;
          final highestScore = _topPlayers[index]['highestScore'] as int? ?? 0;
          if (_lastKnownRank != null && _lastKnownRank != newRank) {
            await _analytics.logLeaderboardRankChanged(
              newRank: newRank,
              highestScore: highestScore,
            );
          }
          _lastKnownRank = newRank;
        }
      }
    } catch (e) {
      // ignore
    }

    _isLoading = false;
    notifyListeners();
  }
}
