import 'dart:math' as math;

import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/model/team_state.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Builds a fresh match and puts teams in kick-off positions.
abstract final class MatchSetup {
  static MatchState create({
    required GameMode mode,
    required Formation homeFormation,
    required Formation awayFormation,
    TeamPlan homePlan = Presets.balanced,
    TeamPlan awayPlan = Presets.balanced,
  }) {
    final discs = <Disc>[];
    final home = _team(Side.home, homeFormation, homePlan, discs);
    final away = _team(Side.away, awayFormation, awayPlan, discs);
    final state = MatchState(mode: mode, home: home, away: away, discs: discs);
    resetShape(state, kickOffSide: Side.home);
    return state;
  }

  static TeamState _team(
    Side side,
    Formation f,
    TeamPlan plan,
    List<Disc> all,
  ) {
    final discs = <Disc>[];
    for (var i = 0; i < f.spots.length; i++) {
      final spot = f.spots[i];
      final d = Disc(
        id: all.length,
        side: side,
        number: spot.number,
        role: spot.position.role,
        slot: i,
      );
      all.add(d);
      discs.add(d);
    }
    return TeamState(
      side: side,
      formation: f,
      plan: plan,
      discs: discs,
      cursorId: discs[f.kickOffSlot].id,
    );
  }

  /// Formation spot → pitch metres for a team.
  static double worldX(MatchState s, Side side, double teamX) =>
      teamX * s.mode.halfLength * s.dir(side);

  static double worldY(MatchState s, double teamY) =>
      teamY * s.mode.halfWidth * 0.85;

  /// Where [d] stands for a kick-off taken by [kickOffSide]: its defence
  /// shape kept in its own half (and outside the circle if it isn't
  /// kicking off). Written into [out].
  static void kickOffSpot(
    MatchState s,
    Disc d, {
    required Side kickOffSide,
    required Vec2 out,
  }) {
    final team = s.team(d.side);
    final kicking = d.side == kickOffSide;
    final spot = team.formation.spots[d.slot];
    var tx = clampD(spot.dx, -0.95, -0.08);
    var ty = spot.dy;
    if (kicking && d.slot == team.formation.kickOffSlot) {
      tx = -0.5 / s.mode.halfLength; // just behind the ball
      ty = 0.0;
    }
    out.set(worldX(s, d.side, tx), worldY(s, ty));
    if (!kicking) _keepOutOfCircle(s, d.side, out);
  }

  /// Everyone to their kick-off spot, ball on the centre spot.
  static void resetShape(MatchState s, {required Side kickOffSide}) {
    for (final team in [s.home, s.away]) {
      for (final d in team.discs) {
        kickOffSpot(s, d, kickOffSide: kickOffSide, out: d.pos);
        d.prev.setFrom(d.pos);
        d.vel.setZero();
        d.desiredVel.setZero();
        d.target.setFrom(d.pos);
        d.facing.set(s.dir(team.side), 0.0);
        d.stunTimer = 0.0;
        d.tackleCooldown = 0.0;
        d.pickupCooldown = 0.0;
      }
      team.cursorId = team.discs[team.formation.kickOffSlot].id;
    }
    final b = s.ball;
    b.pos.setZero();
    b.prev.setZero();
    b.vel.setZero();
    b.z = 0.0;
    b.vz = 0.0;
    b.ownerId = -1;
    b.lastTouchId = -1;
    b.lastTouchSide = null;
    b.offsideIds.clear();
    b.missedIds.clear();
  }

  static void _keepOutOfCircle(MatchState s, Side side, Vec2 p) {
    final minR = s.mode.centreCircle + 1.0;
    final r = math.sqrt(p.x * p.x + p.y * p.y);
    if (r >= minR) return;
    // Push straight back toward own goal.
    final back = -s.dir(side);
    final needX = math.sqrt(math.max(0.0, minR * minR - p.y * p.y));
    p.x = back * needX;
  }
}
