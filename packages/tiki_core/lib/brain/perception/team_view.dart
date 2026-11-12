import 'dart:math' as math;

import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/model/team_state.dart';

/// Everything one team's brain needs to know this tick, worked out once and
/// shared by every disc's behaviours.
///
/// "Team x" means distance toward the goal we attack: −halfLength at our
/// goal line, +halfLength at theirs. It's the same for both teams and both
/// halves, so behaviours never worry about left/right.
class TeamView {
  final MatchState s;
  final TeamState team;
  final TeamState opp;
  final Phase phase;

  /// +1 or −1: multiply world x by this to get team x.
  final double dir;
  final double halfL;
  final double halfW;

  /// Carrier (either team) or null.
  final Disc? carrier;
  final bool weHaveBall;
  final bool theyHaveBall;

  /// Ball position in team coordinates.
  final double ballX;
  final double ballY;

  /// Their offside line in team x (second-last defender, at least halfway
  /// and the ball). Offside-safe runs start behind this.
  final double offsideLine;

  /// Our deepest outfield disc in team x.
  final double ourLine;

  TeamView._(
    this.s,
    this.team,
    this.opp,
    this.phase,
    this.dir,
    this.carrier,
    this.weHaveBall,
    this.theyHaveBall,
    this.ballX,
    this.ballY,
    this.offsideLine,
    this.ourLine,
  ) : halfL = s.mode.halfLength,
      halfW = s.mode.halfWidth;

  factory TeamView.build(MatchState s, Side side, Phase phase) {
    final team = s.team(side);
    final opp = s.team(side.other);
    final dir = s.dir(side);
    final carrier = s.owner;
    final ballX = s.ball.pos.x * dir;

    var first = -double.infinity;
    var second = -double.infinity;
    for (final o in opp.discs) {
      final v = o.pos.x * dir;
      if (v > first) {
        second = first;
        first = v;
      } else if (v > second) {
        second = v;
      }
    }
    final offside = math.max(second, math.max(0.0, ballX));

    var ourLine = double.infinity;
    for (final d in team.discs) {
      if (!d.isKeeper) ourLine = math.min(ourLine, d.pos.x * dir);
    }

    return TeamView._(
      s,
      team,
      opp,
      phase,
      dir,
      carrier,
      carrier != null && carrier.side == side,
      carrier != null && carrier.side != side,
      ballX,
      s.ball.pos.y,
      offside,
      ourLine,
    );
  }

  bool get looseBall => carrier == null;
  bool get offsideOn => s.mode.offside;

  double teamX(Disc d) => d.pos.x * dir;
  double worldX(double teamX) => teamX * dir;

  /// Distance from a world point to the nearest opponent.
  double space(double wx, double wy) {
    var best = double.infinity;
    for (final o in opp.discs) {
      final dx = o.pos.x - wx;
      final dy = o.pos.y - wy;
      best = math.min(best, math.sqrt(dx * dx + dy * dy));
    }
    return best;
  }

  /// No opponent within 1 m of the line from (ax, ay) to (bx, by).
  bool laneOpen(double ax, double ay, double bx, double by) {
    for (final o in opp.discs) {
      final t = projectOnSegment(o.pos.x, o.pos.y, ax, ay, bx, by);
      if (t < 0.08 || t > 0.95) continue;
      if (pointSegmentDist2(o.pos.x, o.pos.y, ax, ay, bx, by) < 1.0) {
        return false;
      }
    }
    return true;
  }

  /// Keeps a world point inside the pitch with a margin.
  double clampX(double wx, [double margin = 1.0]) =>
      clampD(wx, -halfL + margin, halfL - margin);
  double clampY(double wy, [double margin = 1.0]) =>
      clampD(wy, -halfW + margin, halfW - margin);
}
