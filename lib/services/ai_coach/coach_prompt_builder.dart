/// Builds prompts sent to Gemini (post-game review only).
class CoachPromptBuilder {
  static String boardToText(List<int> board) {
    final lines = <String>[];
    for (var r = 0; r < 4; r++) {
      final row = board.sublist(r * 4, r * 4 + 4).map((v) => v == 0 ? '.' : '$v').join(' ');
      lines.add(row);
    }
    return lines.join('\n');
  }

  static String postGameReviewPrompt({
    required List<int> board,
    required int score,
    required String mode,
    required bool won,
  }) {
    return '''
2048 coach. Game ended. Score $score. ${won ? 'Won' : 'Lost'}. Mode: $mode.
Board:
${boardToText(board)}

Reply in 3 short plain sentences (max 40 words): what went well, one mistake, one tip. No bullets.
''';
  }
}
