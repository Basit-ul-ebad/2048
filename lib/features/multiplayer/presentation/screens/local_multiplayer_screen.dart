import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../game/logic/game_engine.dart';
import '../../../game/presentation/widgets/game_board.dart';
import '../../../../services/feedback/feedback_service.dart';
import '../../../../services/analytics/analytics_service.dart';
import '../../../../services/analytics/analytics_constants.dart';

class LocalMultiplayerScreen extends StatefulWidget {
  const LocalMultiplayerScreen({super.key});

  @override
  State<LocalMultiplayerScreen> createState() => _LocalMultiplayerScreenState();
}

class _LocalMultiplayerScreenState extends State<LocalMultiplayerScreen> {
  final GameEngine _engine = GameEngine();

  List<int> _board1 = List.filled(16, 0);
  int _score1 = 0;
  bool _isGameOver1 = false;

  List<int> _board2 = List.filled(16, 0);
  int _score2 = 0;
  bool _isGameOver2 = false;
  DateTime? _matchStartedAt;
  bool _matchEndLogged = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame(logAnalytics: true);
    });
  }

  void _initializeGame({bool logAnalytics = false}) {
    _matchStartedAt = DateTime.now();
    _matchEndLogged = false;
    if (logAnalytics && mounted) {
      context.read<AnalyticsService>().logMultiplayerMatchStarted(
        mode: AnalyticsModes.localMultiplayer,
        opponentType: 'local_human',
      );
    }
    setState(() {
      _board1 = _engine.addRandomTile(_engine.addRandomTile(List.filled(16, 0)));
      _board2 = _engine.addRandomTile(_engine.addRandomTile(List.filled(16, 0)));
      _score1 = 0;
      _score2 = 0;
      _isGameOver1 = false;
      _isGameOver2 = false;
    });
  }

  void _handleSwipePlayer1(DragEndDetails details) {
    if (_isGameOver1) return;
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() > 250.0 || velocity.dy.abs() > 250.0) {
      int direction = -1;
      if (velocity.dx.abs() > velocity.dy.abs()) {
        direction = velocity.dx > 0 ? 1 : 0;
      } else {
        direction = velocity.dy > 0 ? 3 : 2;
      }
      _movePlayer1(direction);
    }
  }

  void _movePlayer1(int direction) {
    final result = _engine.move(_board1, direction);
    if (result['moved']) {
      final scoreGained = result['scoreGained'] as int;
      setState(() {
        _board1 = _engine.addRandomTile(result['board']);
        _score1 += scoreGained;
        _isGameOver1 = _engine.checkGameOver(_board1);
      });
      _playMoveFeedback(scoreGained);
      if (_engine.checkWin(_board1)) {
        context.read<FeedbackService>().onWin();
      }
      _checkOverallGameOver();
    }
  }

  void _handleSwipePlayer2(DragEndDetails details) {
    if (_isGameOver2) return;
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() > 250.0 || velocity.dy.abs() > 250.0) {
      int direction = -1;
      if (velocity.dx.abs() > velocity.dy.abs()) {
        direction = velocity.dx > 0 ? 1 : 0;
      } else {
        direction = velocity.dy > 0 ? 3 : 2;
      }
      _movePlayer2(direction);
    }
  }

  void _movePlayer2(int direction) {
    final result = _engine.move(_board2, direction);
    if (result['moved']) {
      final scoreGained = result['scoreGained'] as int;
      setState(() {
        _board2 = _engine.addRandomTile(result['board']);
        _score2 += scoreGained;
        _isGameOver2 = _engine.checkGameOver(_board2);
      });
      _playMoveFeedback(scoreGained);
      if (_engine.checkWin(_board2)) {
        context.read<FeedbackService>().onWin();
      }
      _checkOverallGameOver();
    }
  }

  void _playMoveFeedback(int scoreGained) {
    if (!mounted) return;
    context.read<FeedbackService>().onMove(scoreGained: scoreGained);
  }

  void _checkOverallGameOver() {
    if (_isGameOver1 && _isGameOver2) {
      String winner = "It's a Tie!";
      if (_score1 > _score2) winner = "Player 1 Wins!";
      if (_score2 > _score1) winner = "Player 2 Wins!";

      if (!_matchEndLogged) {
        _matchEndLogged = true;
        final duration = _matchStartedAt == null
            ? 0
            : DateTime.now().difference(_matchStartedAt!).inSeconds;
        var winOrLoss = 'draw';
        if (_score1 > _score2) winOrLoss = 'player1_win';
        if (_score2 > _score1) winOrLoss = 'player2_win';
        context.read<AnalyticsService>().logMultiplayerMatchFinished(
          mode: AnalyticsModes.localMultiplayer,
          winOrLoss: winOrLoss,
          matchDurationSeconds: duration,
          opponentType: 'local_human',
        );
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.background,
            title: const Text('Game Over'),
            content: Text(
              '$winner\n\nPlayer 1: $_score1\nPlayer 2: $_score2',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _initializeGame();
                },
                child: const Text('Play Again'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Exit'),
              )
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Local Multiplayer', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGame,
          )
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return Column(
                children: [
                  Expanded(child: _buildPlayerSection(2, _board2, _score2, _handleSwipePlayer2, true)),
                  const Divider(height: 2, thickness: 2, color: AppColors.textDark),
                  Expanded(child: _buildPlayerSection(1, _board1, _score1, _handleSwipePlayer1, false)),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(child: _buildPlayerSection(1, _board1, _score1, _handleSwipePlayer1, false)),
                  const VerticalDivider(width: 2, thickness: 2, color: AppColors.textDark),
                  Expanded(child: _buildPlayerSection(2, _board2, _score2, _handleSwipePlayer2, false)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlayerSection(
    int playerNum,
    List<int> board,
    int score,
    void Function(DragEndDetails) onSwipe,
    bool rotate,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPad = 12.0;
        const scoreHeight = 28.0;
        const gap = 6.0;

        final maxW = constraints.maxWidth - horizontalPad * 2;
        final maxH = constraints.maxHeight - scoreHeight - gap;
        final boardSide = math.min(maxW, maxH).clamp(0.0, double.infinity);

        final scoreStyle = TextStyle(
          fontSize: boardSide < 180 ? 14 : 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        );

        Widget content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Player $playerNum — Score: $score',
                style: scoreStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

        if (rotate) {
          return Transform.rotate(
            angle: math.pi,
            child: content,
          );
        }
        return content;
      },
    );
  }
}
