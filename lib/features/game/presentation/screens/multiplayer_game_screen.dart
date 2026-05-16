import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/colors.dart';
import '../../logic/game_controller.dart';
import '../../models/board_model.dart';
import '../widgets/game_board.dart';
import '../../../../services/storage/storage_service.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String player1;
  final String player2;
  final int durationMinutes;

  const MultiplayerGameScreen({
    super.key,
    required this.player1,
    required this.player2,
    required this.durationMinutes,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late GameController _controller1;
  late GameController _controller2;
  
  BoardModel _board1 = BoardModel.empty();
  BoardModel _board2 = BoardModel.empty();
  
  late Timer _timer;
  int _remainingSeconds = 0;
  bool _gameEnded = false;

  @override
  void initState() {
    super.initState();
    // Force landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _remainingSeconds = widget.durationMinutes * 60;
    
    _controller1 = GameController(
      onStateUpdate: (b) => setState(() => _board1 = b),
      onWin: () {},
      onGameOver: () {},
    );
    _controller2 = GameController(
      onStateUpdate: (b) => setState(() => _board2 = b),
      onWin: () {},
      onGameOver: () {},
    );

    _controller1.initializeGame();
    _controller2.initializeGame();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _endGame();
      }
    });
  }

  void _endGame() {
    if (_gameEnded) return;
    _gameEnded = true;
    
    String winner = '';
    String loser = '';
    if (_board1.score > _board2.score) {
      winner = widget.player1;
      loser = widget.player2;
    } else if (_board2.score > _board1.score) {
      winner = widget.player2;
      loser = widget.player1;
    } else {
      winner = 'Tie';
    }

    if (winner != 'Tie') {
      StorageService().recordMatchScore(winner, loser);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Time\'s Up!', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 32), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                winner == 'Tie' ? 'It\'s a Tie!' : '$winner Wins!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              Text('${widget.player1}: ${_board1.score}', style: const TextStyle(fontSize: 18, color: AppColors.textDark)),
              Text('${widget.player2}: ${_board2.score}', style: const TextStyle(fontSize: 18, color: AppColors.textDark)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // exit multiplayer screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getTileColor(2048),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Return to Menu', style: TextStyle(color: Colors.white, fontSize: 18)),
            )
          ],
        );
      }
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    // Return to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String get _timeString {
    int m = _remainingSeconds ~/ 60;
    int s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onSwipe1(DragEndDetails details) {
    if (_gameEnded || _board1.isGameOver) return;
    _handleSwipe(details, _controller1);
  }

  void _onSwipe2(DragEndDetails details) {
    if (_gameEnded || _board2.isGameOver) return;
    _handleSwipe(details, _controller2);
  }
  
  void _handleSwipe(DragEndDetails details, GameController controller) {
    const double threshold = 50.0;
    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dx.abs() > dy.abs()) {
      if (dx > threshold) controller.moveRight();
      else if (dx < -threshold) controller.moveLeft();
    } else {
      if (dy > threshold) controller.moveDown();
      else if (dy < -threshold) controller.moveUp();
    }
  }

  Widget _buildPlayerSide(String playerName, BoardModel board, void Function(DragEndDetails) onSwipe) {
    return GestureDetector(
      onPanEnd: onSwipe,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    playerName, 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.boardBackground, borderRadius: BorderRadius.circular(8)),
                  child: Text('Score: ${board.score}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: GameBoard(tiles: board.tiles),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(child: _buildPlayerSide(widget.player1, _board1, _onSwipe1)),
                Container(width: 4, color: AppColors.boardBackground),
                Expanded(child: _buildPlayerSide(widget.player2, _board2, _onSwipe2)),
              ],
            ),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 10 ? Colors.red : AppColors.getTileColor(2048),
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Text(
                    _timeString,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark, size: 32,),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
