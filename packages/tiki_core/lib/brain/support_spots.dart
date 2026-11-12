import 'dart:math' as math;

import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';

/// "Come and offer a pass": when we have the ball, the two nearest
/// teammates move to open spots around the carrier.
///
/// **Simple version** so the first playable has someone to pass to.
/// Milestone 5 replaces it with scored support behaviours (triangles,
/// third-man runs, runs in behind).
abstract final class SupportSpots {
  /// Angles (degrees) around the carrier, measured from the direction of
  /// attack: two ahead-wide, two square, two behind.
  static const List<double> _angles = [35, -35, 95, -95, 155, -155];

  /// How many teammates come to support.
  static const int supporters = 2;

  /// Sends supporters to open spots. Returns their ids (empty if none).
  static List<int> assign(MatchState s, TeamState team, Disc carrier) {
    final m = s.mode;
    final dir = team.side.attackDir;
    final dist = m.length < 50.0 ? 7.0 : 9.0;
    final opp = s.team(team.side.other);

    // Score each candidate spot: open space, a clear lane, a bit of progress.
    final spots = <({double x, double y, double score})>[];
    for (final deg in _angles) {
      final a = deg * degToRad;
      final x = carrier.pos.x + math.cos(a) * dir * dist;
      final y = carrier.pos.y + math.sin(a) * dist;
      if (x.abs() > m.halfLength - 1.5 || y.abs() > m.halfWidth - 1.0) continue;
      var nearest = double.infinity;
      for (final o in opp.discs) {
        final dx = o.pos.x - x;
        final dy = o.pos.y - y;
        nearest = math.min(nearest, math.sqrt(dx * dx + dy * dy));
      }
      var score = math.min(nearest, 6.0) + (x - carrier.pos.x) * dir * 0.12;
      if (_laneBlocked(carrier, x, y, opp)) score -= 4.0;
      spots.add((x: x, y: y, score: score));
    }
    spots.sort((p, q) => q.score.compareTo(p.score));

    // Give the best spots to the nearest free outfield teammates.
    final used = <int>[];
    for (final spot in spots) {
      if (used.length >= supporters) break;
      Disc? pick;
      var pickD = double.infinity;
      for (final d in team.discs) {
        if (d.isKeeper || d.id == carrier.id || used.contains(d.id)) continue;
        final dx = d.pos.x - spot.x;
        final dy = d.pos.y - spot.y;
        final dd = math.sqrt(dx * dx + dy * dy);
        if (dd < pickD) {
          pickD = dd;
          pick = d;
        }
      }
      if (pick == null) break;
      pick.target.set(spot.x, spot.y);
      pick.urgency = pickD > 4.0 ? 1.2 : 0.8;
      pick.job = 'support';
      used.add(pick.id);
    }
    return used;
  }

  static bool _laneBlocked(Disc c, double x, double y, TeamState opp) {
    for (final o in opp.discs) {
      final t = projectOnSegment(o.pos.x, o.pos.y, c.pos.x, c.pos.y, x, y);
      if (t < 0.1 || t > 0.95) continue;
      if (pointSegmentDist2(o.pos.x, o.pos.y, c.pos.x, c.pos.y, x, y) < 1.0) {
        return true;
      }
    }
    return false;
  }
}
