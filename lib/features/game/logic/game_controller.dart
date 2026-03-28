import '../models/board_model.dart';
import 'game_engine.dart';

class GameController {
  final GameEngine _engine = GameEngine();
  // Using a callback for state changes so we don't need complex state management
  final Function(BoardModel) onStateUpdate;
  final Function() onWin;
  final Function() onGameOver;
  
  BoardModel _board = BoardModel.empty();
  bool _hasWonAlready = false;

  GameController({
    required this.onStateUpdate,
    required this.onWin,
    required this.onGameOver,
  });

  BoardModel get board => _board;

  void initializeGame() {
    _hasWonAlready = false;
    List<int> initialTiles = List.filled(16, 0);
    initialTiles = _engine.addRandomTile(initialTiles);
    initialTiles = _engine.addRandomTile(initialTiles);
    
    _board = BoardModel(
      tiles: initialTiles,
      score: 0,
      isGameOver: false,
      isWon: false,
    );
    
    onStateUpdate(_board);
  }

  void moveLeft() => _handleMove(0);
  void moveRight() => _handleMove(1);
  void moveUp() => _handleMove(2);
  void moveDown() => _handleMove(3);

  void _handleMove(int direction) {
    if (_board.isGameOver) return; // Prevent moves if game over
    
    var result = _engine.move(_board.tiles, direction);
    bool moved = result['moved'];
    
    if (moved) {
      List<int> newTiles = result['board'];
      int newScore = _board.score + (result['scoreGained'] as int);
      
      newTiles = _engine.addRandomTile(newTiles);
      
      bool isWin = _engine.checkWin(newTiles);
      bool isOver = _engine.checkGameOver(newTiles);
      
      _board = _board.copyWith(
        tiles: newTiles,
        score: newScore,
        isGameOver: isOver,
        isWon: isWin,
      );
      
      onStateUpdate(_board);

      if (isWin && !_hasWonAlready) {
        _hasWonAlready = true;
        onWin();
      } else if (isOver) {
        onGameOver();
      }
    }
  }

  void restart() {
    initializeGame();
  }
}
