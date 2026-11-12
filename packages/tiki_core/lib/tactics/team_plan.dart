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

  /// A copy with some choices changed. Changing anything but [name] usually
  /// means the plan is now "Custom" — the caller decides the name.
  TeamPlan copyWith({
    String? name,
    AttackStyle? attack,
    AfterWin? afterWin,
    AfterLoss? afterLoss,
    Marking? marking,
    double? lineHeight,
    double? compactness,
    double? width,
    double? pressIntensity,
  }) {
    return TeamPlan(
      name: name ?? this.name,
      attack: attack ?? this.attack,
      afterWin: afterWin ?? this.afterWin,
      afterLoss: afterLoss ?? this.afterLoss,
      marking: marking ?? this.marking,
      lineHeight: lineHeight ?? this.lineHeight,
      compactness: compactness ?? this.compactness,
      width: width ?? this.width,
      pressIntensity: pressIntensity ?? this.pressIntensity,
    );
  }

  /// Plain map for saving (shared preferences, later online).
  Map<String, Object> toJson() => {
    'name': name,
    'attack': attack.name,
    'afterWin': afterWin.name,
    'afterLoss': afterLoss.name,
    'marking': marking.name,
    'lineHeight': lineHeight,
    'compactness': compactness,
    'width': width,
    'pressIntensity': pressIntensity,
  };

  /// Reads [toJson]'s map; anything missing or unknown falls back to the
  /// defaults, so old saves never crash.
  factory TeamPlan.fromJson(Map<String, Object?> j) {
    T pick<T extends Enum>(List<T> values, Object? v, T fallback) {
      for (final e in values) {
        if (e.name == v) return e;
      }
      return fallback;
    }

    double num01(Object? v, double fallback) {
      if (v is! num) return fallback;
      final d = v.toDouble();
      return d < 0.0 ? 0.0 : (d > 1.0 ? 1.0 : d);
    }

    return TeamPlan(
      name: j['name'] is String ? j['name']! as String : 'Custom',
      attack: pick(AttackStyle.values, j['attack'], AttackStyle.possession),
      afterWin: pick(AfterWin.values, j['afterWin'], AfterWin.keep),
      afterLoss: pick(AfterLoss.values, j['afterLoss'], AfterLoss.dropIntoShape),
      marking: pick(Marking.values, j['marking'], Marking.zonal),
      lineHeight: num01(j['lineHeight'], 0.5),
      compactness: num01(j['compactness'], 0.5),
      width: num01(j['width'], 0.6),
      pressIntensity: num01(j['pressIntensity'], 0.5),
    );
  }
}
