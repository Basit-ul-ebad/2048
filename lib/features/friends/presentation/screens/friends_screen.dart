import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/match_constants.dart';
import '../../../multiplayer/providers/multiplayer_provider.dart';
import '../../../multiplayer/presentation/screens/online_multiplayer_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../../multiplayer/providers/party_provider.dart';
import '../../../multiplayer/presentation/screens/party_lobby_screen.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../../../profile/providers/profile_provider.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<FriendsProvider>().fetchFriendsAndRequests(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sendRequest() async {
    final nickname = _searchController.text.trim();
    if (nickname.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final success = await context.read<FriendsProvider>().sendFriendRequest(user.uid, nickname);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Request sent!' : 'User not found or already requested.')),
        );
        _searchController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.watch<FriendsProvider>();
    final user = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Friends', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: friendsProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textDark))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add Friend Section
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Enter Friend\'s Nickname',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _sendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getTileColor(2048),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.person_add, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Friend Requests Section
                  if (friendsProvider.requests.isNotEmpty) ...[
                    const Text('Friend Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    ...friendsProvider.requests.map((request) => Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(request['nickname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    if (user != null) {
                                      friendsProvider.acceptRequest(request['requestId'], user.uid, request['uid']);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    if (user != null) {
                                      friendsProvider.rejectRequest(request['requestId'], user.uid);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Friends List Section
                  const Text('My Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: friendsProvider.friends.isEmpty
                        ? const Center(child: Text('You have no friends yet.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: friendsProvider.friends.length,
                            itemBuilder: (context, index) {
                              final friend = friendsProvider.friends[index];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(friend['nickname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Level ${friend['currentLevel'] ?? 1} • Rank: ${friend['rank'] ?? 'Bronze'}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.videogame_asset, color: AppColors.textDark),
                                    onPressed: () => _showChallengeOptions(
                                      context,
                                      friendUid: friend['uid'] as String,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showChallengeOptions(BuildContext context, {required String friendUid}) {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    final profile = context.read<ProfileProvider>().userProfile;
    if (uid == null || profile == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Challenge friend',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...MatchDurations.all.map((seconds) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getTileColor(128),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sending challenge...')),
                    );
                    final matchId = await context.read<NotificationProvider>().sendFriendChallenge(
                          targetUid: friendUid,
                          senderId: uid,
                          senderNickname: profile.nickname,
                          matchDurationSeconds: seconds,
                        );
                    if (!context.mounted) return;
                    await context.read<MultiplayerProvider>().joinExistingMatch(matchId, uid);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnlineMultiplayerScreen(matchDurationSeconds: seconds),
                      ),
                    );
                  },
                  child: Text(
                    'Timed ${MatchDurations.label(seconds)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final partyProvider = context.read<PartyProvider>();
                await partyProvider.createRoom(uid);
                final roomCode = partyProvider.roomData?['roomCode'];
                if (roomCode != null && context.mounted) {
                  await context.read<NotificationProvider>().sendPartyChallenge(
                        friendUid,
                        profile.nickname,
                        roomCode,
                      );
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PartyLobbyScreen()),
                    );
                  }
                }
              },
              child: const Text('Party room instead'),
            ),
          ],
        ),
      ),
    );
  }
}
