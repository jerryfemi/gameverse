import 'package:b_ball/tiki_counter/model/disc.dart';

/// One spot in a formation, in **team coordinates**:
/// - `x`: −1 = own goal line, 0 = halfway, +1 = opponent goal line.
/// - `y`: −1 = top touchline, +1 = bottom touchline.
///
/// Team coordinates mean the same formation works for both sides; the
/// setup flips x for the away team.
class FormationSpot {
  final double x;
  final double y;
  final Role role;
  final int number;

  const FormationSpot(this.x, this.y, this.role, this.number);
}

class Formation {
  final String name;

  /// First spot is always the keeper.
  final List<FormationSpot> spots;

  /// Slot of the disc that takes kick-offs.
  final int kickOffSlot;

  const Formation({
    required this.name,
    required this.spots,
    required this.kickOffSlot,
  });
}
