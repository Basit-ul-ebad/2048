/// Online match duration options (seconds).
abstract final class MatchDurations {
  static const int short = 60;
  static const int medium = 90;
  static const int long = 120;

  static const List<int> all = [short, medium, long];

  static String label(int seconds) => switch (seconds) {
        short => '60 sec',
        medium => '90 sec',
        long => '120 sec',
        _ => '${seconds}s',
      };

  /// EXP reward for winning a timed online match.
  static int winExp(int seconds) => switch (seconds) {
        short => 80,
        medium => 100,
        long => 120,
        _ => 50,
      };

  static int lossExp(int seconds) => switch (seconds) {
        short => 40,
        medium => 50,
        long => 60,
        _ => 25,
      };
}
