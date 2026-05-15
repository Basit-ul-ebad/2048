import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/friends_provider.dart';

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
                                    onPressed: () {
                                      // Challenge friend logic (future feature)
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge feature coming soon!')));
                                    },
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
}
