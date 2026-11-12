import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Each disc's "home": its formation spot, moved with the ball and shaped
/// by the game plan. This is the layer that keeps the team's shape.
///
/// With the ball (attack shape): higher and wider.
/// Without it (defence shape): the whole block slides with the ball, the
/// back line steps up or drops as one (line height), and the team squeezes
/// short and narrow toward the ball (compactness).
abstract final class HomeSpots {
  static void compute(
    TeamView v,
    FormationSpot spot,
    TeamPlan plan,
    Vec2 out,
  ) {
    final ourBall = v.weHaveBall ||
        (v.looseBall && v.s.ball.lastTouchSide == v.team.side);
    final x = ourBall ? _attackX(v, spot, plan) : _defendX(v, spot, plan);
    final y = ourBall ? _attackY(v, spot, plan) : _defendY(v, spot, plan);
    out.set(v.clampX(v.worldX(x), 1.5), v.clampY(y, 1.2));
  }

  // ── With the ball ─────────────────────────────────────────────────────
  static double _attackX(TeamView v, FormationSpot spot, TeamPlan plan) {
    final hl = v.halfL;
    // Shape stretched over ~70 % of the length, pushed up with the ball.
    var x = spot.ax * hl * 0.7 + v.ballX * 0.35 + 0.08 * hl;
    if (plan.attack == AttackStyle.direct) x += 0.06 * hl;
    // Stay onside while holding position (runs in behind are separate).
    if (v.offsideOn && spot.ax > 0.0 && x > v.offsideLine - 0.5) {
      x = v.offsideLine - 0.5;
    }
    return clampD(x, -hl * 0.85, hl * 0.82);
  }

  static double _attackY(TeamView v, FormationSpot spot, TeamPlan plan) {
    final hw = v.halfW;
    var y = spot.ay * hw * (0.6 + 0.32 * plan.width) + v.ballY * 0.15;
    if (plan.attack == AttackStyle.overload) {
      // Bodies to the ball side for combinations.
      y += (v.ballY - y) * 0.35;
    }
    return y;
  }

  // ── Without the ball ──────────────────────────────────────────────────
  static double _defendX(TeamView v, FormationSpot spot, TeamPlan plan) {
    final hl = v.halfL;
    // Where the block sits: deep for a low block, up for a high line.
    final blockBase = (-0.45 + 0.5 * plan.lineHeight) * hl;
    // Compact teams are shorter from back line to front.
    final depth = (0.6 - 0.25 * plan.compactness) * hl;
    var x = blockBase + (spot.dx + 0.5) * depth + v.ballX * 0.35;
    // Defenders and midfielders stay goal-side of the ball; forwards may
    // stand level with it to start the press.
    if (spot.dx < -0.2 && x > v.ballX - 2.0) x = v.ballX - 2.0;
    return clampD(x, -hl * 0.86, hl * 0.6);
  }

  static double _defendY(TeamView v, FormationSpot spot, TeamPlan plan) {
    final hw = v.halfW;
    final narrow = 0.75 - 0.3 * plan.compactness;
    final shift = 0.2 + 0.3 * plan.compactness;
    return spot.dy * hw * narrow + v.ballY * shift;
  }
}
