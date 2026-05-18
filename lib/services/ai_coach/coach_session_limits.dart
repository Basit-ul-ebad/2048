/// Per-game limits for AI Coach requests (avoids spam and API cost).
class CoachSessionLimits {
  static const int maxHintsPerGame = 3;
  static const Duration cooldown = Duration(seconds: 10);

  int hintsUsed = 0;
  DateTime? lastHintAt;
  String? lastReviewText;

  bool get canRequestHint =>
      hintsUsed < maxHintsPerGame &&
      (lastHintAt == null || DateTime.now().difference(lastHintAt!) >= cooldown);

  int? get cooldownSecondsRemaining {
    if (lastHintAt == null) return null;
    final elapsed = DateTime.now().difference(lastHintAt!);
    if (elapsed >= cooldown) return null;
    return (cooldown - elapsed).inSeconds + 1;
  }

  int get hintsRemaining => (maxHintsPerGame - hintsUsed).clamp(0, maxHintsPerGame);

  void recordHint() {
    hintsUsed++;
    lastHintAt = DateTime.now();
  }

  void reset() {
    hintsUsed = 0;
    lastHintAt = null;
    lastReviewText = null;
  }
}
