import 'dart:math';

class NicknameUtils {
  static final Random _random = Random();

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
