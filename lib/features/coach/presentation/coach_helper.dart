import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../services/ai_coach/coach_session_limits.dart';
import '../../../services/ai_coach/gemini_coach_service.dart';
import '../../../services/ai_coach/local_coach_engine.dart';
import '../../../services/ai_coach/models/coach_advice.dart';
import '../../settings/providers/settings_provider.dart';

/// Shows AI Coach overlay and post-game review dialogs.
class CoachHelper {
  static final _localCoach = LocalCoachEngine();

  static Future<void> showCoachSheet({
    required BuildContext context,
    required List<int> board,
    required int score,
    required String mode,
    required CoachSessionLimits limits,
  }) async {
    if (!context.read<SettingsProvider>().aiCoachEnabled) {
      _snack(context, 'AI Coach is off in Settings.');
      return;
    }

    if (!limits.canRequestHint) {
      final wait = limits.cooldownSecondsRemaining;
      if (wait != null) {
        _snack(context, 'Wait ${wait}s before asking again.');
      } else {
        _snack(context, 'No coach hints left this game (max ${CoachSessionLimits.maxHintsPerGame}).');
      }
      return;
    }

    final advice = _localCoach.analyze(board);
    limits.recordHint();

    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Coach hint',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, _) {
        return _CoachHintOverlay(board: board, advice: advice);
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    );
  }

  /// Gemini summary for a finished run (win, loss, or manual end).
  static Future<void> showPostGameReview({
    required BuildContext context,
    required List<int> board,
    required int score,
    required String mode,
    required bool won,
    CoachSessionLimits? limits,
  }) async {
    if (!context.read<SettingsProvider>().aiCoachEnabled) {
      _snack(context, 'AI Coach is off in Settings.');
      return;
    }

    final coach = context.read<GeminiCoachService>();
    if (!coach.isConfigured) {
      _snack(
        context,
        'Gemini key missing. Add GEMINI_API_KEY to keys/dart_defines.json, then stop and run the app again (flutter run).',
      );
      return;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _ReviewDialog(
        future: coach.getPostGameReview(
          board: board,
          score: score,
          mode: mode,
          won: won,
        ),
        onSaved: limits != null
            ? (text) {
                limits.lastReviewText = text;
              }
            : null,
      ),
    );
  }

  static void showStoredReview(BuildContext context, CoachSessionLimits limits) {
    final text = limits.lastReviewText;
    if (text == null || text.isEmpty) {
      _snack(context, 'No review saved yet. Tap "Get AI Review" first.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('Your review'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.textDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shown after win, loss, or when the player taps End game.
  static Future<void> showGameEndDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int score,
    required List<int> board,
    required String mode,
    required bool won,
    required CoachSessionLimits limits,
    required VoidCallback onRestart,
    VoidCallback? onExit,
  }) async {
    final coachOn = context.read<SettingsProvider>().aiCoachEnabled;
    final hasStored = limits.lastReviewText != null && limits.lastReviewText!.isNotEmpty;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                ),
              if (subtitle.isNotEmpty) const SizedBox(height: 12),
              Text(
                'Score: $score',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            if (coachOn) ...[
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  showPostGameReview(
                    context: context,
                    board: board,
                    score: score,
                    mode: mode,
                    won: won,
                    limits: limits,
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get AI Review'),
              ),
              if (hasStored)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    showStoredReview(context, limits);
                  },
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('Read last review'),
                ),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onRestart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getTileColor(64),
              ),
              child: const Text('Play again', style: TextStyle(color: Colors.white)),
            ),
            if (onExit != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onExit();
                },
                child: const Text('Back to menu'),
              ),
          ],
        );
      },
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _CoachHintOverlay extends StatelessWidget {
  const _CoachHintOverlay({required this.board, required this.advice});

  final List<int> board;
  final CoachAdvice advice;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top + kToolbarHeight + 8;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            top: top,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _CoachCardShell(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber, size: 22),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Hint',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 20, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      if (advice.hasMove) ...[
                        const SizedBox(height: 8),
                        _DirectionBanner(move: advice.move!),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: Row(
                          children: [
                            Expanded(
                              child: _MiniBoard(
                                board: board,
                                highlights: advice.highlightIndices.toSet(),
                              ),
                            ),
                            if (advice.hasMove) ...[
                              const SizedBox(width: 8),
                              _EdgeArrow(move: advice.move!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        advice.headline,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SectionLabel('What happens'),
                      Text(
                        advice.what,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      _SectionLabel('Why'),
                      Text(
                        advice.why,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textDark.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CoachDismissButton(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _DirectionBanner extends StatelessWidget {
  const _DirectionBanner({required this.move});

  final String move;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.getTileColor(512),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Swipe ', style: TextStyle(color: Colors.white70, fontSize: 15)),
          Text(
            move.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Icon(_moveIcon(move), color: Colors.white, size: 24),
        ],
      ),
    );
  }

  static IconData _moveIcon(String move) => switch (move) {
        'up' => Icons.arrow_upward,
        'down' => Icons.arrow_downward,
        'left' => Icons.arrow_back,
        _ => Icons.arrow_forward,
      };
}

class _EdgeArrow extends StatelessWidget {
  const _EdgeArrow({required this.move});

  final String move;

  @override
  Widget build(BuildContext context) {
    final icon = _DirectionBanner._moveIcon(move);
    return Container(
      width: 36,
      alignment: Alignment.center,
      child: Icon(icon, size: 32, color: AppColors.getTileColor(128)),
    );
  }
}

class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.board, required this.highlights});

  final List<int> board;
  final Set<int> highlights;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.boardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 16,
          itemBuilder: (context, i) {
            final v = board[i];
            final hl = highlights.contains(i);
            return Container(
              decoration: BoxDecoration(
                color: AppColors.getTileColor(v == 0 ? 0 : v),
                borderRadius: BorderRadius.circular(4),
                border: hl
                    ? Border.all(color: Colors.amber.shade700, width: 2.5)
                    : null,
                boxShadow: hl
                    ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.45), blurRadius: 6)]
                    : null,
              ),
              alignment: Alignment.center,
              child: v == 0
                  ? null
                  : FittedBox(
                      child: Text(
                        '$v',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: v >= 128 ? 11 : 13,
                          color: v <= 4 ? AppColors.textDark : AppColors.textLight,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _CoachCardShell extends StatelessWidget {
  const _CoachCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: Colors.black26,
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: child,
      ),
    );
  }
}

class _CoachDismissButton extends StatelessWidget {
  const _CoachDismissButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.getTileColor(2048),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.future, this.onSaved});

  final Future<String> future;
  final void Function(String text)? onSaved;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.55;

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber),
          SizedBox(width: 8),
          Text('AI Review'),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: FutureBuilder<String>(
          future: widget.future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            final text = snapshot.data!;
            if (!_saved && widget.onSaved != null) {
              _saved = true;
              widget.onSaved!(text);
            }
            return SingleChildScrollView(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.textDark),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// App bar coach action with hint count badge.
class CoachAppBarButton extends StatelessWidget {
  const CoachAppBarButton({
    super.key,
    required this.limits,
    required this.board,
    required this.score,
    required this.mode,
    this.enabled = true,
  });

  final CoachSessionLimits limits;
  final List<int> board;
  final int score;
  final String mode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (!settings.aiCoachEnabled) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Hint (${limits.hintsRemaining} left)',
      onPressed: enabled
          ? () => CoachHelper.showCoachSheet(
                context: context,
                board: List<int>.from(board),
                score: score,
                mode: mode,
                limits: limits,
              )
          : null,
      icon: Badge(
        label: Text('${limits.hintsRemaining}'),
        child: const Icon(Icons.lightbulb_outline, color: AppColors.textDark),
      ),
    );
  }
}
