import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../logic/game_controller.dart';
import '../../models/board_model.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  BoardModel _board = BoardModel.empty();

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      onStateUpdate: (validBoard) {
        setState(() {
          _board = validBoard;
        });
      },
      onWin: _showWinDialog,
      onGameOver: _showGameOverDialog,
    );
    _controller.initializeGame();
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text(
            'You Win!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Score: ${_board.score}',
            style: const TextStyle(fontSize: 24, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.restart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getTileColor(32),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Restart',
                style: TextStyle(fontSize: 18, color: AppColors.textLight),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text(
            'Game Over',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Score: ${_board.score}',
            style: const TextStyle(fontSize: 24, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.restart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getTileColor(64),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Restart',
                style: TextStyle(fontSize: 18, color: AppColors.textLight),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSwipe(DragEndDetails details) {
    if (_board.isGameOver) return;
    
    // Sensitivity threshold for a swipe
    const double threshold = 50.0;
    
    // We only register a swipe if it's primarily horizontal or vertical
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      if (dx > threshold) {
        _controller.moveRight();
      } else if (dx < -threshold) {
        _controller.moveLeft();
      }
    } else {
      // Vertical swipe
      if (dy > threshold) {
        _controller.moveDown();
      } else if (dy < -threshold) {
        _controller.moveUp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '2048',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score Board Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.boardBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'SCORE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '${_board.score}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _controller.restart();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.getTileColor(32),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Restart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Game Board wrapped in GestureDetector for swipe support
            Expanded(
              child: GestureDetector(
                onPanEnd: _onSwipe,
                behavior: HitTestBehavior.opaque, 
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AspectRatio(
                      aspectRatio: 1.0, // Keeping it square as requested
                      child: GameBoard(tiles: _board.tiles),
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
