/// The game plan, organised by the four phases of play (like eFootball's
/// team playstyles, but each phase is chosen separately).

/// With the ball.
enum AttackStyle {
  /// Tight support, short passes, few runs in behind.
  possession,

  /// Early runs in behind, through balls.
  direct,

  /// Extra bodies to the ball side, short combinations.
  overload,

  /// Stretch the pitch, hold the touchlines.
  wide,
}

/// Right after winning the ball.
enum AfterWin {
  /// Keep it: close support first.
  keep,

  /// Forwards sprint in behind at once.
  counter,
}

/// Right after losing the ball.
enum AfterLoss {
  /// The nearest two or three sprint at the ball.
  counterPress,

  /// Everyone runs back into shape.
  dropIntoShape,
}

enum Marking {
  /// Guard spaces: each disc holds its home spot and steps to the ball.
  zonal,

  /// Each outfield disc follows an opponent.
  man,
}

/// Every number is 0..1 so presets and (later) sliders stay simple.
class TeamPlan {
  final String name;

  final AttackStyle attack;
  final AfterWin afterWin;
  final AfterLoss afterLoss;
  final Marking marking;

  /// 0 = low block (deep), 1 = high line (squeeze up).
  final double lineHeight;

  /// 0 = spread out, 1 = very compact (short and narrow).
  final double compactness;

  /// How wide the attack shape is, 0..1.
  final double width;

  /// 0 = never press, 1 = press everything, everywhere.
  final double pressIntensity;

  const TeamPlan({
    required this.name,
    this.attack = AttackStyle.possession,
    this.afterWin = AfterWin.keep,
    this.afterLoss = AfterLoss.dropIntoShape,
    this.marking = Marking.zonal,
    this.lineHeight = 0.5,
    this.compactness = 0.5,
    this.width = 0.6,
    this.pressIntensity = 0.5,
  });
}
