import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/position.dart';

/// Built-in formations, per mode. Attack shape (ax, ay) is wider and higher;
/// defence shape (dx, dy) is narrower and deeper.
abstract final class Formations {
  // ── 5v5 ───────────────────────────────────────────────────────────────
  static const Formation fiveA211 = Formation(
    name: '2-1-1',
    blurb: 'Two at the back, a pivot, one up top. Solid and simple.',
    kickOffSlot: 4,
    spots: [
      FormationSpot(Position.keeper, 1, ax: -0.92, ay: 0, dx: -0.94, dy: 0),
      FormationSpot(Position.centreBack, 2, ax: -0.45, ay: -0.5, dx: -0.6, dy: -0.35),
      FormationSpot(Position.centreBack, 3, ax: -0.45, ay: 0.5, dx: -0.6, dy: 0.35),
      FormationSpot(Position.centralMid, 8, ax: 0.05, ay: 0, dx: -0.3, dy: 0),
      FormationSpot(Position.striker, 9, ax: 0.6, ay: 0, dx: 0.05, dy: 0),
    ],
  );

  static const Formation fiveA121 = Formation(
    name: '1-2-1',
    blurb: 'Diamond: one at the back, two wide, one up top. Lots of angles.',
    kickOffSlot: 4,
    spots: [
      FormationSpot(Position.keeper, 1, ax: -0.92, ay: 0, dx: -0.94, dy: 0),
      FormationSpot(Position.centreBack, 4, ax: -0.5, ay: 0, dx: -0.62, dy: 0),
      FormationSpot(Position.wideMid, 7, ax: 0.0, ay: -0.75, dx: -0.3, dy: -0.45),
      FormationSpot(Position.wideMid, 11, ax: 0.0, ay: 0.75, dx: -0.3, dy: 0.45),
      FormationSpot(Position.striker, 9, ax: 0.6, ay: 0, dx: 0.0, dy: 0),
    ],
  );

  static const Formation fiveA22 = Formation(
    name: '2-2',
    blurb: 'Square: two back, two forward. Balanced, easy to press with.',
    kickOffSlot: 3,
    spots: [
      FormationSpot(Position.keeper, 1, ax: -0.92, ay: 0, dx: -0.94, dy: 0),
      FormationSpot(Position.centreBack, 2, ax: -0.4, ay: -0.5, dx: -0.6, dy: -0.35),
      FormationSpot(Position.centreBack, 3, ax: -0.4, ay: 0.5, dx: -0.6, dy: 0.35),
      FormationSpot(Position.striker, 9, ax: 0.45, ay: -0.4, dx: -0.05, dy: -0.3),
      FormationSpot(Position.winger, 10, ax: 0.45, ay: 0.4, dx: -0.05, dy: 0.3),
    ],
  );

  // ── 7v7 ───────────────────────────────────────────────────────────────
  static const Formation sevenA231 = Formation(
    name: '2-3-1',
    blurb: 'Two centre backs, a midfield three, a lone striker.',
    kickOffSlot: 6,
    spots: [
      FormationSpot(Position.keeper, 1, ax: -0.93, ay: 0, dx: -0.95, dy: 0),
      FormationSpot(Position.centreBack, 4, ax: -0.5, ay: -0.45, dx: -0.62, dy: -0.3),
      FormationSpot(Position.centreBack, 5, ax: -0.5, ay: 0.45, dx: -0.62, dy: 0.3),
      FormationSpot(Position.wideMid, 7, ax: 0.05, ay: -0.85, dx: -0.3, dy: -0.6),
      FormationSpot(Position.holdingMid, 6, ax: -0.15, ay: 0, dx: -0.38, dy: 0),
      FormationSpot(Position.wideMid, 11, ax: 0.05, ay: 0.85, dx: -0.3, dy: 0.6),
      FormationSpot(Position.striker, 9, ax: 0.6, ay: 0, dx: 0.0, dy: 0),
    ],
  );

  static const Formation sevenA321 = Formation(
    name: '3-2-1',
    blurb: 'Back three, two in midfield, one up top. Hard to break down.',
    kickOffSlot: 6,
    spots: [
      FormationSpot(Position.keeper, 1, ax: -0.93, ay: 0, dx: -0.95, dy: 0),
      FormationSpot(Position.fullBack, 2, ax: -0.4, ay: -0.8, dx: -0.6, dy: -0.55),
      FormationSpot(Position.centreBack, 4, ax: -0.55, ay: 0, dx: -0.66, dy: 0),
      FormationSpot(Position.fullBack, 3, ax: -0.4, ay: 0.8, dx: -0.6, dy: 0.55),
      FormationSpot(Position.centralMid, 8, ax: 0.0, ay: -0.3, dx: -0.3, dy: -0.25),
      FormationSpot(Position.attackingMid, 10, ax: 0.15, ay: 0.3, dx: -0.25, dy: 0.25),
      FormationSpot(Position.striker, 9, ax: 0.6, ay: 0, dx: 0.0, dy: 0),
    ],
  );

  static const Formation sevenA2121 = Formation(
    name: '2-1-2-1',
    blurb: 'A pivot behind two inside forwards and a striker. Attack-minded.',
    kickOffSlot: 6,
    spots: [
      FormationSpot(Position.keeper, 1, ax: -0.93, ay: 0, dx: -0.95, dy: 0),
      FormationSpot(Position.centreBack, 4, ax: -0.5, ay: -0.45, dx: -0.62, dy: -0.3),
      FormationSpot(Position.centreBack, 5, ax: -0.5, ay: 0.45, dx: -0.62, dy: 0.3),
      FormationSpot(Position.holdingMid, 6, ax: -0.2, ay: 0, dx: -0.4, dy: 0),
      FormationSpot(Position.winger, 7, ax: 0.35, ay: -0.7, dx: -0.15, dy: -0.5),
      FormationSpot(Position.winger, 11, ax: 0.35, ay: 0.7, dx: -0.15, dy: 0.5),
      FormationSpot(Position.striker, 9, ax: 0.62, ay: 0, dx: 0.0, dy: 0),
    ],
  );

  static List<Formation> forMode(GameMode mode) => mode == GameMode.fiveASide
      ? const [fiveA211, fiveA121, fiveA22]
      : const [sevenA231, sevenA321, sevenA2121];

  static Formation defaultFor(GameMode mode) => forMode(mode).first;
}
