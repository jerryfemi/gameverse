import 'dart:math' as math;

import 'package:tiki_core/brain/home_spots.dart';
import 'package:tiki_core/brain/keeper.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/sim/rules/ball_control.dart';

/// Puts a match into a chosen moment without playing up to it: both teams
/// on their shape for where the ball is, one disc on the ball. Used by the
/// game plan boards, the Lab (patterns, scenarios) and the drills.
abstract final class Staging {
  /// Everyone on their home spot for a moment where [had] has the ball at
  /// (bx, by). Keepers go in their goal.
  static void shape(MatchState s, Side had, double bx, double by) {
    final holder = nearestOrFirst(s, had, bx, by);
    BallControl.give(s, holder);
    s.ball.pos.set(bx, by);
    final spots = <Disc, Vec2>{};
    for (final team in [s.home, s.away]) {
      final weHave = team.side == had;
      final v = TeamView.build(
        s,
        team.side,
        weHave ? Phase.attacking : Phase.defending,
      );
      for (final d in team.discs) {
        final out = Vec2();
        if (d.isKeeper) {
          Keeper.place(v, d, team.plan.lineHeight);
          out.setFrom(d.target);
        } else {
          HomeSpots.compute(v, team.formation.spots[d.slot], team.plan, out);
        }
        spots[d] = out;
      }
    }
    spots.forEach((d, p) {
      d.pos.setFrom(p);
      d.prev.setFrom(p);
      d.vel.setZero();
      d.target.setFrom(p);
    });
  }

  /// [owner]'s best-placed disc takes the ball at (bx, by), facing the goal
  /// it attacks; overlapping discs are spread apart. Returns the carrier.
  /// [prefer] picks the carrier by position when one is close enough.
  static Disc takeBall(
    MatchState s,
    Side owner,
    double bx,
    double by, {
    bool Function(Disc d)? prefer,
  }) {
    var carrier = nearestOrFirst(s, owner, bx, by);
    if (prefer != null) {
      final p = nearest(s, owner, bx, by, where: prefer, maxDist: 14.0);
      if (p != null) carrier = p;
    }
    carrier.pos.set(bx - 0.9 * s.dir(owner), by);
    carrier.prev.setFrom(carrier.pos);
    carrier.facing.set(s.dir(owner), 0.0);
    BallControl.give(s, carrier);
    separate(s, carrier);
    return carrier;
  }

  /// Pushes overlapping discs apart. Keepers and [fixed] stay put.
  static void separate(MatchState s, Disc fixed) {
    const minGap = 2.7; // a little more than two disc widths
    for (var pass = 0; pass < 10; pass++) {
      var moved = false;
      for (var i = 0; i < s.discs.length; i++) {
        for (var j = i + 1; j < s.discs.length; j++) {
          final a = s.discs[i];
          final b = s.discs[j];
          var dx = b.pos.x - a.pos.x;
          var dy = b.pos.y - a.pos.y;
          var d = math.sqrt(dx * dx + dy * dy);
          if (d >= minGap) continue;
          if (d < 1e-3) {
            dx = 0.0;
            dy = 1.0;
            d = 1.0;
          }
          final push = (minGap - d) / d;
          final aFixed = a.isKeeper || identical(a, fixed);
          final bFixed = b.isKeeper || identical(b, fixed);
          if (aFixed && bFixed) continue;
          final share = aFixed || bFixed ? 1.0 : 0.5;
          if (!aFixed) {
            a.pos.set(a.pos.x - dx * push * share, a.pos.y - dy * push * share);
          }
          if (!bFixed) {
            b.pos.set(b.pos.x + dx * push * share, b.pos.y + dy * push * share);
          }
          moved = true;
        }
      }
      if (!moved) break;
    }
    for (final d in s.discs) {
      d.prev.setFrom(d.pos);
      d.target.setFrom(d.pos);
    }
  }

  /// Nearest outfield disc of [side] to (x, y).
  static Disc nearestOrFirst(MatchState s, Side side, double x, double y) =>
      nearest(s, side, x, y)!;

  /// Nearest outfield disc of [side] to (x, y), optionally only those
  /// matching [where] and within [maxDist]; null if none qualifies.
  static Disc? nearest(
    MatchState s,
    Side side,
    double x,
    double y, {
    bool Function(Disc d)? where,
    double maxDist = double.infinity,
  }) {
    Disc? best;
    var bestD = maxDist * maxDist;
    for (final d in s.team(side).discs) {
      if (d.isKeeper) continue;
      if (where != null && !where(d)) continue;
      final dx = d.pos.x - x;
      final dy = d.pos.y - y;
      final d2 = dx * dx + dy * dy;
      if (d2 < bestD) {
        bestD = d2;
        best = d;
      }
    }
    return best;
  }
}
