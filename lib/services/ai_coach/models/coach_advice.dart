/// Coach hint for the current board — built locally (instant, no API).
class CoachAdvice {
  final String? move; // left, right, up, down
  final String headline;
  final String what;
  final String why;
  /// Board cells (0–15) involved in the main merge or slide.
  final List<int> highlightIndices;

  const CoachAdvice({
    this.move,
    required this.headline,
    required this.what,
    required this.why,
    this.highlightIndices = const [],
  });

  bool get hasMove => move != null && move!.isNotEmpty;

  /// Legacy single-line tip.
  String get tip => what;
}
