/// Game mode values for analytics [mode] parameter.
abstract final class AnalyticsModes {
  static const String singlePlayer = 'single_player';
  static const String ai = 'ai';
  static const String localMultiplayer = 'local_multiplayer';
  static const String quickMatch = 'quick_match';
  static const String party = 'party';
  static const String timedLocal = 'timed_local';
}

/// Tile milestone values for [tile_achieved] events.
abstract final class AnalyticsTileMilestones {
  static const milestones = [128, 256, 512, 1024, 2048];
}

abstract final class AnalyticsLoginMethods {
  static const String email = 'email';
  static const String google = 'google';
}
