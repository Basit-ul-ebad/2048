class GameConstants {
  // Grid
  static const int crossAxisCount = 4;
  static const int emptyTileValue = 0;
  static const int winValue = 2048;

  // Animations (Durations in milliseconds)
  static const int tileMoveDuration = 150;
  static const int tileScaleDuration = 100;
  static const int tileMergeScaleDuration = 100;

  // Thresholds for swipe gestures
  static const double swipeVelocityThreshold = 250.0;
  static const double swipeDistanceThreshold = 20.0;

  // Rewards
  static const int expPerWin = 50;
  static const int expPerLoss = 10;
  static const int coinsPerWin = 20;

  // Sync intervals
  static const int boardSyncDebounceMs = 150; // Performance optimization layer
}
