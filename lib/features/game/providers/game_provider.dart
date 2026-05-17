import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/game_engine.dart';
import '../../../core/constants/game_constants.dart';
import '../../../services/storage/local_storage_service.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../../services/feedback/feedback_service.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/analytics/analytics_constants.dart';
import '../../../services/analytics/game_session_tracker.dart';

class GameProvider extends ChangeNotifier {
  GameProvider(
    this._localStorageService,
    this._firestoreService,
    this._feedback,
    this._analytics,
  ) : _session = GameSessionTracker(_analytics);

  final LocalStorageService _localStorageService;
  final FirestoreService _firestoreService;
  final FeedbackService _feedback;
  final AnalyticsService _analytics;
  final GameSessionTracker _session;
  final GameEngine _engine = GameEngine();

  List<int> _board = List.filled(16, 0);
  int _score = 0;
  bool _isGameOver = false;
  bool _isGameWon = false;
  bool _endedManually = false;
  bool _isMultiplayer = false;
  String _mode = AnalyticsModes.singlePlayer;

  List<int> get board => _board;
  int get score => _score;
  bool get isGameOver => _isGameOver;
  bool get isGameWon => _isGameWon;
  bool get endedManually => _endedManually;
  bool get isFinished => _isGameOver || _isGameWon;

  /// True while the player can still swipe or end the session.
  bool get isPlaying => !_isGameOver && !_isGameWon;

  void initializeGame({
    bool isMultiplayer = false,
    String mode = AnalyticsModes.singlePlayer,
  }) {
    _isMultiplayer = isMultiplayer;
    _mode = mode;
    _isGameOver = false;
    _isGameWon = false;
    _endedManually = false;

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

    _board = _engine.addRandomTile(_board);
    _board = _engine.addRandomTile(_board);

    if (!isMultiplayer) {
      _session.start(mode: mode);
    }

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

  void restartGame({
    bool isMultiplayer = false,
    String mode = AnalyticsModes.singlePlayer,
  }) {
    if (!isMultiplayer) {
      _localStorageService.clearSavedGame();
    }
    initializeGame(isMultiplayer: isMultiplayer, mode: mode);
  }

  void _saveGameState() {
    if (_isMultiplayer) return;

    _localStorageService.setSavedBoard(json.encode(_board));
    _localStorageService.setSavedScore(_score);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.updateHighestScore(user.uid, _score);
    }
  }

  void _finalizeSession() {
    if (_isMultiplayer) return;
    _session.end(
      board: _board,
      finalScore: _score,
      won: _isGameWon,
    );
  }

  /// Player quits the current run (score is kept for review / leaderboard).
  void endGameManually() {
    if (!isPlaying) return;
    _endedManually = true;
    _isGameOver = true;
    _localStorageService.clearSavedGame();
    _finalizeSession();
    _submitMatchResults();
    notifyListeners();
  }

  void handleSwipe(int direction) {
    if (!isPlaying) return;

    final result = _engine.move(_board, direction);
    final moved = result['moved'] as bool;

    if (moved) {
      _board = result['board'] as List<int>;
      final scoreGained = result['scoreGained'] as int;
      _score += scoreGained;
      _feedback.onMove(scoreGained: scoreGained);

      if (!_isMultiplayer) {
        _session.trackBoard(_board, currentScore: _score);
      }

      if (_engine.checkWin(_board)) {
        _isGameWon = true;
        _feedback.onWin();
      }

      _board = _engine.addRandomTile(_board);

      if (_engine.checkGameOver(_board)) {
        _isGameOver = true;
        _localStorageService.clearSavedGame();
        _finalizeSession();
        _submitMatchResults();
      } else if (_isGameWon) {
        _finalizeSession();
        _submitMatchResults();
        _saveGameState();
      } else {
        _saveGameState();
      }

      notifyListeners();
    }
  }

  void handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() > GameConstants.swipeVelocityThreshold ||
        velocity.dy.abs() > GameConstants.swipeVelocityThreshold) {
      if (velocity.dx.abs() > velocity.dy.abs()) {
        if (velocity.dx > 0) {
          handleSwipe(1);
        } else {
          handleSwipe(0);
        }
      } else {
        if (velocity.dy > 0) {
          handleSwipe(3);
        } else {
          handleSwipe(2);
        }
      }
    }
  }
}
