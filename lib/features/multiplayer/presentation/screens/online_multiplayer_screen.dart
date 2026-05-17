import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../game/providers/game_provider.dart';
import '../../providers/multiplayer_provider.dart';
import '../../../game/presentation/widgets/game_board.dart';

class OnlineMultiplayerScreen extends StatefulWidget {
  const OnlineMultiplayerScreen({super.key});

  @override
  State<OnlineMultiplayerScreen> createState() => _OnlineMultiplayerScreenState();
}

class _OnlineMultiplayerScreenState extends State<OnlineMultiplayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initializeGame(isMultiplayer: true);
      context.read<GameProvider>().addListener(_onLocalBoardChanged);
    });
  }

  void _onLocalBoardChanged() {
    if (!mounted) return;
    final gameProvider = context.read<GameProvider>();
    final multiProvider = context.read<MultiplayerProvider>();
    final user = context.read<AuthProvider>().currentUser;

    if (user != null) {
      multiProvider.syncLocalBoard(
        user.uid,
        gameProvider.board,
        gameProvider.score,
      );
    }
  }

  void _sendEmote(String emote) {
    final multiProvider = context.read<MultiplayerProvider>();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      multiProvider.sendEmote(emote, user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiProvider = context.watch<MultiplayerProvider>();
    final gameProvider = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Online Match', style: TextStyle(color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Row(
            children: [
              IconButton(onPressed: () => _sendEmote('😭'), icon: const Text('😭', style: TextStyle(fontSize: 24))),
              IconButton(onPressed: () => _sendEmote('🔥'), icon: const Text('🔥', style: TextStyle(fontSize: 24))),
              IconButton(onPressed: () => _sendEmote('😎'), icon: const Text('😎', style: TextStyle(fontSize: 24))),
            ],
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return Column(
              children: [
                _buildOpponentArea(multiProvider, showBoard: false),
                const SizedBox(height: 24),
                _buildLocalScore(gameProvider.score),
                Expanded(
                  child: GestureDetector(
                    onPanEnd: (details) {
                      context.read<GameProvider>().handlePanEnd(details);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: GameBoard(tiles: gameProvider.board),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onPanEnd: (details) {
                      context.read<GameProvider>().handlePanEnd(details);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLocalScore(gameProvider.score),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: GameBoard(tiles: gameProvider.board),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 4, thickness: 4, color: AppColors.textDark),
                Expanded(
                  child: _buildOpponentArea(multiProvider, showBoard: true),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildLocalScore(int score) {
    return Text(
      'You: $score',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
    );
  }

  Widget _buildOpponentArea(MultiplayerProvider provider, {required bool showBoard}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.getTileColor(64),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Opponent: ${provider.opponentScore}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        if (showBoard)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GameBoard(tiles: provider.opponentBoard),
                  if (provider.opponentEmote != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                            ),
                            child: Text(provider.opponentEmote!, style: const TextStyle(fontSize: 64)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          )
        else if (provider.opponentEmote != null)
          // Show emote below score in portrait mode
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Text(provider.opponentEmote!, style: const TextStyle(fontSize: 48)),
                );
              },
            ),
          ),
      ],
    );
  }
}
