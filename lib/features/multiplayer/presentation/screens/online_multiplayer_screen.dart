import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../game/providers/game_provider.dart';
import '../../../../services/analytics/analytics_constants.dart';
import '../../providers/multiplayer_provider.dart';
import '../../../game/presentation/widgets/game_board.dart';

class OnlineMultiplayerScreen extends StatefulWidget {
  const OnlineMultiplayerScreen({super.key, this.matchDurationSeconds = 60});

  final int matchDurationSeconds;

  @override
  State<OnlineMultiplayerScreen> createState() => _OnlineMultiplayerScreenState();
}

class _OnlineMultiplayerScreenState extends State<OnlineMultiplayerScreen> {
  bool _endDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initializeGame(
            isMultiplayer: true,
            mode: AnalyticsModes.quickMatch,
          );
      context.read<GameProvider>().addListener(_onLocalBoardChanged);
    });
  }

  @override
  void dispose() {
    context.read<GameProvider>().removeListener(_onLocalBoardChanged);
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<MultiplayerProvider>().syncLocalBoard(
            user.uid,
            context.read<GameProvider>().board,
            context.read<GameProvider>().score,
            force: true,
          );
    }
    super.dispose();
  }

  void _onLocalBoardChanged() {
    if (!mounted) return;
    final gameProvider = context.read<GameProvider>();
    final multiProvider = context.read<MultiplayerProvider>();
    final user = context.read<AuthProvider>().currentUser;

    if (user != null && multiProvider.isPlaying) {
      multiProvider.syncLocalBoard(
        user.uid,
        gameProvider.board,
        gameProvider.score,
      );
    }
  }

  void _sendEmote(String emote) {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<MultiplayerProvider>().sendEmote(emote, user.uid);
    }
  }

  void _maybeShowEndDialog(MultiplayerProvider multi) {
    if (multi.state != MatchState.finished || _endDialogShown) return;
    _endDialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Match Over', textAlign: TextAlign.center),
          content: Text(
            multi.matchResultMessage ?? 'Game finished',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Back'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final multi = context.watch<MultiplayerProvider>();
    final game = context.watch<GameProvider>();

    _maybeShowEndDialog(multi);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Online • ${multi.secondsRemaining}s',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () async {
            final user = context.read<AuthProvider>().currentUser;
            if (user != null) {
              await context.read<MultiplayerProvider>().leaveMatch(user.uid);
            }
            if (context.mounted) Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(onPressed: () => _sendEmote('😭'), icon: const Text('😭', style: TextStyle(fontSize: 22))),
          IconButton(onPressed: () => _sendEmote('🔥'), icon: const Text('🔥', style: TextStyle(fontSize: 22))),
          IconButton(onPressed: () => _sendEmote('😎'), icon: const Text('😎', style: TextStyle(fontSize: 22))),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > constraints.maxHeight;

            if (!isWide) {
              return Column(
                children: [
                  _OpponentHeader(multi: multi),
                  _ScoreRow(label: 'You', score: game.score),
                  Expanded(child: _LocalBoard(onPanEnd: game.handlePanEnd)),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ScoreRow(label: 'You', score: game.score),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _LocalBoard(onPanEnd: game.handlePanEnd),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 2, thickness: 2, color: AppColors.boardBackground),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OpponentHeader(multi: multi),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _OpponentBoard(multi: multi),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OpponentHeader extends StatelessWidget {
  const _OpponentHeader({required this.multi});

  final MultiplayerProvider multi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.getTileColor(64),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Opponent: ${multi.opponentScore}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          if (multi.opponentEmote != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(multi.opponentEmote!, style: const TextStyle(fontSize: 40)),
            ),
        ],
      ),
    );
  }
}

class _OpponentBoard extends StatelessWidget {
  const _OpponentBoard({required this.multi});

  final MultiplayerProvider multi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: GameBoard(tiles: multi.opponentBoard),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '$label: $score',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
    );
  }
}

class _LocalBoard extends StatelessWidget {
  const _LocalBoard({required this.onPanEnd});

  final void Function(DragEndDetails) onPanEnd;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<GameProvider>().board;

    return GestureDetector(
      onPanEnd: onPanEnd,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: GameBoard(tiles: board),
          ),
        ),
      ),
    );
  }
}
