import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/firestore_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<Map<String, dynamic>> _topPlayers = [];
  bool _isLoading = false;

  LeaderboardProvider(this._firestoreService);

  List<Map<String, dynamic>> get topPlayers => _topPlayers;
  bool get isLoading => _isLoading;

  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestoreService.globalLeaderboard
          .orderBy('highestScore', descending: true)
          .limit(100)
          .get();

      _topPlayers = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Failed to fetch leaderboard: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
