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

  /// Chance per decision of shooting from a decent position.
  final double shootChance;

  /// Chance of picking the second-best pass instead of the best.
  final double decisionNoise;

  /// Extra random error on its aim, in degrees.
  final double aimNoiseDeg;

  const BotLevel({
    required this.name,
    required this.thinkInterval,
    required this.holdMax,
    required this.tacklePerSecond,
    required this.setPieceDelay,
    required this.shootChance,
    required this.decisionNoise,
    required this.aimNoiseDeg,
  });

  static const BotLevel easy = BotLevel(
    name: 'Easy',
    thinkInterval: 0.4,
    holdMax: 2.6,
    tacklePerSecond: 0.5,
    setPieceDelay: 1.2,
    shootChance: 0.12,
    decisionNoise: 0.35,
    aimNoiseDeg: 9.0,
  );

  static const BotLevel normal = BotLevel(
    name: 'Normal',
    thinkInterval: 0.12,
    holdMax: 2.0,
    tacklePerSecond: 1.2,
    setPieceDelay: 0.9,
    shootChance: 0.2,
    decisionNoise: 0.15,
    aimNoiseDeg: 5.0,
  );

  static const BotLevel hard = BotLevel(
    name: 'Hard',
    thinkInterval: 0.07,
    holdMax: 1.5,
    tacklePerSecond: 1.8,
    setPieceDelay: 0.6,
    shootChance: 0.28,
    decisionNoise: 0.03,
    aimNoiseDeg: 0.0,
  );

  static const List<BotLevel> all = [easy, normal, hard];
}
