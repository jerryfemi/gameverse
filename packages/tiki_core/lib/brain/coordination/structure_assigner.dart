import 'dart:math' as math;

import 'package:tiki_core/brain/coordination/assignments.dart';
import 'package:tiki_core/brain/home_spots.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// With the ball, a couple of players keep the team's structure instead of
/// all drifting toward the ball:
///
/// - **Rest defence**: the deepest player stays behind the ball, goal-side
///   of their most advanced forward, so losing the ball doesn't mean a
///   free run at our keeper. In 7-a-side a second one joins once the ball
///   is in their third (that's when a counter hurts most). Not needed
///   while we build up in our own third.
/// - **Far-side width**: the widest player on the side away from the ball
///   holds that touchline, so there's always a switch of play on and their
///   block can't squeeze over. Skipped by Overload (bodies to the ball)
///   and very narrow plans.
///
/// Runs before `SupportAssigner`, which only uses who is left.
abstract final class StructureAssigner {
  static final Vec2 _home = Vec2();

  static void assign(TeamView v, TeamPlan plan, Assignments a) {
    final carrier = v.carrier;
    if (!v.weHaveBall || carrier == null) return;
    final free = [
      for (final d in v.team.discs)
        if (!d.isKeeper && d.id != carrier.id && d.id != v.team.cursorId) d,
    ];
    _restDefence(v, a, free);
    _farWidth(v, plan, a, free);
  }

  static void _restDefence(TeamView v, Assignments a, List<Disc> free) {
    if (v.ballX < -0.25 * v.halfL) return; // building up: everyone offers
    final high = v.ballX > v.halfL / 3;
    final count = math.min(v.s.mode.teamSize > 5 && high ? 2 : 1, free.length);
    if (count == 0) return;
    final spots = v.team.formation.spots;
    free.sort((p, q) => spots[p.slot].ax.compareTo(spots[q.slot].ax));
    final picked = free.sublist(0, count)..sort((p, q) => p.pos.y.compareTo(q.pos.y));
    free.removeRange(0, count);

    // Their most advanced outfield player, in our team x.
    var danger = v.halfL;
    for (final o in v.opp.discs) {
      if (!o.isKeeper) danger = math.min(danger, v.teamX(o));
    }
    final line = clampD(
      math.min(v.ballX - 0.4 * v.halfL, danger - 1.5),
      -0.75 * v.halfL,
      0.2 * v.halfL,
    );
    for (var i = 0; i < count; i++) {
      final y = count == 1
          ? v.ballY * 0.4
          : (i == 0 ? -1.0 : 1.0) * v.halfW * 0.28 + v.ballY * 0.3;
      a.structure[picked[i].id] = (
        x: v.worldX(line),
        y: v.clampY(y, 2.0),
        job: 'rest defence',
      );
    }
  }

  static void _farWidth(TeamView v, TeamPlan plan, Assignments a, List<Disc> free) {
    if (plan.attack == AttackStyle.overload) return;
    if (plan.width < 0.3 && plan.attack != AttackStyle.wide) return;
    final flank = v.ballY > 0.0 ? -1.0 : 1.0; // the side away from the ball
    final spots = v.team.formation.spots;
    Disc? best;
    var bestWide = 0.15;
    for (final d in free) {
      final wide = spots[d.slot].ay * flank;
      if (wide > bestWide) {
        bestWide = wide;
        best = d;
      }
    }
    if (best == null) return;
    free.remove(best);
    HomeSpots.compute(v, spots[best.slot], plan, _home);
    final y = flank * v.halfW * math.min(0.9, 0.72 + 0.18 * plan.width);
    a.structure[best.id] = (x: _home.x, y: v.clampY(y, 1.2), job: 'hold far side');
  }
}
