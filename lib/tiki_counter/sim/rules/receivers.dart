import 'dart:math' as math;

import 'package:b_ball/tiki_counter/core/geometry.dart';
import 'package:b_ball/tiki_counter/core/vec2.dart';
import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';

/// Questions about teammates and opponents that passing, bots and the
/// brain all ask: "who's in that direction?", "is that lane open?",
/// "how close is the nearest opponent?".
abstract final class Receivers {
  /// Best teammate roughly in the aim direction, or null.
  /// Lower score wins: small angle, short distance, open lane.
  static Disc? inDirection(
    MatchState s,
    Disc passer,
    double ax,
    double ay,
    double coneDeg,
  ) {
    final team = s.team(passer.side);
    final opp = s.team(passer.side.other);
    final cone = coneDeg * degToRad;
    Disc? best;
    var bestScore = double.infinity;
    for (final m in team.discs) {
      if (m.id == passer.id) continue;
      final dx = m.pos.x - passer.pos.x;
      final dy = m.pos.y - passer.pos.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 2.5 || dist > 40.0) continue;
      final ang = angleBetween(ax, ay, dx, dy);
      if (ang > cone) continue;
      var score = ang / cone + dist / 30.0 * 0.4;
      if (laneBlocked(passer.pos, m.pos, opp)) score += 0.8;
      if (m.isKeeper) score += 0.5;
      if (score < bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  /// Best teammate to pass to with no aim (bots, auto set pieces).
  /// Higher score wins: forward progress, space around them, open lane.
  static Disc? bestOpen(MatchState s, Disc passer) {
    final team = s.team(passer.side);
    final opp = s.team(passer.side.other);
    final dir = passer.side.attackDir;
    Disc? best;
    var bestScore = -double.infinity;
    for (final m in team.discs) {
      if (m.id == passer.id) continue;
      final dist = passer.pos.distTo(m.pos);
      if (dist < 3.0 || dist > 28.0) continue;
      final progress = (m.pos.x - passer.pos.x) * dir;
      final space = math.min(6.0, nearestOpponentDist(opp, m.pos));
      var score = progress * 0.15 + space * 0.5;
      if (laneBlocked(passer.pos, m.pos, opp)) score -= 3.0;
      if (m.isKeeper) score -= 2.0;
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  /// True when an opponent stands within 1 m of the line between a and b.
  static bool laneBlocked(Vec2 a, Vec2 b, TeamState opp) {
    for (final o in opp.discs) {
      final t = projectOnSegment(o.pos.x, o.pos.y, a.x, a.y, b.x, b.y);
      if (t < 0.1 || t > 0.95) continue;
      final d2 = pointSegmentDist2(o.pos.x, o.pos.y, a.x, a.y, b.x, b.y);
      if (d2 < 1.0) return true;
    }
    return false;
  }

  static double nearestOpponentDist(TeamState opp, Vec2 p) {
    var best = double.infinity;
    for (final o in opp.discs) {
      final d = o.pos.distTo(p);
      if (d < best) best = d;
    }
    return best;
  }
}
