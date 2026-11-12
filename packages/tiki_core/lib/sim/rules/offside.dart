import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_state.dart';

/// Offside (7v7 only), judged **at the moment of the pass**.
///
/// An attacker is offside if, when the ball is played, they are:
/// in the opponent's half, ahead of the ball, and ahead of the
/// second-last defender (the keeper usually counts as the last one).
///
/// We only remember *who was offside* here. The call happens later, if one
/// of them is the first to touch the ball (see `possession.dart`).
abstract final class Offside {
  static void snapshot(MatchState s, Disc passer, Set<int> out) {
    out.clear();
    final dir = s.dir(passer.side);

    // Two deepest defenders, measured in the attacking direction.
    var first = -double.infinity;
    var second = -double.infinity;
    for (final o in s.team(passer.side.other).discs) {
      final v = o.pos.x * dir;
      if (v > first) {
        second = first;
        first = v;
      } else if (v > second) {
        second = v;
      }
    }

    final ballV = s.ball.pos.x * dir;
    for (final m in s.team(passer.side).discs) {
      if (m.id == passer.id) continue;
      final v = m.pos.x * dir;
      if (v > 0.0 && v > ballV && v > second) out.add(m.id);
    }
  }
}
