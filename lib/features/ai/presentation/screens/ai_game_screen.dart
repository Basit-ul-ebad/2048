import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/colors.dart';
import '../../../game/presentation/widgets/game_board.dart';
import '../../models/ai_difficulty.dart';
import '../../providers/ai_provider.dart';
import '../../../coach/presentation/coach_helper.dart';
import '../../../../services/ai_coach/coach_session_limits.dart';
import '../../../../services/analytics/analytics_constants.dart';
import '../../../settings/providers/settings_provider.dart';

class AiGameScreen extends StatefulWidget {
  const AiGameScreen({super.key, required this.difficulty});

  final AiDifficulty difficulty;

  @override
  State<AiGameScreen> createState() => _AiGameScreenState();
}

class _AiGameScreenState extends State<AiGameScreen> {
  bool _dialogShown = false;
  final CoachSessionLimits _coachLimits = CoachSessionLimits();

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    if (ai.gameFinished && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResultDialog(context, ai);
      });
    } else if (!ai.gameFinished) {
      _dialogShown = false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'vs ${widget.difficulty.label} AI',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          _DifficultyBadge(difficulty: widget.difficulty),
          CoachAppBarButton(
            limits: _coachLimits,
            board: ai.playerBoard,
            score: ai.playerScore,
            mode: AnalyticsModes.ai,
            enabled: !ai.gameFinished,
          ),
          if (!ai.gameFinished)
            TextButton(
              onPressed: () => _confirmEndGame(context),
              child: const Text('End', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textDark),
            onSelected: (value) {
              if (value == 'review' && _coachLimits.lastReviewText != null) {
                CoachHelper.showStoredReview(context, _coachLimits);
              }
            },
            itemBuilder: (context) => [
              if (context.read<SettingsProvider>().aiCoachEnabled &&
                  _coachLimits.lastReviewText != null)
                const PopupMenuItem(
                  value: 'review',
                  child: Text('Read last AI review'),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _dialogShown = false;
              _coachLimits.reset();
              context.read<AiProvider>().startGame();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return Column(
                children: [
                  Expanded(
                    child: _buildSection(
                      context,
                      label: 'AI',
                      score: ai.aiScore,
                      board: ai.aiBoard,
                      onSwipe: null,
                      trailing: ai.isAiThinking
                          ? const _ThinkingIndicator()
                          : const Icon(Icons.smart_toy, color: AppColors.textDark, size: 20),
                    ),
                  ),
                  _ScoreDivider(playerScore: ai.playerScore, aiScore: ai.aiScore),
                  Expanded(
                    child: _buildSection(
                      context,
                      label: 'You',
                      score: ai.playerScore,
                      board: ai.playerBoard,
                      onSwipe: (d) => _onPlayerSwipe(context, d),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: _buildSection(
                    context,
                    label: 'AI',
                    score: ai.aiScore,
                    board: ai.aiBoard,
                    onSwipe: null,
                    trailing: ai.isAiThinking
                        ? const _ThinkingIndicator()
                        : const Icon(Icons.smart_toy, color: AppColors.textDark, size: 20),
                  ),
                ),
                _ScoreDivider(
                  playerScore: ai.playerScore,
                  aiScore: ai.aiScore,
                  vertical: true,
                ),
                Expanded(
                  child: _buildSection(
                    context,
                    label: 'You',
                    score: ai.playerScore,
                    board: ai.playerBoard,
                    onSwipe: (d) => _onPlayerSwipe(context, d),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onPlayerSwipe(BuildContext context, DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() < 250 && velocity.dy.abs() < 250) return;

    int direction;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      direction = velocity.dx > 0 ? 1 : 0;
    } else {
      direction = velocity.dy > 0 ? 3 : 2;
    }
    context.read<AiProvider>().playerMove(direction);
  }

  Future<void> _confirmEndGame(BuildContext context) async {
    final ai = context.read<AiProvider>();
    if (ai.gameFinished) return;

    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('End this match?'),
        content: const Text('Scores are compared now. You can request an AI review after.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep playing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End match')),
        ],
      ),
    );

    if (quit == true && context.mounted) {
      ai.endGameManually();
    }
  }

  void _showResultDialog(BuildContext context, AiProvider ai) {
    final title = switch (ai.matchResult) {
      AiMatchResult.playerWin => 'You Win!',
      AiMatchResult.aiWin => 'AI Wins',
      AiMatchResult.draw => 'Draw',
      AiMatchResult.ongoing => 'Game Over',
    };

    final subtitle = [
      if (ai.endMessage != null) ai.endMessage!,
      'You: ${ai.playerScore}  ·  AI: ${ai.aiScore}',
    ].join('\n');

    CoachHelper.showGameEndDialog(
      context: context,
      title: title,
      subtitle: subtitle,
      score: ai.playerScore,
      board: List<int>.from(ai.playerBoard),
      mode: AnalyticsModes.ai,
      won: ai.matchResult == AiMatchResult.playerWin,
      limits: _coachLimits,
      onRestart: () {
        _dialogShown = false;
        _coachLimits.reset();
        context.read<AiProvider>().startGame();
      },
      onExit: () => Navigator.pop(context),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required int score,
    required List<int> board,
    void Function(DragEndDetails)? onSwipe,
    Widget? trailing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPad = 12.0;
        const scoreHeight = 36.0;
        const gap = 6.0;

        final maxW = constraints.maxWidth - horizontalPad * 2;
        final maxH = constraints.maxHeight - scoreHeight - gap;
        final boardSide = math.min(maxW, maxH).clamp(0.0, double.infinity);

        Widget content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$label — $score',
                    style: TextStyle(
                      fontSize: boardSide < 180 ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing,
                  ],
                ],
              ),
              const SizedBox(height: gap),
              SizedBox(
                width: boardSide,
                height: boardSide,
                child: GestureDetector(
                  onPanEnd: onSwipe,
                  behavior: HitTestBehavior.opaque,
                  child: GameBoard(tiles: board),
                ),
              ),
            ],
          ),
        );

        return content;
      },
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final AiDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getTileColor(64),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty.label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.getTileColor(256),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'AI Thinking...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.getTileColor(512),
          ),
        ),
      ],
    );
  }
}

class _ScoreDivider extends StatelessWidget {
  const _ScoreDivider({
    required this.playerScore,
    required this.aiScore,
    this.vertical = false,
  });

  final int playerScore;
  final int aiScore;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final playerLeading = playerScore >= aiScore;
    final child = Container(
      width: vertical ? null : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.getTileColor(2),
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ScoreChip(label: 'You', score: playerScore, highlight: playerLeading),
                const SizedBox(height: 8),
                _ScoreChip(label: 'AI', score: aiScore, highlight: !playerLeading && aiScore > playerScore),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreChip(label: 'You', score: playerScore, highlight: playerLeading),
                const Text('vs', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                _ScoreChip(label: 'AI', score: aiScore, highlight: !playerLeading && aiScore > playerScore),
              ],
            ),
    );

    return child;
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.score,
    required this.highlight,
  });

  final String label;
  final int score;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.getTileColor(512) : Colors.grey.shade700,
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.getTileColor(2048) : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
