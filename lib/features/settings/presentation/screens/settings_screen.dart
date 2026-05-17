import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/settings_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../ai/models/ai_difficulty.dart';
import '../../../../services/feedback/feedback_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: const Icon(Icons.volume_up, color: AppColors.textDark),
              activeThumbColor: AppColors.getTileColor(2048),
              value: settings.isSoundEnabled,
              onChanged: (_) async {
                final enabling = !settings.isSoundEnabled;
                await settings.toggleSound();
                if (enabling && context.mounted) {
                  context.read<FeedbackService>().previewSound();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Share Anonymous Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Helps improve AI mode balance'),
              secondary: const Icon(Icons.analytics_outlined, color: AppColors.textDark),
              activeThumbColor: AppColors.getTileColor(2048),
              value: settings.analyticsEnabled,
              onChanged: (_) => settings.toggleAnalytics(),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('AI Coach hints', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Instant hints on device. Post-game review uses Gemini if configured.'),
              secondary: const Icon(Icons.psychology, color: AppColors.textDark),
              activeThumbColor: AppColors.getTileColor(2048),
              value: settings.aiCoachEnabled,
              onChanged: (_) => settings.toggleAiCoach(),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: const Text('Default AI Difficulty', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(settings.preferredAiDifficulty.label),
              leading: const Icon(Icons.smart_toy, color: AppColors.textDark),
              trailing: DropdownButton<AiDifficulty>(
                value: settings.preferredAiDifficulty,
                underline: const SizedBox.shrink(),
                items: AiDifficulty.values
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    settings.setPreferredAiDifficulty(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Vibration (Haptics)', style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: const Icon(Icons.vibration, color: AppColors.textDark),
              activeThumbColor: AppColors.getTileColor(2048),
              value: settings.isVibrationEnabled,
              onChanged: (_) async {
                final enabling = !settings.isVibrationEnabled;
                await settings.toggleVibration();
                if (enabling && context.mounted) {
                  context.read<FeedbackService>().previewVibration();
                }
              },
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(context); // Go back to dashboard which will auto-redirect to login
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
