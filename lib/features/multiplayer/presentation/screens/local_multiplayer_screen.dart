import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../game/logic/game_engine.dart';
import '../../../game/presentation/widgets/game_board.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
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
      setState(() {
        _board1 = _engine.addRandomTile(result['board']);
        _score1 += result['scoreGained'] as int;
        _isGameOver1 = _engine.checkGameOver(_board1);
      });
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
      setState(() {
        _board2 = _engine.addRandomTile(result['board']);
        _score2 += result['scoreGained'] as int;
        _isGameOver2 = _engine.checkGameOver(_board2);
      });
      _checkOverallGameOver();
    }
  }

  void _checkOverallGameOver() {
    if (_isGameOver1 && _isGameOver2) {
      String winner = "It's a Tie!";
      if (_score1 > _score2) winner = "Player 1 Wins!";
      if (_score2 > _score1) winner = "Player 2 Wins!";

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
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return Column(
              children: [
                Expanded(child: _buildPlayerSection(2, _board2, _score2, _handleSwipePlayer2, true)),
                const Divider(height: 4, thickness: 4, color: AppColors.textDark),
                Expanded(child: _buildPlayerSection(1, _board1, _score1, _handleSwipePlayer1, false)),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(child: _buildPlayerSection(1, _board1, _score1, _handleSwipePlayer1, false)),
                const VerticalDivider(width: 4, thickness: 4, color: AppColors.textDark),
                Expanded(child: _buildPlayerSection(2, _board2, _score2, _handleSwipePlayer2, false)),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPlayerSection(int playerNum, List<int> board, int score, void Function(DragEndDetails) onSwipe, bool rotate) {
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Player $playerNum - Score: $score',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: GestureDetector(
              onPanEnd: onSwipe,
              behavior: HitTestBehavior.opaque,
              child: GameBoard(tiles: board),
            ),
          ),
        ),
      ],
    );

    if (rotate) {
      return Transform.rotate(
        angle: 3.14159, // 180 degrees in radians
        child: content,
      );
    }
    return content;
  }
}
