import 'dart:math' as math;

import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/ball.dart';

/// Moves a loose ball: rolling friction on the ground, gravity and bounces
/// in the air. A carried ball is placed by `rules/possession.dart` instead.
class BallPhysics {
  void step(Ball b, double dt) {
    if (!b.isLoose) return;
    final airborne = b.z > 0.0 || b.vz > 0.0;
    if (airborne) {
      _fly(b, dt);
    } else {
      _roll(b, dt);
    }
    b.pos.addScaled(b.vel, dt);
  }

  void _fly(Ball b, double dt) {
    b.vz -= T.gravity * dt;
    b.z += b.vz * dt;
    b.vel.scale(1.0 - T.airDrag * dt);
    if (b.z > 0.0) return;
    // Landing.
    b.z = 0.0;
    if (b.vz < -T.bounceMinVz) {
      b.vz = -b.vz * T.bounceRestitution;
      b.vel.scale(T.bounceKeep);
    } else {
      b.vz = 0.0;
    }
  }

  void _roll(Ball b, double dt) {
    final speed = b.vel.length;
    if (speed < 0.05) {
      b.vel.setZero();
      return;
    }
    final drop = (T.rollDecel + T.rollDrag * speed) * dt;
    final newSpeed = math.max(0.0, speed - drop);
    b.vel.scale(newSpeed / speed);
  }

  /// How far a ball rolling at [speed] travels before stopping.
  ///
  /// Slow-down is `a + k·v`, which gives
  /// `distance = v/k − (a/k²)·ln(1 + k·v/a)`.
  static double rollDistance(double speed) {
    const a = T.rollDecel;
    const k = T.rollDrag;
    if (speed <= 0.0) return 0.0;
    return speed / k - (a / (k * k)) * math.log(1.0 + k * speed / a);
  }

  /// Launch speed for a rolling ball to travel [distance] metres
  /// (bisection on [rollDistance]; only runs when a pass is played).
  static double speedForDistance(double distance) {
    if (distance <= 0.0) return 0.0;
    var lo = 0.0;
    var hi = 60.0;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) * 0.5;
      if (rollDistance(mid) < distance) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo + hi) * 0.5;
  }
}
