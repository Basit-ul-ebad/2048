/// Single-player game variants.
enum SinglePlayerMode {
  classic('Classic', 'Infinite play • counts on leaderboard'),
  time60('60 Second', 'Score as high as you can in 60s'),
  time90('90 Second', 'Score as high as you can in 90s'),
  time120('120 Second', 'Score as high as you can in 120s'),
  scoreTarget('Score Rush', 'Reach 2,048 before time runs out');

  const SinglePlayerMode(this.title, this.subtitle);

  final String title;
  final String subtitle;

  bool get isClassic => this == SinglePlayerMode.classic;
  bool get hasTimer => this != SinglePlayerMode.classic;

  int? get timeLimitSeconds => switch (this) {
        SinglePlayerMode.time60 => 60,
        SinglePlayerMode.time90 => 90,
        SinglePlayerMode.time120 => 120,
        SinglePlayerMode.scoreTarget => 180,
        _ => null,
      };

  int? get targetScore => this == SinglePlayerMode.scoreTarget ? 2048 : null;
}
