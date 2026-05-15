import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../../../core/constants/game_constants.dart';

class GameProvider extends ChangeNotifier {
  final GameEngine _engine = GameEngine();

  List<int> _board = List.filled(16, 0);
  int _score = 0;
  bool _isGameOver = false;
  bool _isGameWon = false;

  List<int> get board => _board;
  int get score => _score;
  bool get isGameOver => _isGameOver;
  bool get isGameWon => _isGameWon;

  void initializeGame() {
    _board = List.filled(16, 0);
    _score = 0;
    _isGameOver = false;
    _isGameWon = false;
    
    // Add two initial tiles
    _board = _engine.addRandomTile(_board);
    _board = _engine.addRandomTile(_board);
    notifyListeners();
  }

  void handleSwipe(int direction) {
    if (_isGameOver || _isGameWon) return;

    final result = _engine.move(_board, direction);
    bool moved = result['moved'];

    if (moved) {
      _board = result['board'];
      _score += result['scoreGained'] as int;

      // Check win condition
      if (_engine.checkWin(_board)) {
        _isGameWon = true;
      }

      // Add a new tile after the move
      _board = _engine.addRandomTile(_board);

      // Check if game over after adding new tile
      if (_engine.checkGameOver(_board)) {
        _isGameOver = true;
      }

      notifyListeners();
    }
  }

  // Use for performance optimization layer when handling drag details
  void handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() > GameConstants.swipeVelocityThreshold || 
        velocity.dy.abs() > GameConstants.swipeVelocityThreshold) {
      if (velocity.dx.abs() > velocity.dy.abs()) {
        // Horizontal swipe
        if (velocity.dx > 0) {
          handleSwipe(1); // Right
        } else {
          handleSwipe(0); // Left
        }
      } else {
        // Vertical swipe
        if (velocity.dy > 0) {
          handleSwipe(3); // Down
        } else {
          handleSwipe(2); // Up
        }
      }
    }
  }
}
