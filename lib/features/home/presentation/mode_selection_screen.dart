import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/ranks.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../game/presentation/screens/game_screen.dart';
import '../../multiplayer/presentation/screens/local_multiplayer_screen.dart';
import '../../multiplayer/presentation/screens/matchmaking_screen.dart';
import '../../leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../friends/presentation/screens/friends_screen.dart';
import '../../shop/presentation/screens/shop_screen.dart';
import '../../settings/presentation/screens/settings_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../multiplayer/presentation/screens/party_lobby_screen.dart';
import '../../multiplayer/providers/party_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../../notifications/providers/notification_provider.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final user = profileProvider.userProfile;

    // Listen to notifications if not already doing so
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null && !notificationProvider.isListening) {
        context.read<NotificationProvider>().listenToNotifications(user.uid);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('2048 Multiplayer'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                },
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '${notificationProvider.unreadCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text("Failed to load profile."))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Card
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.getTileColor(2048),
                              child: Text(
                                user.nickname.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.nickname,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  Text(
                                    'Level ${Ranks.getLevelForExp(user.exp)} • ${user.rank}',
                                    style: TextStyle(fontSize: 14, color: Ranks.getRankColor(user.rank), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${user.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('HS: ${user.highestScore}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Game Modes
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            _buildModeCard(
                              context,
                              title: 'Single Player',
                              icon: Icons.person,
                              color: AppColors.getTileColor(32),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const GameScreen()),
                                );
                              },
                            ),
                            _buildModeCard(
                              context,
                              title: 'Party Room',
                              icon: Icons.meeting_room,
                              color: AppColors.getTileColor(2048),
                              onPressed: () {
                                if (user != null) {
                                  _showPartyDialog(context, user.uid);
                                }
                              },
                            ),
                            _buildModeCard(
                              context,
                              title: 'Local Match',
                              icon: Icons.people,
                              color: AppColors.getTileColor(64),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const LocalMultiplayerScreen()));
                              },
                            ),
                            _buildModeCard(
                              context,
                              title: 'Quick Match',
                              icon: Icons.public,
                              color: AppColors.getTileColor(128),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchmakingScreen()));
                              },
                            ),
                            _buildModeCard(
                              context,
                              title: 'Leaderboard',
                              icon: Icons.leaderboard,
                              color: AppColors.getTileColor(256),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
                              },
                            ),
                            _buildModeCard(
                              context,
                              title: 'Friends',
                              icon: Icons.group,
                              color: AppColors.getTileColor(512),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsScreen()));
                              },
                            ),
                            _buildModeCard(
                              context,
                              title: 'Shop',
                              icon: Icons.store,
                              color: AppColors.getTileColor(1024),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopScreen()));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildModeCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPartyDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final codeController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Party Room', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getTileColor(2048),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close dialog
                  await context.read<PartyProvider>().createRoom(uid);
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyLobbyScreen()));
                  }
                },
                child: const Text('Create Party', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  hintText: 'Enter Room Code',
                  filled: true,
                  fillColor: AppColors.getTileColor(2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getTileColor(1024),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  final code = codeController.text.trim().toUpperCase();
                  if (code.isNotEmpty) {
                    Navigator.pop(dialogContext); // Close dialog
                    final success = await context.read<PartyProvider>().joinRoom(uid, code);
                    if (success && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyLobbyScreen()));
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Room Code or Room Full')));
                    }
                  }
                },
                child: const Text('Join Party', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
