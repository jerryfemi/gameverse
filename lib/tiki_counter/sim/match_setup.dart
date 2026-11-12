import 'dart:math' as math;

import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/side.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';
import 'package:b_ball/tiki_counter/tactics/formation.dart';

/// Builds a fresh match and puts teams in kick-off positions.
abstract final class MatchSetup {
  static MatchState create({
    required GameMode mode,
    required Formation homeFormation,
    required Formation awayFormation,
  }) {
    final discs = <Disc>[];
    final home = _team(Side.home, homeFormation, discs);
    final away = _team(Side.away, awayFormation, discs);
    final state = MatchState(mode: mode, home: home, away: away, discs: discs);
    resetShape(state, kickOffSide: Side.home);
    return state;
  }

  static TeamState _team(Side side, Formation f, List<Disc> all) {
    final discs = <Disc>[];
    for (var i = 0; i < f.spots.length; i++) {
      final spot = f.spots[i];
      final d = Disc(
        id: all.length,
        side: side,
        number: spot.number,
        role: spot.role,
        slot: i,
      );
      all.add(d);
      discs.add(d);
    }
    return TeamState(
      side: side,
      formation: f,
      discs: discs,
      cursorId: discs[f.kickOffSlot].id,
    );
  }

  /// Formation spot → pitch metres for a team.
  static double worldX(MatchState s, Side side, double teamX) =>
      teamX * s.mode.halfLength * side.attackDir;

  static double worldY(MatchState s, double teamY) =>
      teamY * s.mode.halfWidth * 0.85;

  /// Everyone back to their own half, ball on the centre spot.
  static void resetShape(MatchState s, {required Side kickOffSide}) {
    for (final team in [s.home, s.away]) {
      final kicking = team.side == kickOffSide;
      for (final d in team.discs) {
        final spot = team.formation.spots[d.slot];
        // Squeeze the shape into the own half.
        var tx = -1.0 + (spot.x + 1.0) * 0.48;
        var ty = spot.y;
        if (kicking && d.slot == team.formation.kickOffSlot) {
          tx = -0.5 / s.mode.halfLength; // just behind the ball
          ty = 0.0;
        }
        d.pos.set(worldX(s, team.side, tx), worldY(s, ty));
        if (!kicking) _keepOutOfCircle(s, d);
        d.prev.setFrom(d.pos);
        d.vel.setZero();
        d.desiredVel.setZero();
        d.target.setFrom(d.pos);
        d.facing.set(team.side.attackDir, 0.0);
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

  static void _keepOutOfCircle(MatchState s, Disc d) {
    final minR = s.mode.centreCircle + 1.0;
    final r = math.sqrt(d.pos.x * d.pos.x + d.pos.y * d.pos.y);
    if (r >= minR) return;
    // Push straight back toward own goal.
    final back = -d.side.attackDir;
    final needX = math.sqrt(math.max(0.0, minR * minR - d.pos.y * d.pos.y));
    d.pos.x = back * needX;
  }
}
