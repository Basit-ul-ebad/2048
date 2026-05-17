import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/leaderboard_provider.dart';
import '../../../auth/providers/auth_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      context.read<LeaderboardProvider>().fetchLeaderboard(currentUserId: uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Global Leaderboard', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Consumer<LeaderboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.textDark));
          }

          if (provider.topPlayers.isEmpty) {
            return const Center(child: Text('No players found yet.', style: TextStyle(fontSize: 18, color: AppColors.textDark)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.topPlayers.length,
            itemBuilder: (context, index) {
              final player = provider.topPlayers[index];
              final isTop3 = index < 3;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: isTop3 ? 4 : 1,
                color: isTop3 ? AppColors.getTileColor(2048).withOpacity(0.1) : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isTop3 ? AppColors.getTileColor(2048) : AppColors.getTileColor(2),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isTop3 ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                  title: Text(
                    player['nickname'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    'Level ${player['level'] ?? 1}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Highest Score', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${player['highestScore']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.getTileColor(64),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
