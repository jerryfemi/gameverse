/// How good a bot is. Only the bot's *controlled disc* uses these; its
/// teammates run the same team brain as yours.
class BotLevel {
  final String name;

  /// Seconds between decisions (slower = easier).
  final double thinkInterval;

  /// Longest it holds the ball before passing.
  final double holdMax;

  /// Chance per second of tackling when close enough.
  final double tacklePerSecond;

  /// Delay before taking a restart.
  final double setPieceDelay;

  /// Chance per decision of shooting when in range.
  final double shootChance;

  const BotLevel({
    required this.name,
    required this.thinkInterval,
    required this.holdMax,
    required this.tacklePerSecond,
    required this.setPieceDelay,
    required this.shootChance,
  });

  static const BotLevel normal = BotLevel(
    name: 'Normal',
    thinkInterval: 0.12,
    holdMax: 1.3,
    tacklePerSecond: 1.2,
    setPieceDelay: 0.9,
    shootChance: 0.18,
  );
}
