import 'dart:math' as math;

import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_event.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/set_piece.dart';
import 'package:tiki_core/sim/physics/ball_physics.dart';
import 'package:tiki_core/sim/rules/aim_error.dart';
import 'package:tiki_core/sim/rules/ball_control.dart';
import 'package:tiki_core/sim/rules/offside.dart';
import 'package:tiki_core/sim/rules/receivers.dart';

/// Where a kick should go before aim error is added.
typedef _Plan = ({double tx, double ty, double speed, double vz, int receiver});

/// PASS, THROUGH, LOB and SHOOT.
///
/// Each kind works out a target point and a launch speed, then
/// [AimError] nudges it, then [BallControl.release] lets the ball go.
class Passing {
  final Rng rng;

  Passing(this.rng);

  /// Returns false if [d] doesn't have the ball.
  bool execute(
    MatchState s,
    Disc d,
    ActionKind kind,
    double aimX,
    double aimY,
    double power,
  ) {
    if (s.ball.ownerId != d.id) return false;
    final sp = s.setPiece;
    final isThrow = sp != null && sp.kind == RestartKind.throwIn;
    if (isThrow && (kind == ActionKind.lob || kind == ActionKind.shoot)) {
      kind = ActionKind.pass;
    }

    // Aim: the stick, or the way the disc faces if the stick is centred.
    var ax = aimX;
    var ay = aimY;
    final al = math.sqrt(ax * ax + ay * ay);
    if (al < T.stickDeadZone) {
      ax = d.facing.x;
      ay = d.facing.y;
    } else {
      ax /= al;
      ay /= al;
    }
    power = clampD(power, 0.0, 1.0);

    final plan = switch (kind) {
      ActionKind.pass => _pass(s, d, ax, ay, power),
      ActionKind.through => _through(s, d, ax, ay, power),
      ActionKind.lob => _lob(s, d, ax, ay, power),
      ActionKind.shoot => _shoot(s, d, ay, power),
      _ => null,
    };
    if (plan == null) return false;

    // Direction from the ball to the target, then the miss angle.
    var dx = plan.tx - s.ball.pos.x;
    var dy = plan.ty - s.ball.pos.y;
    final dl = math.sqrt(dx * dx + dy * dy);
    if (dl < 1e-6) {
      dx = ax;
      dy = ay;
    } else {
      dx /= dl;
      dy /= dl;
    }
    final err = AimError.angle(s, d, kind, rng);
    final c = math.cos(err);
    final sn = math.sin(err);
    final rx = dx * c - dy * sn;
    final ry = dx * sn + dy * c;
    var speed = plan.speed * AimError.speedFactor(rng);
    if (isThrow) speed = math.min(speed, T.throwMaxSpeed);

    BallControl.release(
      s,
      d,
      rx * speed,
      ry * speed,
      plan.vz,
      kick: kind,
      receiverId: plan.receiver,
    );

    final offsideApplies = s.mode.offside &&
        kind != ActionKind.shoot &&
        (sp == null || !sp.offsideExempt);
    if (offsideApplies) Offside.snapshot(s, d, s.ball.offsideIds);

    final stats = s.team(d.side).stats;
    if (kind == ActionKind.shoot) {
      stats.shots++;
      s.emit(MatchEventKind.shot, d.side, d.id);
    } else {
      stats.passesTried++;
      s.emit(MatchEventKind.pass, d.side, d.id);
    }
    s.setPiece = null; // a restart ends once the ball is played
    return true;
  }

  _Plan _pass(MatchState s, Disc d, double ax, double ay, double power) {
    final r = Receivers.inDirection(s, d, ax, ay, T.passConeDeg);
    if (r == null) return _space(d, ax, ay, power, T.spacePassBase);
    final tx = r.pos.x + r.vel.x * 0.35;
    final ty = r.pos.y + r.vel.y * 0.35;
    final dist = _dist(d, tx, ty);
    final roll = dist + T.passArriveExtra + power * T.passPowerExtra;
    return (
      tx: tx,
      ty: ty,
      speed: _clampSpeed(BallPhysics.speedForDistance(roll)),
      vz: 0.0,
      receiver: r.id,
    );
  }

  _Plan _through(MatchState s, Disc d, double ax, double ay, double power) {
    final r = Receivers.inDirection(s, d, ax, ay, T.throughConeDeg);
    if (r == null) return _space(d, ax, ay, power, 10.0);
    // Lead the runner: mostly toward goal, partly the way they're running.
    var lx = s.dir(d.side) * 0.6;
    var ly = 0.0;
    final rs = r.vel.length;
    if (rs > 1.0) {
      lx += r.vel.x / rs * 0.4;
      ly += r.vel.y / rs * 0.4;
    }
    final ll = math.sqrt(lx * lx + ly * ly);
    final lead = T.throughLeadBase + power * T.throughLeadPower;
    final tx = r.pos.x + lx / ll * lead;
    final ty = r.pos.y + ly / ll * lead;
    final speed = BallPhysics.speedForDistance(_dist(d, tx, ty));
    return (tx: tx, ty: ty, speed: _clampSpeed(speed), vz: 0.0, receiver: r.id);
  }

  _Plan _lob(MatchState s, Disc d, double ax, double ay, double power) {
    final r = Receivers.inDirection(s, d, ax, ay, T.throughConeDeg);
    double tx;
    double ty;
    if (r != null) {
      tx = r.pos.x + r.vel.x * 0.6;
      ty = r.pos.y + r.vel.y * 0.6;
    } else {
      final dist = 10.0 + power * T.spacePassPower;
      tx = d.pos.x + ax * dist;
      ty = d.pos.y + ay * dist;
    }
    final vz = T.lobVzBase + power * T.lobVzPower;
    final flight = 2.0 * vz / T.gravity;
    final speed = _dist(d, tx, ty) * T.lobLandFraction / flight;
    return (tx: tx, ty: ty, speed: speed, vz: vz, receiver: r?.id ?? -1);
  }

  _Plan _shoot(MatchState s, Disc d, double ay, double power) {
    final m = s.mode;
    final gx = s.dir(d.side) * m.halfLength;
    final post = m.goalWidth * 0.42;
    // Stick up/down picks the corner; centred stick goes far post.
    final gy = ay.abs() > 0.2
        ? clampD(ay * m.goalWidth * 0.6, -post, post)
        : -signD(d.pos.y) * m.goalWidth * 0.3;
    final speed = T.shootSpeedBase + power * T.shootSpeedPower;
    final vz = T.shootLiftPower * power * power;
    return (tx: gx, ty: gy, speed: speed, vz: vz, receiver: -1);
  }

  _Plan _space(Disc d, double ax, double ay, double power, double base) {
    final dist = base + power * T.spacePassPower;
    final speed = BallPhysics.speedForDistance(dist);
    return (
      tx: d.pos.x + ax * dist,
      ty: d.pos.y + ay * dist,
      speed: _clampSpeed(speed),
      vz: 0.0,
      receiver: -1,
    );
  }

  double _dist(Disc d, double x, double y) {
    final dx = x - d.pos.x;
    final dy = y - d.pos.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double _clampSpeed(double v) => clampD(v, T.passMinSpeed, T.passMaxSpeed);
}
