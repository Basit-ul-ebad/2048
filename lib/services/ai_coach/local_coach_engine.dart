import '../../features/ai/logic/ai_engine.dart';
import '../../features/ai/models/ai_difficulty.dart';
import '../../features/game/logic/game_engine.dart';
import 'models/coach_advice.dart';

/// Instant move hints with plain-language explanations (no API).
class LocalCoachEngine {
  static const _moves = ['left', 'right', 'up', 'down'];

  final GameEngine _game = GameEngine();
  final AiEngine _ai = AiEngine();

  CoachAdvice analyze(List<int> board) {
    final dir = _ai.getBestMove(board, AiDifficulty.hard);
    if (dir == null) {
      return const CoachAdvice(
        headline: 'No moves left',
        what: 'The board is full and nothing can slide.',
        why: 'Start a new game and try keeping your biggest tile in one corner.',
      );
    }

    final move = _moves[dir];
    final result = _game.move(List<int>.from(board), dir);
    final after = result['board'] as List<int>;
    final scoreGained = result['scoreGained'] as int;
    final emptiesBefore = _emptyCount(board);
    final emptiesAfter = _emptyCount(after);

    final effects = _lineEffects(board, dir);
    final main = effects.isNotEmpty ? effects.first : null;

    final headline = _headline(move, main, scoreGained);
    final what = _what(move, main, effects, scoreGained, emptiesAfter - emptiesBefore);
    final why = _why(board, after, move, main, scoreGained, emptiesAfter - emptiesBefore);

    return CoachAdvice(
      move: move,
      headline: headline,
      what: what,
      why: why,
      highlightIndices: main?.indices ?? const [],
    );
  }

  int _emptyCount(List<int> board) => board.where((v) => v == 0).length;

  String _headline(String move, _LineEffect? main, int scoreGained) {
    if (main != null) {
      return '${main.a} + ${main.a} → ${main.a * 2}';
    }
    if (scoreGained > 0) {
      return 'Merge tiles';
    }
    return 'Swipe ${move.toUpperCase()}';
  }

  String _what(
    String move,
    _LineEffect? main,
    List<_LineEffect> all,
    int scoreGained,
    int extraSpace,
  ) {
    final parts = <String>[];

    if (main != null) {
      parts.add(
        'On the ${main.lineName}, two ${main.a}s slide ${move} and merge into one ${main.a * 2}.',
      );
    } else if (all.length > 1) {
      parts.add(
        'Several rows/columns shift $move and tiles combine (+$scoreGained points).',
      );
    } else if (scoreGained > 0) {
      parts.add('Tiles merge when you swipe $move (+$scoreGained points).');
    } else {
      parts.add('All tiles slide $move. Nothing merges this turn.');
    }

    if (extraSpace > 0) {
      parts.add(
        extraSpace == 1
            ? 'You gain 1 empty cell.'
            : 'You gain $extraSpace empty cells.',
      );
    }

    parts.add('After you swipe, a new 2 (or 4) appears in a random empty spot.');

    return parts.join(' ');
  }

  String _why(
    List<int> before,
    List<int> after,
    String move,
    _LineEffect? main,
    int scoreGained,
    int extraSpace,
  ) {
    if (main != null) {
      return 'Merging the ${main.a}s is safe: same numbers touch, you score, and the board stays tidy.';
    }

    final maxBefore = _maxTile(before);
    final maxAfter = _maxTile(after);
    final cornerIdx = _cornerIndex(maxAfter, after);
    if (cornerIdx != null && after[cornerIdx] == maxAfter && maxAfter >= maxBefore) {
      final corner = _cellName(cornerIdx);
      return 'Your biggest tile ($maxAfter) stays in the $corner — good corner strategy.';
    }

    if (extraSpace >= 2) {
      return 'More empty space means fewer game-overs. Don\'t fill the board too fast.';
    }

    if (scoreGained == 0) {
      return 'This slide sets up a merge on your next move — watch for matching numbers lining up.';
    }

    return 'This is the strongest slide right now: good merges and board control.';
  }

  int _maxTile(List<int> board) {
    var m = 0;
    for (final v in board) {
      if (v > m) m = v;
    }
    return m;
  }

  int? _cornerIndex(int value, List<int> board) {
    const corners = [0, 3, 12, 15];
    for (final i in corners) {
      if (board[i] == value) return i;
    }
    return null;
  }

  String _cellName(int index) {
    final row = index ~/ 4;
    final col = index % 4;
    final rowName = switch (row) {
      0 => 'top',
      3 => 'bottom',
      _ => 'middle',
    };
    final colName = switch (col) {
      0 => 'left',
      3 => 'right',
      _ => 'center',
    };
    if (row == 1 || row == 2) {
      if (col == 1 || col == 2) return '$rowName-center';
    }
    return '$rowName-$colName corner';
  }

  List<_LineEffect> _lineEffects(List<int> board, int direction) {
    final effects = <_LineEffect>[];
    for (var line = 0; line < 4; line++) {
      final cells = _lineCells(board, direction, line);
      final effect = _mergesOnLine(cells.values, cells.indices, _lineLabel(direction, line));
      if (effect != null) effects.add(effect);
    }
    effects.sort((a, b) => b.a.compareTo(a.a));
    return effects;
  }

  ({List<int> values, List<int> indices}) _lineCells(List<int> board, int direction, int line) {
    final values = <int>[];
    final indices = <int>[];
    final isColumn = direction == 2 || direction == 3;
    final reverse = direction == 1 || direction == 3;

    for (var i = 0; i < 4; i++) {
      final idx = isColumn ? line + i * 4 : line * 4 + i;
      values.add(board[idx]);
      indices.add(idx);
    }

    if (reverse) {
      return (
        values: values.reversed.toList(),
        indices: indices.reversed.toList(),
      );
    }
    return (values: values, indices: indices);
  }

  String _lineLabel(int direction, int line) {
    final isColumn = direction == 2 || direction == 3;
    if (isColumn) {
      return switch (line) {
        0 => 'left column',
        3 => 'right column',
        _ => 'column ${line + 1}',
      };
    }
    return switch (line) {
      0 => 'top row',
      3 => 'bottom row',
      _ => 'row ${line + 1}',
    };
  }

  _LineEffect? _mergesOnLine(List<int> values, List<int> indices, String lineName) {
    final tiles = <({int v, int idx})>[];
    for (var i = 0; i < 4; i++) {
      if (values[i] > 0) tiles.add((v: values[i], idx: indices[i]));
    }

    // Same single-pass merge as GameEngine (after tiles slide together).
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i].v == tiles[i + 1].v) {
        return _LineEffect(
          a: tiles[i].v,
          lineName: lineName,
          indices: [tiles[i].idx, tiles[i + 1].idx],
        );
      }
    }
    return null;
  }
}

class _LineEffect {
  _LineEffect({required this.a, required this.lineName, required this.indices});

  final int a;
  final String lineName;
  final List<int> indices;
}
