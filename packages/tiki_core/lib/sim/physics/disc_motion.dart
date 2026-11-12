import 'dart:math' as math;

import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_state.dart';

/// Moves every disc toward what it wants, with limited acceleration.
///
/// - Controlled disc (`manual`): wants `desiredVel` (from stick or bot).
/// - Everyone else: "arrive" at `target` at a speed set by `urgency`.
///
/// This is the only place discs actually move. Instructions, patterns and
/// buttons only ever change *what they want*.
class DiscMotion {
  /// Run off around the lines where discs may still go.
  static const double runOff = 1.5;

  void step(MatchState s, double dt) {
    for (final d in s.discs) {
      _tickTimers(d, dt);
      final wantX = _wantX(d);
      final wantY = _wantY(d);
      _accelerate(s, d, wantX, wantY, dt);
      d.pos.addScaled(d.vel, dt);
      _clampToBoard(s, d);
      _updateFacing(d);
    }
  }

  void _tickTimers(Disc d, double dt) {
    if (d.stunTimer > 0) d.stunTimer = math.max(0.0, d.stunTimer - dt);
    if (d.tackleCooldown > 0) {
      d.tackleCooldown = math.max(0.0, d.tackleCooldown - dt);
    }
    if (d.pickupCooldown > 0) {
      d.pickupCooldown = math.max(0.0, d.pickupCooldown - dt);
    }
  }

  // Desired velocity, split in x/y to avoid allocating a vector.
  double _wantX(Disc d) => d.manual ? d.desiredVel.x : _arrive(d, true);
  double _wantY(Disc d) => d.manual ? d.desiredVel.y : _arrive(d, false);

  double _arrive(Disc d, bool xAxis) {
    final dx = d.target.x - d.pos.x;
    final dy = d.target.y - d.pos.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.15) return 0.0;
    var speed = math.min(T.sprintSpeed, T.runSpeed * d.urgency);
    if (dist < T.arriveRadius) speed *= dist / T.arriveRadius;
    return (xAxis ? dx : dy) / dist * speed;
  }

  void _accelerate(MatchState s, Disc d, double wx, double wy, double dt) {
    var maxSpeed = math.sqrt(wx * wx + wy * wy);
    if (d.stunTimer > 0) {
      final cap = T.runSpeed * T.stunSpeedFactor;
      if (maxSpeed > cap) {
        wx *= cap / maxSpeed;
        wy *= cap / maxSpeed;
        maxSpeed = cap;
      }
    }
    final carryingDash = d.dashing && s.ball.ownerId == d.id;
    final a = carryingDash ? T.accelDashCarry : T.accel;
    var dvx = wx - d.vel.x;
    var dvy = wy - d.vel.y;
    final dv = math.sqrt(dvx * dvx + dvy * dvy);
    final maxDv = a * dt;
    if (dv > maxDv) {
      dvx *= maxDv / dv;
      dvy *= maxDv / dv;
    }
    d.vel.x += dvx;
    d.vel.y += dvy;
  }

  void _clampToBoard(MatchState s, Disc d) {
    final hx = s.mode.halfLength + runOff;
    final hy = s.mode.halfWidth + runOff;
    final cx = clampD(d.pos.x, -hx, hx);
    final cy = clampD(d.pos.y, -hy, hy);
    if (cx != d.pos.x) d.vel.x = 0.0;
    if (cy != d.pos.y) d.vel.y = 0.0;
    d.pos.set(cx, cy);
  }

  void _updateFacing(Disc d) {
    double fx = d.vel.x;
    double fy = d.vel.y;
    if (d.manual && d.desiredVel.length2 > 0.09) {
      fx = d.desiredVel.x;
      fy = d.desiredVel.y;
    }
    final l = math.sqrt(fx * fx + fy * fy);
    if (l > 0.3) d.facing.set(fx / l, fy / l);
  }
}
