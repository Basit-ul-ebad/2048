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

  factory BoardModel.fromJson(Map<String, dynamic> json) {
    return BoardModel(
      tiles: List<int>.from(
        (json['tiles'] as List<dynamic>).map((e) => (e as num).toInt()),
      ),
      score: (json['score'] as num).toInt(),
      isGameOver: json['isGameOver'] as bool? ?? false,
      isWon: json['isWon'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'tiles': tiles,
        'score': score,
        'isGameOver': isGameOver,
        'isWon': isWon,
      };
}
