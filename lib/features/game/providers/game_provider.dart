import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/game_engine.dart';
import '../models/single_player_mode.dart';
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
  SinglePlayerMode _singlePlayerMode = SinglePlayerMode.classic;
  Timer? _timer;
  int _secondsRemaining = 0;
  String? _endReason;

  List<int> get board => _board;
  int get score => _score;
  bool get isGameOver => _isGameOver;
  bool get isGameWon => _isGameWon;
  bool get endedManually => _endedManually;
  bool get isFinished => _isGameOver || _isGameWon;
  bool get isPlaying => !_isGameOver && !_isGameWon;
  SinglePlayerMode get singlePlayerMode => _singlePlayerMode;
  int get secondsRemaining => _secondsRemaining;
  String? get endReason => _endReason;

  void initializeGame({
    bool isMultiplayer = false,
    String mode = AnalyticsModes.singlePlayer,
    SinglePlayerMode? singlePlayerMode,
  }) {
    _timer?.cancel();
    _isMultiplayer = isMultiplayer;
    _mode = mode;
    _singlePlayerMode = singlePlayerMode ?? SinglePlayerMode.classic;
    _isGameOver = false;
    _isGameWon = false;
    _endedManually = false;
    _endReason = null;

    if (!_isMultiplayer && _singlePlayerMode.isClassic) {
      final savedBoardJson = _localStorageService.savedBoard;
      if (savedBoardJson != null) {
        try {
          final List<dynamic> decoded = json.decode(savedBoardJson);
          _board = decoded.cast<int>();
          _score = _localStorageService.savedScore;
          notifyListeners();
          return;
        } catch (_) {}
      }
    }

    _board = List.filled(16, 0);
    _score = 0;
    _board = _engine.addRandomTile(_board);
    _board = _engine.addRandomTile(_board);

    if (!_isMultiplayer) {
      _session.start(mode: mode);
      _startTimerIfNeeded();
    }

    if (_singlePlayerMode.isClassic && !_isMultiplayer) {
      _saveGameState();
    }
    notifyListeners();
  }

  void _startTimerIfNeeded() {
    final limit = _singlePlayerMode.timeLimitSeconds;
    if (limit == null) return;

    _secondsRemaining = limit;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsRemaining--;
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        _endTimedGame(reason: 'Time\'s up!');
      } else {
        notifyListeners();
      }
    });
  }

  void _endTimedGame({required String reason}) {
    if (!isPlaying) return;
    _endReason = reason;
    _isGameOver = true;
    _localStorageService.clearSavedGame();
    _finalizeSession();
    if (!_singlePlayerMode.isClassic) {
      _submitMatchResults();
    }
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
    SinglePlayerMode? singlePlayerMode,
  }) {
    if (!isMultiplayer) {
      _localStorageService.clearSavedGame();
    }
    initializeGame(
      isMultiplayer: isMultiplayer,
      mode: mode,
      singlePlayerMode: singlePlayerMode ?? _singlePlayerMode,
    );
  }

  void _saveGameState() {
    if (_isMultiplayer || !_singlePlayerMode.isClassic) return;

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

  void endGameManually() {
    if (!isPlaying) return;
    _endedManually = true;
    _endReason = 'You ended the game';
    _timer?.cancel();
    _isGameOver = true;
    _localStorageService.clearSavedGame();
    _finalizeSession();
    if (!_singlePlayerMode.isClassic) {
      _submitMatchResults();
    }
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

      final target = _singlePlayerMode.targetScore;
      if (target != null && _score >= target) {
        _isGameWon = true;
        _endReason = 'Target score reached!';
        _feedback.onWin();
        _timer?.cancel();
        _finalizeSession();
        _submitMatchResults();
        notifyListeners();
        return;
      }

      if (_engine.checkWin(_board)) {
        _isGameWon = true;
        _endReason = 'You reached 2048!';
        _feedback.onWin();
      }

      _board = _engine.addRandomTile(_board);

      if (_engine.checkGameOver(_board)) {
        _isGameOver = true;
        _endReason = 'No moves left';
        _timer?.cancel();
        _localStorageService.clearSavedGame();
        _finalizeSession();
        if (!_singlePlayerMode.isClassic) {
          _submitMatchResults();
        }
      } else if (_isGameWon) {
        _timer?.cancel();
        _finalizeSession();
        if (!_singlePlayerMode.isClassic) {
          _submitMatchResults();
        }
        if (_singlePlayerMode.isClassic) {
          _saveGameState();
        }
      } else if (_singlePlayerMode.isClassic) {
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
        handleSwipe(velocity.dx > 0 ? 1 : 0);
      } else {
        handleSwipe(velocity.dy > 0 ? 3 : 2);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
