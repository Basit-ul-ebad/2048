import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../game/logic/game_engine.dart';
import '../logic/ai_engine.dart';
import '../models/ai_difficulty.dart';
import '../services/ai_stats_service.dart';
import '../../../services/feedback/feedback_service.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/analytics/analytics_constants.dart';
import '../../../services/analytics/game_session_tracker.dart';

enum AiMatchResult { ongoing, playerWin, aiWin, draw }

class AiProvider extends ChangeNotifier {
  AiProvider({
    required this.difficulty,
    required AiStatsService statsService,
    required this.userId,
    required this.analyticsEnabled,
    required AnalyticsService analytics,
    FeedbackService? feedback,
  })  : _statsService = statsService,
        _analytics = analytics,
        _feedback = feedback,
        _engine = AiEngine(),
        _playerSession = GameSessionTracker(analytics);

  final AiDifficulty difficulty;
  final String userId;
  final bool analyticsEnabled;
  final AiStatsService _statsService;
  final AnalyticsService _analytics;
  final FeedbackService? _feedback;
  final AiEngine _engine;
  final GameSessionTracker _playerSession;
  final Random _random = Random();

  List<int> playerBoard = List.filled(16, 0);
  List<int> aiBoard = List.filled(16, 0);
  int playerScore = 0;
  int aiScore = 0;
  bool playerGameOver = false;
  bool aiGameOver = false;
  bool isAiThinking = false;
  bool gameFinished = false;
  AiMatchResult matchResult = AiMatchResult.ongoing;
  String? endMessage;

  Timer? _aiTimer;
  bool _statsRecorded = false;
  bool _analyticsFinished = false;

  GameEngine get gameEngine => _engine.gameEngine;

  String get _difficultyKey => difficulty.label.toLowerCase();

  /// Stop the match now and show results (voluntary quit).
  void endGameManually() {
    if (gameFinished) return;
    _cancelAiTimer();
    isAiThinking = false;

    if (playerScore > aiScore) {
      _finishMatch(playerWon: true, message: 'You ended the game — ahead on score.');
    } else if (aiScore > playerScore) {
      _finishMatch(playerWon: false, message: 'You ended the game — AI was ahead.');
    } else {
      _finishMatch(playerWon: false, message: 'You ended the game — tied score.', isDraw: true);
    }
  }

  void startGame() {
    _cancelAiTimer();
    gameFinished = false;
    matchResult = AiMatchResult.ongoing;
    endMessage = null;
    _statsRecorded = false;
    _analyticsFinished = false;
    playerGameOver = false;
    aiGameOver = false;
    playerScore = 0;
    aiScore = 0;

    var empty = List<int>.filled(16, 0);
    playerBoard = gameEngine.addRandomTile(gameEngine.addRandomTile(empty));
    aiBoard = gameEngine.addRandomTile(gameEngine.addRandomTile(List.from(empty)));

    _playerSession.start(mode: AnalyticsModes.ai);
    _analytics.logAiMatchStarted(difficulty: _difficultyKey);

    notifyListeners();
    _scheduleAiMove();
  }

  void playerMove(int direction) {
    if (gameFinished || playerGameOver) return;

    final result = gameEngine.move(List<int>.from(playerBoard), direction);
    if (result['moved'] != true) return;

    playerBoard = gameEngine.addRandomTile(result['board'] as List<int>);
    final scoreGained = result['scoreGained'] as int;
    playerScore += scoreGained;
    _feedback?.onMove(scoreGained: scoreGained);
    _playerSession.trackBoard(playerBoard, currentScore: playerScore);

    if (gameEngine.checkWin(playerBoard)) {
      _feedback?.onWin();
    }
    if (gameEngine.checkGameOver(playerBoard)) {
      playerGameOver = true;
    }
    notifyListeners();
    _evaluateMatchEnd();
  }

  void _scheduleAiMove() {
    _cancelAiTimer();
    if (gameFinished || aiGameOver) return;

    final delay = difficulty.randomMoveDelay(_random);
    isAiThinking = true;
    notifyListeners();

    _aiTimer = Timer(delay, () async {
      if (gameFinished || aiGameOver) {
        isAiThinking = false;
        notifyListeners();
        return;
      }

      final direction = await Future.microtask(
        () => _engine.getBestMove(List<int>.from(aiBoard), difficulty),
      );

      if (gameFinished || aiGameOver) {
        isAiThinking = false;
        notifyListeners();
        return;
      }

      if (direction == null) {
        aiGameOver = true;
        isAiThinking = false;
        notifyListeners();
        _evaluateMatchEnd();
        return;
      }

      final result = gameEngine.move(List<int>.from(aiBoard), direction);
      if (result['moved'] == true) {
        aiBoard = gameEngine.addRandomTile(result['board'] as List<int>);
        aiScore += result['scoreGained'] as int;
        if (gameEngine.checkGameOver(aiBoard)) {
          aiGameOver = true;
        }
      } else {
        aiGameOver = true;
      }

      isAiThinking = false;
      notifyListeners();
      _evaluateMatchEnd();

      if (!gameFinished && !aiGameOver) {
        _scheduleAiMove();
      }
    });
  }

  void _evaluateMatchEnd() {
    if (gameFinished) return;

    final playerWonTile = gameEngine.checkWin(playerBoard);
    final aiWonTile = gameEngine.checkWin(aiBoard);

    if (playerWonTile) {
      _finishMatch(playerWon: true, message: 'You reached 2048!');
      return;
    }
    if (aiWonTile) {
      _finishMatch(playerWon: false, message: 'AI reached 2048!');
      return;
    }

    if (playerGameOver && aiGameOver) {
      if (playerScore > aiScore) {
        _finishMatch(playerWon: true, message: 'Higher score — you win!');
      } else if (aiScore > playerScore) {
        _finishMatch(playerWon: false, message: 'AI wins on score.');
      } else {
        _finishMatch(playerWon: false, message: "It's a tie!", isDraw: true);
      }
    }
  }

  void _finishMatch({
    required bool playerWon,
    required String message,
    bool isDraw = false,
  }) {
    if (gameFinished) return;
    gameFinished = true;
    _cancelAiTimer();
    isAiThinking = false;
    endMessage = message;
    matchResult = isDraw
        ? AiMatchResult.draw
        : (playerWon ? AiMatchResult.playerWin : AiMatchResult.aiWin);
    notifyListeners();
    _logAnalyticsEnd(isDraw: isDraw, playerWon: playerWon);
    _recordStats(playerWon: isDraw ? null : playerWon);
  }

  Future<void> _logAnalyticsEnd({
    required bool isDraw,
    required bool playerWon,
  }) async {
    if (_analyticsFinished) return;
    _analyticsFinished = true;

    final winner = isDraw
        ? 'draw'
        : (playerWon ? 'player' : 'ai');

    await _analytics.logAiMatchFinished(
      difficulty: _difficultyKey,
      playerScore: playerScore,
      aiScore: aiScore,
      winner: winner,
    );

    await _playerSession.end(
      board: playerBoard,
      finalScore: playerScore,
      won: playerWon && !isDraw,
    );
  }

  Future<void> _recordStats({required bool? playerWon}) async {
    if (_statsRecorded || userId.isEmpty) return;
    _statsRecorded = true;
    await _statsService.recordAiGameResult(
      uid: userId,
      playerWon: playerWon,
      difficulty: difficulty,
      analyticsEnabled: analyticsEnabled,
    );
  }

  void _cancelAiTimer() {
    _aiTimer?.cancel();
    _aiTimer = null;
  }

  @override
  void dispose() {
    _cancelAiTimer();
    super.dispose();
  }
}
