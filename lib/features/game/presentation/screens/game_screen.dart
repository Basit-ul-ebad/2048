import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/game_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../shop/providers/shop_provider.dart';
import '../../../coach/presentation/coach_helper.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../../../services/ai_coach/coach_session_limits.dart';
import '../../../../services/analytics/analytics_constants.dart';
import '../../models/single_player_mode.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.singlePlayerMode = SinglePlayerMode.classic});

  final SinglePlayerMode singlePlayerMode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final CoachSessionLimits _coachLimits = CoachSessionLimits();
  bool _endDialogShown = false;

  @override
  void initState() {
    super.initState();
    _coachLimits.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initializeGame(
            singlePlayerMode: widget.singlePlayerMode,
          );
    });
  }

  void _maybeShowEndDialog(GameProvider provider) {
    if (!provider.isFinished || _endDialogShown) return;
    _endDialogShown = true;

    final title = provider.isGameWon
        ? 'You Win!'
        : provider.endedManually
            ? 'Game ended'
            : 'Game Over';

    final subtitle = provider.endReason ??
        (provider.endedManually
            ? 'You chose to stop this run.'
            : provider.isGameWon
                ? 'You reached 2048!'
                : 'No more moves left.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoachHelper.showGameEndDialog(
        context: context,
        title: title,
        subtitle: subtitle,
        score: provider.score,
        board: List<int>.from(provider.board),
        mode: AnalyticsModes.singlePlayer,
        won: provider.isGameWon,
        limits: _coachLimits,
        onRestart: () {
          _endDialogShown = false;
          _coachLimits.reset();
          provider.restartGame(singlePlayerMode: widget.singlePlayerMode);
        },
        onExit: () => Navigator.of(context).pop(),
      );
    });
  }

  Future<void> _confirmEndGame(GameProvider provider) async {
    if (!provider.isPlaying) return;

    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('End this game?'),
        content: Text(
          'Your score (${provider.score}) will be saved. You can get an AI review after.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep playing')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End game'),
          ),
        ],
      ),
    );

    if (quit == true && mounted) {
      provider.endGameManually();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final skinId = context.watch<ShopProvider>().selectedSkin;
    final highestScore = profileProvider.userProfile?.highestScore ?? 0;

    if (gameProvider.isFinished) {
      _maybeShowEndDialog(gameProvider);
    } else {
      _endDialogShown = false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.singlePlayerMode.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          CoachAppBarButton(
            limits: _coachLimits,
            board: gameProvider.board,
            score: gameProvider.score,
            mode: AnalyticsModes.singlePlayer,
            enabled: gameProvider.isPlaying,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textDark),
            onSelected: (value) {
              switch (value) {
                case 'end':
                  _confirmEndGame(gameProvider);
                case 'review':
                  if (_coachLimits.lastReviewText != null) {
                    CoachHelper.showStoredReview(context, _coachLimits);
                  } else {
                    CoachHelper.showPostGameReview(
                      context: context,
                      board: List<int>.from(gameProvider.board),
                      score: gameProvider.score,
                      mode: AnalyticsModes.singlePlayer,
                      won: false,
                      limits: _coachLimits,
                    );
                  }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'end', child: Text('End game')),
              if (context.read<SettingsProvider>().aiCoachEnabled)
                PopupMenuItem(
                  value: 'review',
                  child: Text(
                    _coachLimits.lastReviewText != null
                        ? 'Read last AI review'
                        : 'AI review (current board)',
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.getBoardBackground(skinId),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'SCORE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              '${gameProvider.score}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (gameProvider.singlePlayerMode.hasTimer) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.getTileColor(128),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'TIME',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                '${gameProvider.secondsRemaining}s',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (widget.singlePlayerMode.isClassic) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.getBoardBackground(skinId),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'BEST',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              '$highestScore',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (gameProvider.isPlaying)
                        TextButton(
                          onPressed: () => _confirmEndGame(gameProvider),
                          child: const Text(
                            'End',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          _endDialogShown = false;
                          _coachLimits.reset();
                          gameProvider.restartGame(singlePlayerMode: widget.singlePlayerMode);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getTileColor(32),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Restart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        ),
      ),
    );
  }
}
