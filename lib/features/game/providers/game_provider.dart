import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/game_engine.dart';
import '../../../core/constants/game_constants.dart';
import '../../../services/storage/local_storage_service.dart';
import '../../../services/firebase/firestore_service.dart';

class GameProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService;
  final FirestoreService _firestoreService;
  final GameEngine _engine = GameEngine();

  List<int> _board = List.filled(16, 0);
  int _score = 0;
  bool _isGameOver = false;
  bool _isGameWon = false;
  bool _isMultiplayer = false;

  GameProvider(this._localStorageService, this._firestoreService);

  List<int> get board => _board;
  int get score => _score;
  bool get isGameOver => _isGameOver;
  bool get isGameWon => _isGameWon;

  void initializeGame({bool isMultiplayer = false}) {
    _isMultiplayer = isMultiplayer;
    _isGameOver = false;
    _isGameWon = false;

    if (!_isMultiplayer) {
      final savedBoardJson = _localStorageService.savedBoard;
      if (savedBoardJson != null) {
        try {
          final List<dynamic> decoded = json.decode(savedBoardJson);
          _board = decoded.cast<int>();
          _score = _localStorageService.savedScore;
          notifyListeners();
          return;
        } catch (e) {
          // Fallback if parsing fails
        }
      }
    }

    _board = List.filled(16, 0);
    _score = 0;
    
    // Add two initial tiles
    _board = _engine.addRandomTile(_board);
    _board = _engine.addRandomTile(_board);
    _saveGameState();
    notifyListeners();
  }
  
  void _submitMatchResults() {
    if (_isMultiplayer) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.addMatchResults(user.uid, _score);
    }
  }

  void restartGame({bool isMultiplayer = false}) {
    if (!isMultiplayer) {
      _localStorageService.clearSavedGame();
    }
    initializeGame(isMultiplayer: isMultiplayer);
  }

  void _saveGameState() {
    if (_isMultiplayer) return; // Don't save to local storage in multiplayer

    _localStorageService.setSavedBoard(json.encode(_board));
    _localStorageService.setSavedScore(_score);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.updateHighestScore(user.uid, _score);
    }
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
        _localStorageService.clearSavedGame();
        _submitMatchResults();
      } else if (_isGameWon) {
        _submitMatchResults();
        _saveGameState();
      } else {
        _saveGameState();
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
