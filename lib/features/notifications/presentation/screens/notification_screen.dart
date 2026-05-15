import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'friend_online':
        return Icons.person_outline;
      case 'match_invite':
        return Icons.videogame_asset;
      case 'rank_promotion':
        return Icons.star;
      case 'friend_request':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
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
                final isRead = notif['isRead'] as bool;

                return Card(
                  elevation: isRead ? 1 : 4,
                  color: isRead ? Colors.white : AppColors.getTileColor(2048).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey.shade300 : AppColors.getTileColor(2048),
                      child: Icon(_getIconForType(notif['type']), color: isRead ? Colors.grey.shade600 : Colors.white),
                    ),
                    title: Text(
                      notif['title'],
                      style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Text(notif['message']),
                    onTap: () {
                      if (!isRead) {
                        provider.markAsRead(notif['id']);
                      }
                      // Could navigate based on type (e.g. to party lobby for invite)
                    },
                  ),
                );
              },
            ),
    );
  }
}
