import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/settings_provider.dart';
import '../../../auth/providers/auth_provider.dart';

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
              activeColor: AppColors.getTileColor(2048),
              value: settings.isSoundEnabled,
              onChanged: (value) {
                settings.toggleSound();
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Vibration (Haptics)', style: TextStyle(fontWeight: FontWeight.bold)),
              secondary: const Icon(Icons.vibration, color: AppColors.textDark),
              activeColor: AppColors.getTileColor(2048),
              value: settings.isVibrationEnabled,
              onChanged: (value) {
                settings.toggleVibration();
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
