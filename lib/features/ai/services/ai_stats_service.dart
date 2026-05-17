import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firebase/firestore_service.dart';
import '../models/ai_difficulty.dart';

/// Persists AI mode statistics on the user document.
class AiStatsService {
  final FirestoreService _firestore;

  AiStatsService(this._firestore);

  Future<void> recordAiGameResult({
    required String uid,
    required bool? playerWon,
    required AiDifficulty difficulty,
    required bool analyticsEnabled,
  }) async {
    try {
      final ref = _firestore.users.doc(uid);
      final doc = await ref.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final currentHardest = (data['hardestAiBeaten'] as num?)?.toInt() ?? -1;

      final updates = <String, dynamic>{
        'aiGamesPlayed': FieldValue.increment(1),
      };

      if (playerWon == true) {
        updates['aiWins'] = FieldValue.increment(1);
        if (difficulty.levelIndex > currentHardest) {
          updates['hardestAiBeaten'] = difficulty.levelIndex;
        }
      } else if (playerWon == false) {
        updates['aiLosses'] = FieldValue.increment(1);
      }

      await ref.set(updates, SetOptions(merge: true));

      if (analyticsEnabled && playerWon != null) {
        await _incrementAnalyticsSummary(playerWon);
      } else if (analyticsEnabled) {
        await _incrementAnalyticsSummary(false, drawOnly: true);
      }
    } catch (e) {
      // Non-blocking for gameplay
    }
  }

  Future<void> _incrementAnalyticsSummary(bool playerWon, {bool drawOnly = false}) async {
    final dayKey = _periodKey(DateTime.now(), 'daily');
    final ref = FirebaseFirestore.instance.collection('analytics_summary').doc('daily');
    await ref.set({
      dayKey: {
        'aiGames': FieldValue.increment(1),
        if (!drawOnly) 'aiPlayerWins': FieldValue.increment(playerWon ? 1 : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  String _periodKey(DateTime now, String period) {
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    if (period == 'weekly') {
      final week = ((now.day - 1) ~/ 7) + 1;
      return '$y-W$week';
    }
    if (period == 'monthly') return '$y-$m';
    return '$y-$m-$d';
  }
}
