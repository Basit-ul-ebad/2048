import 'dart:math';

import '../../game/logic/game_engine.dart';
import '../models/ai_difficulty.dart';

/// Algorithmic 2048 AI (no machine learning).
class AiEngine {
  final GameEngine _gameEngine = GameEngine();
  final Random _random = Random();

  /// Returns direction indices 0–3 that change the board, or empty if stuck.
  List<int> getValidMoves(List<int> board) {
    final moves = <int>[];
    for (var d = 0; d < 4; d++) {
      final result = _gameEngine.move(List<int>.from(board), d);
      if (result['moved'] == true) {
        moves.add(d);
      }
    }
    return moves;
  }

  /// Picks the best direction for the given difficulty, or null if no move.
  int? getBestMove(List<int> board, AiDifficulty difficulty) {
    final valid = getValidMoves(board);
    if (valid.isEmpty) return null;

    switch (difficulty) {
      case AiDifficulty.easy:
        return valid[_random.nextInt(valid.length)];
      case AiDifficulty.medium:
        return _pickGreedy(board, valid);
      case AiDifficulty.hard:
        return _pickHard(board, valid);
    }
  }

  int _pickGreedy(List<int> board, List<int> valid) {
    var bestDir = valid.first;
    var bestEval = double.negativeInfinity;
    for (final d in valid) {
      final result = _gameEngine.move(List<int>.from(board), d);
      final eval = evaluateBoard(result['board'] as List<int>);
      if (eval > bestEval) {
        bestEval = eval;
        bestDir = d;
      }
    }
    return bestDir;
  }

  int _pickHard(List<int> board, List<int> valid) {
    var bestDir = valid.first;
    var bestScore = double.negativeInfinity;
    for (final d in valid) {
      final score = _expectimax(board, d, depth: 2);
      if (score > bestScore) {
        bestScore = score;
        bestDir = d;
      }
    }
    return bestDir;
  }

  /// Lightweight expectimax-style lookahead (spawn-aware, not full ML).
  double _expectimax(List<int> board, int direction, {required int depth}) {
    final result = _gameEngine.move(List<int>.from(board), direction);
    if (result['moved'] != true) return double.negativeInfinity;

    var newBoard = result['board'] as List<int>;
    if (depth <= 0) return evaluateBoard(newBoard);

    final empties = <int>[];
    for (var i = 0; i < 16; i++) {
      if (newBoard[i] == 0) empties.add(i);
    }
    if (empties.isEmpty) return evaluateBoard(newBoard);

    empties.shuffle(_random);
    final sample = empties.take(empties.length.clamp(1, 4));
    var total = 0.0;
    var count = 0;

    for (final idx in sample) {
      final spawned = List<int>.from(newBoard)..[idx] = 2;
      final replies = getValidMoves(spawned);
      if (replies.isEmpty) {
        total += evaluateBoard(spawned);
      } else {
        var worst = double.infinity;
        for (final reply in replies) {
          final s = _expectimax(spawned, reply, depth: depth - 1);
          if (s < worst) worst = s;
        }
        total += worst;
      }
      count++;
    }
    return total / count;
  }

  double evaluateBoard(List<int> board) {
    return calculateEmptySpaces(board) * 2.8 +
        calculateMergePotential(board) * 1.6 +
        calculateCornerPriority(board) * 3.2 +
        _monotonicityScore(board) * 1.2 +
        _maxTileValue(board) * 0.15;
  }

  int calculateEmptySpaces(List<int> board) {
    return board.where((v) => v == 0).length;
  }

  int calculateMergePotential(List<int> board) {
    var potential = 0;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        final v = board[r * 4 + c];
        if (v == 0) continue;
        if (c < 3 && v == board[r * 4 + c + 1]) potential++;
        if (r < 3 && v == board[(r + 1) * 4 + c]) potential++;
      }
    }
    return potential;
  }

  double calculateCornerPriority(List<int> board) {
    const corners = [0, 3, 12, 15];
    var max = 0;
    for (final v in board) {
      if (v > max) max = v;
    }
    if (max == 0) return 0;

    var score = 0.0;
    for (final i in corners) {
      if (board[i] > 0) {
        score += board[i] / max;
      }
    }
    // Bonus if global max is in bottom-left corner (index 12)
    if (board[12] == max) score += 2.0;
    return score;
  }

  double _monotonicityScore(List<int> board) {
    var inc = 0;
    var dec = 0;
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 3; c++) {
        final a = board[r * 4 + c];
        final b = board[r * 4 + c + 1];
        if (a > b) {
          inc++;
        } else if (b > a) {
          dec++;
        }
      }
    }
    for (var c = 0; c < 4; c++) {
      for (var r = 0; r < 3; r++) {
        final a = board[r * 4 + c];
        final b = board[(r + 1) * 4 + c];
        if (a > b) {
          inc++;
        } else if (b > a) {
          dec++;
        }
      }
    }
    return max(inc, dec).toDouble();
  }

  int _maxTileValue(List<int> board) {
    return board.fold(0, (a, b) => a > b ? a : b);
  }

  GameEngine get gameEngine => _gameEngine;
}
