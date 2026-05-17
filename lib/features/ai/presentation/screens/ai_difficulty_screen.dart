import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../models/ai_difficulty.dart';
import '../../providers/ai_provider.dart';
import '../../services/ai_stats_service.dart';
import '../../../../services/firebase/firestore_service.dart';
import '../../../../services/feedback/feedback_service.dart';
import '../../../../services/analytics/analytics_service.dart';
import 'ai_game_screen.dart';

class AiDifficultyScreen extends StatelessWidget {
  const AiDifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferred = context.watch<SettingsProvider>().preferredAiDifficulty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Play vs AI',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.getTileColor(512),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Choose your opponent strength. The AI plays on its own board while you swipe yours.',
                    style: TextStyle(color: AppColors.textDark, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...AiDifficulty.values.map(
            (d) => _DifficultyTile(
              difficulty: d,
              isPreferred: d == preferred,
              onTap: () => _startMatch(context, d),
            ),
          ),
        ],
      ),
    );
  }

  void _startMatch(BuildContext context, AiDifficulty difficulty) {
    context.read<SettingsProvider>().setPreferredAiDifficulty(difficulty);
    context.read<AnalyticsService>().logAiDifficultySelected(
      difficulty: difficulty.label.toLowerCase(),
    );

    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    final analyticsEnabled = context.read<SettingsProvider>().analyticsEnabled;
    final stats = AiStatsService(context.read<FirestoreService>());
    final feedback = context.read<FeedbackService>();
    final analyticsService = context.read<AnalyticsService>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AiProvider(
            difficulty: difficulty,
            statsService: stats,
            userId: uid,
            analyticsEnabled: analyticsEnabled,
            feedback: feedback,
            analytics: analyticsService,
          )..startGame(),
          child: AiGameScreen(difficulty: difficulty),
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.isPreferred,
    required this.onTap,
  });

  final AiDifficulty difficulty;
  final bool isPreferred;
  final VoidCallback onTap;

  Color get _accent {
    switch (difficulty) {
      case AiDifficulty.easy:
        return AppColors.getTileColor(32);
      case AiDifficulty.medium:
        return AppColors.getTileColor(128);
      case AiDifficulty.hard:
        return AppColors.getTileColor(1024);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _accent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            difficulty.label,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isPreferred) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Saved',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        difficulty.description,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
