import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/nickname_utils.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/party_provider.dart';
import 'online_multiplayer_screen.dart'; // We'll reuse this screen but feed it the party match ID

class PartyLobbyScreen extends StatelessWidget {
  const PartyLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partyProvider = context.watch<PartyProvider>();
    final authUser = context.read<AuthProvider>().currentUser;

    if (partyProvider.roomData == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.textDark)),
      );
    }

    final isHost = partyProvider.roomData!['hostId'] == authUser?.uid;

    if (partyProvider.roomData!['roomStatus'] == 'in_game') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Transition to the actual game screen
        // We'll use the OnlineMultiplayerScreen and configure it to use this roomId
        // For simplicity, we just push it
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnlineMultiplayerScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Party Lobby', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            if (authUser != null) partyProvider.leaveRoom(authUser.uid);
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Room Code', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.getTileColor(2048).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.getTileColor(2048), width: 2),
                ),
                child: SelectableText(
                  partyProvider.roomData!['roomCode'],
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 48),

              // Players
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlayerAvatar(partyProvider.hostProfile, 'Host'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  _buildPlayerAvatar(partyProvider.guestProfile, 'Waiting...'),
                ],
              ),
              const SizedBox(height: 64),

              if (isHost)
                ElevatedButton(
                  onPressed: partyProvider.roomData!['guestId'] != null ? () {
                    partyProvider.startMatch();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getTileColor(2048),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Start Match', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else
                const Text('Waiting for host to start...', style: TextStyle(fontSize: 18, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(Map<String, dynamic>? profile, String fallbackText) {
    if (profile == null) {
      return Column(
        children: [
          CircleAvatar(radius: 40, backgroundColor: Colors.grey.shade300, child: const Icon(Icons.person_outline, size: 40, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(fallbackText, style: const TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.getTileColor(2),
          child: Text(
            NicknameUtils.initial(profile['nickname'] as String?),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          NicknameUtils.displayName(profile['nickname'] as String?),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
        ),
      ],
    );
  }
}
