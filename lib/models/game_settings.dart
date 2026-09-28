enum GameMode { humanVsAi, humanVsHuman, online }
enum Difficulty { easy, medium, hard }

enum BoardOrientation { white, black }

class GameSettings {
  final GameMode mode;
  final Difficulty difficulty;
  final BoardOrientation orientation;

  const GameSettings({
    this.mode = GameMode.humanVsAi,
    this.difficulty = Difficulty.medium,
    this.orientation = BoardOrientation.white,
  });

  GameSettings copyWith({
    GameMode? mode,
    Difficulty? difficulty,
    BoardOrientation? orientation,
  }) {
    return GameSettings(
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      orientation: orientation ?? this.orientation,
    );
  }
}
