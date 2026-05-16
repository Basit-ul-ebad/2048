import 'dart:math';

class NicknameUtils {
  static final Random _random = Random();

  /// First letter for avatars; safe for null/empty strings.
  static String initial(String? text, {String fallback = '?'}) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed.substring(0, 1).toUpperCase();
  }

  /// Display name with fallbacks when Firestore nickname is missing.
  static String displayName(String? nickname, {String? email, String fallback = 'Player'}) {
    final n = nickname?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email?.trim();
    if (e != null && e.contains('@')) {
      final local = e.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return fallback;
  }

  /// Suggests alternative nicknames when the requested one is taken
  static List<String> suggestAlternatives(String baseName) {
    return [
      '$baseName${_random.nextInt(9999)}',
      'Real$baseName',
      '${baseName}2048',
    ];
  }

  /// Basic validation for nickname
  static bool isValidNickname(String nickname) {
    if (nickname.isEmpty || nickname.length < 3 || nickname.length > 15) {
      return false;
    }
    // Only alphanumeric and underscores
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(nickname);
  }
}
