import 'dart:math' as math;

import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/ball.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_event.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/set_piece.dart';
import 'package:tiki_core/sim/rules/ball_control.dart';
import 'package:tiki_core/sim/rules/restarts.dart';

/// Who has the ball:
/// - [carry] keeps a carried ball at the carrier's feet (a little further
///   out while dashing — it stays with him when he turns).
/// - [checkPickups] lets a disc take a loose ball: certain for slow balls
///   and teammates, a dice roll for interceptions.
class Possession {
  final Rng rng;
  final Restarts restarts;

  Possession(this.rng, this.restarts);

  void carry(MatchState s, double dt) {
    final d = s.owner;
    if (d == null) return;
    final b = s.ball;
    b.touchClock += dt;
    final dashCarry = d.dashing && d.vel.length > 2.0 && s.setPiece == null;
    BallControl.placeAtFeet(b, d, extraGap: dashCarry ? T.dashCarryGap : 0.0);
    b.vel.setFrom(d.vel);
  }

  void checkPickups(MatchState s) {
    final b = s.ball;
    if (!b.isLoose || b.z > T.reachHeight) return;
    // Once the ball has slowed to a loose ball, anyone may take it again.
    if (b.missedIds.isNotEmpty && b.speed < T.looseBallSpeed) {
      b.missedIds.clear();
    }
    // The disc whose reach the ball is deepest inside gets the first try.
    Disc? best;
    var bestFrac = 1.0;
    for (final d in s.discs) {
      if (d.pickupCooldown > 0.0 || d.stunTimer > 0.0) continue;
      if (b.missedIds.contains(d.id)) continue;
      if (_ownPassLeaving(b, d)) continue;
      final frac = d.pos.distTo(b.pos) / _reach(s, d);
      if (frac <= bestFrac) {
        bestFrac = frac;
        best = d;
      }
    }
    if (best == null) return;
    final p = _chance(s, best, bestFrac);
    if (p >= 1.0 || rng.chance(p)) {
      _collect(s, best);
    } else {
      _miss(s, best);
    }
  }

  /// How far from its centre a disc can take the ball. A keeper in his own
  /// box dives further for shots.
  double _reach(MatchState s, Disc d) {
    const normal = T.discRadius + T.ballRadius + T.reachExtra;
    final b = s.ball;
    final diving = d.isKeeper &&
        b.lastKick == ActionKind.shoot &&
        b.lastTouchSide != d.side &&
        inOwnBox(s, d);
    if (diving) return normal + T.keeperDiveReach;
    final meantForHim =
        d.id == b.intendedReceiverId && b.lastTouchSide == d.side;
    return meantForHim ? normal + T.receiverReachBonus : normal;
  }

  double _chance(MatchState s, Disc d, double distFrac) {
    final b = s.ball;
    if (b.dribbleTouch && d.id == b.lastTouchId) return 1.0;
    final speed = b.speed;
    if (speed < T.looseBallSpeed) return 1.0;
    if (d.side == b.lastTouchSide) {
      return speed < T.easyControlSpeed ? 1.0 : T.hardControlChance;
    }
    final start =
        b.lastKick == ActionKind.shoot ? T.shotBlockBase : T.interceptBase;
    final base = clampD(
      start - (speed - T.looseBallSpeed) * T.interceptSpeedFalloff,
      T.interceptMin,
      T.interceptMax,
    );
    var p = base * (1.0 - 0.5 * distFrac);
    if (d.isKeeper && inOwnBox(s, d)) p = math.max(p, T.keeperSaveChance);
    return p;
  }

  /// A passer can't "receive" his own pass while it's still travelling:
  /// a backward pass from the kick-off spot runs through his own body.
  /// Once it slows to a loose ball he may take it again.
  static bool _ownPassLeaving(Ball b, Disc d) {
    final k = b.lastKick;
    if (d.id != b.lastTouchId || k == null || b.dribbleTouch) return false;
    final passLike = k == ActionKind.pass ||
        k == ActionKind.through ||
        k == ActionKind.lob ||
        k == ActionKind.shoot;
    return passLike && b.speed > T.looseBallSpeed;
  }

  void _collect(MatchState s, Disc d) {
    final b = s.ball;
    if (s.mode.offside && b.offsideIds.contains(d.id)) {
      s.team(d.side).stats.offsides++;
      s.emit(MatchEventKind.offside, d.side, d.id);
      restarts.schedule(s, RestartKind.freeKick, d.side.other, d.pos.x, d.pos.y);
      return;
    }
    _countStats(s, d);
    BallControl.give(s, d);
  }

  void _countStats(MatchState s, Disc d) {
    final b = s.ball;
    final from = b.lastTouchSide;
    final kick = b.lastKick;
    if (from == null || kick == null || b.dribbleTouch) return;
    final isPass = kick == ActionKind.pass ||
        kick == ActionKind.through ||
        kick == ActionKind.lob;
    if (isPass) {
      if (from == d.side) {
        if (b.lastTouchId != d.id) s.team(from).stats.passesCompleted++;
      } else {
        s.team(d.side).stats.interceptions++;
        s.emit(MatchEventKind.interception, d.side, d.id);
      }
    } else if (kick == ActionKind.shoot && from != d.side) {
      if (d.isKeeper) {
        s.team(d.side).stats.saves++;
        s.team(from).stats.shotsOnTarget++;
        s.emit(MatchEventKind.save, d.side, d.id);
      } else {
        s.team(d.side).stats.interceptions++;
      }
    }
  }

  /// A failed interception: the ball clips the disc and carries on.
  void _miss(MatchState s, Disc d) {
    final b = s.ball;
    b.missedIds.add(d.id);
    if (d.side == b.lastTouchSide) return;
    b.vel.rotate(rng.bell() * T.deflectMaxDeg * degToRad);
    b.vel.scale(T.deflectKeep);
  }

  static bool inOwnBox(MatchState s, Disc d) {
    final m = s.mode;
    final depth = d.pos.x * s.dir(d.side); // −halfLength at own goal line
    return depth < -(m.halfLength - m.boxDepth) &&
        d.pos.y.abs() < m.boxWidth / 2.0;
  }
}
