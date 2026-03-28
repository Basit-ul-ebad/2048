import 'dart:math';

class GameEngine {
  final Random _random = Random();

  /// Adds a random tile (2 or 4) to an empty spot on the board
  List<int> addRandomTile(List<int> board) {
    List<int> emptyIndices = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 0) {
        emptyIndices.add(i);
      }
    }

    if (emptyIndices.isEmpty) return board;

    int randomIndex = emptyIndices[_random.nextInt(emptyIndices.length)];
    // 90% chance of 2, 10% chance of 4
    int newValue = _random.nextDouble() < 0.9 ? 2 : 4;
    
    List<int> newBoard = List.from(board);
    newBoard[randomIndex] = newValue;
    return newBoard;
  }

  /// Processes a move in a given direction, returning the new board and any gained score
  /// Directions: 0 = left, 1 = right, 2 = up, 3 = down
  Map<String, dynamic> move(List<int> board, int direction) {
    List<List<int>> grid = _to2D(board);
    int scoreGained = 0;
    bool moved = false;

    // We only implement "move left" logic, and for other directions,
    // we rotate the grid, move left, then rotate back.
    if (direction == 1) { // Right
      grid = _rotateRight(_rotateRight(grid));
    } else if (direction == 2) { // Up
      grid = _rotateLeft(grid);
    } else if (direction == 3) { // Down
      grid = _rotateRight(grid);
    }

    // Move left for all rows
    for (int i = 0; i < 4; i++) {
      Map<String, dynamic> rowResult = _slideAndMergeRow(grid[i]);
      List<int> newRow = rowResult['row'];
      int rowScore = rowResult['score'];
      
      if (!_listEquals(grid[i], newRow)) {
        moved = true;
      }
      
      grid[i] = newRow;
      scoreGained += rowScore;
    }

    // Rotate back to original orientation
    if (direction == 1) { // Right (rotated 180 originally)
      grid = _rotateRight(_rotateRight(grid));
    } else if (direction == 2) { // Up (rotated left originally, so rotate right)
      grid = _rotateRight(grid);
    } else if (direction == 3) { // Down (rotated right originally, so rotate left)
      grid = _rotateLeft(grid);
    }

    return {
      'board': _to1D(grid),
      'scoreGained': scoreGained,
      'moved': moved,
    };
  }

  /// Slides and merges a single row to the left
  Map<String, dynamic> _slideAndMergeRow(List<int> row) {
    // 1. Remove zeros
    List<int> nonZero = row.where((val) => val != 0).toList();
    int scoreGained = 0;

    // 2. Merge identical adjacent tiles
    for (int i = 0; i < nonZero.length - 1; i++) {
      if (nonZero[i] == nonZero[i + 1]) {
        nonZero[i] *= 2;
        scoreGained += nonZero[i];
        nonZero.removeAt(i + 1);
      }
    }

    // 3. Pad with zeros to keep length 4
    while (nonZero.length < 4) {
      nonZero.add(0);
    }

    return {
      'row': nonZero,
      'score': scoreGained,
    };
  }

  /// Checks if any tile reached 2048
  bool checkWin(List<int> board) {
    return board.contains(2048);
  }

  /// Checks if no more moves are possible
  bool checkGameOver(List<int> board) {
    if (board.contains(0)) return false;

    // Check horizontal merges
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i * 4 + j] == board[i * 4 + j + 1]) return false;
      }
    }

    // Check vertical merges
    for (int j = 0; j < 4; j++) {
      for (int i = 0; i < 3; i++) {
        if (board[i * 4 + j] == board[(i + 1) * 4 + j]) return false;
      }
    }

    return true;
  }

  bool _listEquals(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Converts 1D list to 4x4 2D list
  List<List<int>> _to2D(List<int> list) {
    return [
      [list[0], list[1], list[2], list[3]],
      [list[4], list[5], list[6], list[7]],
      [list[8], list[9], list[10], list[11]],
      [list[12], list[13], list[14], list[15]],
    ];
  }

  /// Converts 2D list to 1D list
  List<int> _to1D(List<List<int>> grid) {
    return [
      ...grid[0],
      ...grid[1],
      ...grid[2],
      ...grid[3],
    ];
  }

  List<List<int>> _rotateRight(List<List<int>> grid) {
    List<List<int>> newGrid = List.generate(4, (_) => List.filled(4, 0));
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        newGrid[c][3 - r] = grid[r][c];
      }
    }
    return newGrid;
  }

  List<List<int>> _rotateLeft(List<List<int>> grid) {
    List<List<int>> newGrid = List.generate(4, (_) => List.filled(4, 0));
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        newGrid[3 - c][r] = grid[r][c];
      }
    }
    return newGrid;
  }
}
