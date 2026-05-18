import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/match_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../multiplayer/providers/multiplayer_provider.dart';
import '../../../multiplayer/presentation/screens/online_multiplayer_screen.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData _getIconForType(String type) {
    return switch (type) {
      'challenge' => Icons.sports_esports,
      'friend_online' => Icons.person_outline,
      'match_invite' => Icons.videogame_asset,
      'rank_promotion' => Icons.star,
      'friend_request' => Icons.person_add,
      _ => Icons.notifications,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: provider.notifications.isEmpty
          ? const Center(child: Text('No notifications.', style: TextStyle(color: Colors.grey, fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                final isRead = notif['isRead'] == true;
                final type = notif['type'] as String? ?? '';
                final status = notif['status'] as String? ?? 'unread';
                final isPendingChallenge = type == 'challenge' && status == 'unread';

                return Card(
                  elevation: isRead ? 1 : 4,
                  color: isRead ? Colors.white : AppColors.getTileColor(2048).withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: isRead ? Colors.grey.shade300 : AppColors.getTileColor(2048),
                              child: Icon(
                                _getIconForType(type),
                                color: isRead ? Colors.grey.shade600 : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(notif['message'] ?? ''),
                                  if (notif['matchDuration'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Match: ${MatchDurations.label((notif['matchDuration'] as num).toInt())}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isPendingChallenge) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _decline(context, provider, notif['id'] as String),
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  label: const Text('Decline', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _accept(context, provider, notif),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                  ),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  label: const Text('Accept', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ] else if (type == 'challenge' && status != 'unread')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              status == 'accepted' ? 'Accepted' : 'Declined',
                              style: TextStyle(
                                color: status == 'accepted' ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _accept(
    BuildContext context,
    NotificationProvider provider,
    Map<String, dynamic> notif,
  ) async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    final matchId = notif['matchId'] as String?;
    final duration = (notif['matchDuration'] as num?)?.toInt() ?? MatchDurations.short;
    final id = notif['id'] as String?;

    if (uid == null || matchId == null || id == null) return;

    await provider.acceptChallenge(
      notificationId: id,
      userId: uid,
      matchId: matchId,
    );

    if (!context.mounted) return;

    await context.read<MultiplayerProvider>().joinExistingMatch(matchId, uid);

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineMultiplayerScreen(matchDurationSeconds: duration),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _decline(
    BuildContext context,
    NotificationProvider provider,
    String notificationId,
  ) async {
    await provider.declineChallenge(notificationId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge declined')),
      );
    }
  }
}
