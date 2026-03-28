class BoardModel {
  final List<int> tiles;
  final int score;
  final bool isGameOver;
  final bool isWon;

  BoardModel({
    required this.tiles,
    required this.score,
    this.isGameOver = false,
    this.isWon = false,
  });

  // Factory constructor to create an initial empty board
  factory BoardModel.empty() {
    return BoardModel(
      tiles: List.filled(16, 0),
      score: 0,
    );
  }

  BoardModel copyWith({
    List<int>? tiles,
    int? score,
    bool? isGameOver,
    bool? isWon,
  }) {
    return BoardModel(
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
      isGameOver: isGameOver ?? this.isGameOver,
      isWon: isWon ?? this.isWon,
    );
  }
}
