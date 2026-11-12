import 'dart:math' as math;

import 'package:tiki_core/brain/coordination/assignments.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Picks open spots around the carrier and hands each to the nearest free
/// teammate (support triangles). How many depends on the attack style.
abstract final class SupportAssigner {
  /// Angles (degrees) around the carrier, measured from the attack
  /// direction: two ahead-wide, two square, two behind.
  static const List<double> _angles = [35, -35, 95, -95, 155, -155];

  static void assign(TeamView v, TeamPlan plan, Assignments a) {
    final carrier = v.carrier;
    if (!v.weHaveBall || carrier == null) return;
    final count = switch (plan.attack) {
      AttackStyle.possession => 2,
      AttackStyle.overload => 3,
      AttackStyle.wide => 2,
      AttackStyle.direct => 1,
    };
    final dist = v.halfL < 25.0 ? 7.0 : 9.0;

    final spots = <({double x, double y, double score})>[];
    for (final deg in _angles) {
      final ang = deg * degToRad;
      final x = carrier.pos.x + math.cos(ang) * v.dir * dist;
      final y = carrier.pos.y + math.sin(ang) * dist;
      if (x.abs() > v.halfL - 1.5 || y.abs() > v.halfW - 1.0) continue;
      var score = math.min(v.space(x, y), 6.0) +
          (x - carrier.pos.x) * v.dir * 0.12;
      if (!v.laneOpen(carrier.pos.x, carrier.pos.y, x, y)) score -= 4.0;
      spots.add((x: x, y: y, score: score));
    }
    spots.sort((p, q) => q.score.compareTo(p.score));

    for (final spot in spots) {
      if (a.support.length >= count) break;
      final pick = _nearestFree(v, a, carrier, spot.x, spot.y);
      if (pick == null) break;
      a.support[pick.id] = (x: spot.x, y: spot.y);
    }
  }

  static Disc? _nearestFree(
    TeamView v,
    Assignments a,
    Disc carrier,
    double x,
    double y,
  ) {
    Disc? best;
    var bestD = double.infinity;
    for (final d in v.team.discs) {
      if (d.isKeeper || d.id == carrier.id || a.support.containsKey(d.id)) {
        continue;
      }
      final dx = d.pos.x - x;
      final dy = d.pos.y - y;
      final dd = dx * dx + dy * dy;
      if (dd < bestD) {
        bestD = dd;
        best = d;
      }
    }
    return best;
  }
}
