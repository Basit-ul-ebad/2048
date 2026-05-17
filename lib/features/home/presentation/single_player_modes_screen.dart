import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../game/models/single_player_mode.dart';
import '../../game/presentation/screens/game_screen.dart';

class SinglePlayerModesScreen extends StatelessWidget {
  const SinglePlayerModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Single Player',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Classic counts toward the leaderboard. Timed modes are for practice and high scores only.',
            style: TextStyle(color: AppColors.textDark, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...SinglePlayerMode.values.map((mode) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: CircleAvatar(
                  backgroundColor: AppColors.getTileColor(
                    mode.isClassic ? 2048 : 512,
                  ),
                  child: Icon(
                    mode.isClassic ? Icons.all_inclusive : Icons.timer,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  mode.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                subtitle: Text(mode.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(singlePlayerMode: mode),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
