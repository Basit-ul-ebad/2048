import 'analytics_constants.dart';
import 'analytics_service.dart';

/// Tracks a single game session duration and tile milestones for analytics.
class GameSessionTracker {
  GameSessionTracker(this._analytics);

  final AnalyticsService _analytics;
  final Set<int> _loggedMilestones = {};

  String _mode = AnalyticsModes.singlePlayer;
  DateTime? _startedAt;
  bool _ended = false;

  void start({required String mode}) {
    _mode = mode;
    _startedAt = DateTime.now();
    _ended = false;
    _loggedMilestones.clear();
    _analytics.logGameStarted(mode: mode);
  }

  void trackBoard(List<int> board, {required int currentScore}) {
    final max = AnalyticsService.highestTileOnBoard(board);
    for (final tile in AnalyticsTileMilestones.milestones) {
      if (max >= tile && !_loggedMilestones.contains(tile)) {
        _loggedMilestones.add(tile);
        _analytics.logTileAchieved(
          tile: tile,
          mode: _mode,
          finalScore: currentScore,
        );
      }
    }
  }

  Future<void> end({
    required List<int> board,
    required int finalScore,
    required bool won,
  }) async {
    if (_ended) return;
    _ended = true;

    final duration = _startedAt == null
        ? 0
        : DateTime.now().difference(_startedAt!).inSeconds;
    final highestTile = AnalyticsService.highestTileOnBoard(board);

    await _analytics.logGameFinished(
      mode: _mode,
      highestTile: highestTile,
      finalScore: finalScore,
      durationSeconds: duration,
    );

    if (won) {
      await _analytics.logGameWon(
        mode: _mode,
        highestTile: highestTile,
        finalScore: finalScore,
        durationSeconds: duration,
      );
    } else {
      await _analytics.logGameLost(
        mode: _mode,
        highestTile: highestTile,
        finalScore: finalScore,
        durationSeconds: duration,
      );
    }
  }

  int get durationSeconds => _startedAt == null
      ? 0
      : DateTime.now().difference(_startedAt!).inSeconds;
}
