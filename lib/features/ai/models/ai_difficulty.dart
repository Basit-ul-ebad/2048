import 'dart:math';

/// AI opponent strength levels.
enum AiDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case AiDifficulty.easy:
        return 'Easy';
      case AiDifficulty.medium:
        return 'Medium';
      case AiDifficulty.hard:
        return 'Hard';
    }
  }

  String get description {
    switch (this) {
      case AiDifficulty.easy:
        return 'Random moves · slower pace';
      case AiDifficulty.medium:
        return 'Smart merges · balanced';
      case AiDifficulty.hard:
        return 'Corner strategy · aggressive';
    }
  }

  int get levelIndex {
    switch (this) {
      case AiDifficulty.easy:
        return 0;
      case AiDifficulty.medium:
        return 1;
      case AiDifficulty.hard:
        return 2;
    }
  }

  static AiDifficulty fromIndex(int index) {
    switch (index) {
      case 1:
        return AiDifficulty.medium;
      case 2:
        return AiDifficulty.hard;
      default:
        return AiDifficulty.easy;
    }
  }

  /// Human-like delay before each AI move.
  Duration randomMoveDelay(Random random) {
    switch (this) {
      case AiDifficulty.easy:
        return Duration(milliseconds: 700 + random.nextInt(501));
      case AiDifficulty.medium:
        return Duration(milliseconds: 400 + random.nextInt(301));
      case AiDifficulty.hard:
        return Duration(milliseconds: 150 + random.nextInt(251));
    }
  }
}
