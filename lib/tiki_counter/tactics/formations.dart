import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/tactics/formation.dart';

/// Built-in formations. Milestone 4 adds more (and the shape screen lets
/// players pick); for now each mode has one default.
abstract final class Formations {
  /// 5v5: keeper + 2-1-1.
  static const Formation fiveA211 = Formation(
    name: '2-1-1',
    kickOffSlot: 4,
    spots: [
      FormationSpot(-0.92, 0.0, Role.keeper, 1),
      FormationSpot(-0.50, -0.45, Role.defender, 2),
      FormationSpot(-0.50, 0.45, Role.defender, 3),
      FormationSpot(-0.05, 0.0, Role.midfielder, 8),
      FormationSpot(0.45, 0.0, Role.forward, 9),
    ],
  );

  /// 7v7: keeper + 2-3-1.
  static const Formation sevenA231 = Formation(
    name: '2-3-1',
    kickOffSlot: 6,
    spots: [
      FormationSpot(-0.93, 0.0, Role.keeper, 1),
      FormationSpot(-0.55, -0.40, Role.defender, 4),
      FormationSpot(-0.55, 0.40, Role.defender, 5),
      FormationSpot(-0.10, -0.62, Role.midfielder, 7),
      FormationSpot(-0.15, 0.0, Role.midfielder, 8),
      FormationSpot(-0.10, 0.62, Role.midfielder, 11),
      FormationSpot(0.40, 0.0, Role.forward, 9),
    ],
  );

  static Formation defaultFor(GameMode mode) =>
      mode == GameMode.fiveASide ? fiveA211 : sevenA231;
}
