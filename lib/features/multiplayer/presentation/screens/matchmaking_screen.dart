import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/match_constants.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/multiplayer_provider.dart';
import 'online_multiplayer_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key, required this.matchDurationSeconds});

  final int matchDurationSeconds;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<MultiplayerProvider>().findMatch(
              user.uid,
              matchDurationSeconds: widget.matchDurationSeconds,
            );
      }
    });
  }

  @override
  void dispose() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<MultiplayerProvider>().cancelSearch(user.uid);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MultiplayerProvider>(
      builder: (context, provider, child) {
        if (provider.state == MatchState.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OnlineMultiplayerScreen(
                  matchDurationSeconds: widget.matchDurationSeconds,
                ),
              ),
            );
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () {
                final user = context.read<AuthProvider>().currentUser;
                if (user != null) {
                  provider.cancelSearch(user.uid);
                }
                Navigator.pop(context);
              },
            ),
            title: Text(
              MatchDurations.label(widget.matchDurationSeconds),
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.textDark),
                const SizedBox(height: 24),
                Text(
                  provider.state == MatchState.searching
                      ? 'Searching for opponent...'
                      : 'Match found! Preparing...',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
