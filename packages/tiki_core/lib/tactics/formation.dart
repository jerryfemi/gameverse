import 'package:tiki_core/tactics/position.dart';

/// One spot in a formation, in **team coordinates**:
/// - `x`: −1 = own goal line, 0 = halfway, +1 = opponent goal line.
/// - `y`: −1 = top touchline, +1 = bottom touchline.
///
/// Every spot has two places: where the disc stands **with the ball**
/// (attack shape) and **without it** (defence shape). Team coordinates mean
/// the same formation works for both sides and both halves.
class FormationSpot {
  final Position position;
  final int number;
  final double ax;
  final double ay;
  final double dx;
  final double dy;

  const FormationSpot(
    this.position,
    this.number, {
    required this.ax,
    required this.ay,
    required this.dx,
    required this.dy,
  });
}

class Formation {
  /// Shown in menus, e.g. "2-1-1".
  final String name;

  /// One line on how it plays.
  final String blurb;

  /// First spot is always the keeper.
  final List<FormationSpot> spots;

  /// Slot of the disc that takes kick-offs.
  final int kickOffSlot;

  const Formation({
    required this.name,
    required this.blurb,
    required this.spots,
    required this.kickOffSlot,
  });
}
