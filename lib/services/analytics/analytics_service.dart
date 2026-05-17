import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../storage/local_storage_service.dart';
import 'analytics_constants.dart';

/// Centralized Firebase Analytics + Crashlytics logging.
/// All gameplay-related events flow through this class.
class AnalyticsService {
  AnalyticsService(this._storage)
      : _analytics = FirebaseAnalytics.instance,
        _crashlytics = FirebaseCrashlytics.instance;

  final LocalStorageService _storage;
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  bool get isEnabled => _storage.analyticsEnabled;

  /// Sync Firebase collection flag with user preference (call on startup & toggle).
  Future<void> syncCollectionEnabled() async {
    await _analytics.setAnalyticsCollectionEnabled(isEnabled);
    await _crashlytics.setCrashlyticsCollectionEnabled(isEnabled);
  }

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId);
    }
  }

  Future<void> logNonFatalError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  // ─── Authentication ───────────────────────────────────────────────────────

  Future<void> logLoginSuccess({required String loginMethod}) async {
    await _log('login_success', {'login_method': loginMethod});
  }

  Future<void> logSignupSuccess({required String loginMethod}) async {
    await _log('signup_success', {'login_method': loginMethod});
  }

  Future<void> logLogout() async {
    await _log('logout');
    await setUserId(null);
  }

  Future<void> logGoogleSignInUsed() async {
    await _log('google_signin_used', {'login_method': AnalyticsLoginMethods.google});
  }

  Future<void> logEmailLoginUsed() async {
    await _log('email_login_used', {'login_method': AnalyticsLoginMethods.email});
  }

  // ─── Gameplay ─────────────────────────────────────────────────────────────

  Future<void> logGameStarted({required String mode}) async {
    await _log('game_started', {'mode': mode});
  }

  Future<void> logGameFinished({
    required String mode,
    required int highestTile,
    required int finalScore,
    required int durationSeconds,
  }) async {
    await _log('game_finished', {
      'mode': mode,
      'highest_tile': highestTile,
      'final_score': finalScore,
      'duration_seconds': durationSeconds,
    });
  }

  Future<void> logGameWon({
    required String mode,
    required int highestTile,
    required int finalScore,
    required int durationSeconds,
  }) async {
    await _log('game_won', {
      'mode': mode,
      'highest_tile': highestTile,
      'final_score': finalScore,
      'duration_seconds': durationSeconds,
    });
  }

  Future<void> logGameLost({
    required String mode,
    required int highestTile,
    required int finalScore,
    required int durationSeconds,
  }) async {
    await _log('game_lost', {
      'mode': mode,
      'highest_tile': highestTile,
      'final_score': finalScore,
      'duration_seconds': durationSeconds,
    });
  }

  Future<void> logTileAchieved({
    required int tile,
    required String mode,
    required int finalScore,
  }) async {
    if (!AnalyticsTileMilestones.milestones.contains(tile)) return;
    await _log('tile_achieved', {
      'tile': tile,
      'mode': mode,
      'final_score': finalScore,
    });
  }

  // ─── Multiplayer ──────────────────────────────────────────────────────────

  Future<void> logMultiplayerMatchStarted({
    required String mode,
    String? opponentType,
  }) async {
    await _log('multiplayer_match_started', {
      'mode': mode,
      if (opponentType != null) 'opponent_type': opponentType,
    });
  }

  Future<void> logMultiplayerMatchFinished({
    required String mode,
    required String winOrLoss,
    required int matchDurationSeconds,
    String? opponentType,
  }) async {
    await _log('multiplayer_match_finished', {
      'mode': mode,
      'win_or_loss': winOrLoss,
      'match_duration': matchDurationSeconds,
      if (opponentType != null) 'opponent_type': opponentType,
    });
  }

  Future<void> logQuickMatchUsed() async {
    await _log('quick_match_used', {'mode': AnalyticsModes.quickMatch});
  }

  Future<void> logFriendMatchUsed() async {
    await _log('friend_match_used');
  }

  Future<void> logPartyRoomCreated() async {
    await _log('party_room_created');
  }

  Future<void> logPartyRoomJoined() async {
    await _log('party_room_joined');
  }

  // ─── AI mode ──────────────────────────────────────────────────────────────

  Future<void> logAiDifficultySelected({required String difficulty}) async {
    await _log('ai_difficulty_selected', {'difficulty': difficulty});
  }

  Future<void> logAiMatchStarted({required String difficulty}) async {
    await _log('ai_match_started', {'difficulty': difficulty});
  }

  Future<void> logAiMatchFinished({
    required String difficulty,
    required int playerScore,
    required int aiScore,
    required String winner,
  }) async {
    await _log('ai_match_finished', {
      'difficulty': difficulty,
      'player_score': playerScore,
      'ai_score': aiScore,
      'winner': winner,
    });
  }

  // ─── Leaderboard ──────────────────────────────────────────────────────────

  Future<void> logLeaderboardOpened() async {
    await _log('leaderboard_opened');
  }

  Future<void> logLeaderboardRankChanged({
    required int newRank,
    required int highestScore,
  }) async {
    await _log('leaderboard_rank_changed', {
      'new_rank': newRank,
      'highest_score': highestScore,
    });
  }

  // ─── Friends ──────────────────────────────────────────────────────────────

  Future<void> logFriendRequestSent() async {
    await _log('friend_request_sent');
  }

  Future<void> logFriendRequestAccepted() async {
    await _log('friend_request_accepted');
  }

  Future<void> logFriendAdded() async {
    await _log('friend_added');
  }

  // ─── Shop & skins ─────────────────────────────────────────────────────────

  Future<void> logSkinPurchased({
    required String skinName,
    required int skinPrice,
  }) async {
    await _log('skin_purchased', {
      'skin_name': skinName,
      'skin_price': skinPrice,
    });
  }

  Future<void> logSkinEquipped({required String skinName}) async {
    await _log('skin_equipped', {'skin_name': skinName});
  }

  Future<void> logThemeChanged({required String themeName}) async {
    await _log('theme_changed', {'theme_name': themeName});
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  Future<void> logSoundToggled({required bool enabled}) async {
    await _log('sound_toggled', {'enabled': enabled ? 'on' : 'off'});
  }

  Future<void> logVibrationToggled({required bool enabled}) async {
    await _log('vibration_toggled', {'enabled': enabled ? 'on' : 'off'});
  }

  Future<void> logAiCoachToggled({required bool enabled}) async {
    await _log('ai_coach_toggled', {'enabled': enabled ? 'on' : 'off'});
  }

  // ─── Gemini AI Coach ──────────────────────────────────────────────────────

  Future<void> logAiCoachRequested({required String mode, required String type}) async {
    await _log('ai_coach_requested', {'mode': mode, 'coach_type': type});
  }

  Future<void> logAiCoachSuccess({required String mode, required String type}) async {
    await _log('ai_coach_success', {'mode': mode, 'coach_type': type});
  }

  Future<void> logAiCoachFailed({
    required String mode,
    required String type,
    required String error,
  }) async {
    await _log('ai_coach_failed', {
      'mode': mode,
      'coach_type': type,
      'error': error.length > 100 ? error.substring(0, 100) : error,
    });
  }

  /// Fires a test event — use with Firebase DebugView (see scripts/enable_firebase_debug.sh).
  Future<void> logDebugTestEvent() async {
    await _log('debug_test_ping', {
      'source': 'settings',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static int highestTileOnBoard(List<int> board) {
    return board.fold(0, (max, v) => v > max ? v : max);
  }

  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    if (!isEnabled) return;
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e, st) {
      await _crashlytics.recordError(e, st, reason: 'analytics_log_$name');
    }
  }
}
