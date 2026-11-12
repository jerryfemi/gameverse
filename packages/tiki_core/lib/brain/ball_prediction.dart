import 'dart:math' as math;

import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/ball.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/sim/physics/ball_physics.dart';

/// Where is a loose ball going?
abstract final class BallPrediction {
  /// Where a loose ball will come to rest (roughly, for lobs).
  static void stopPoint(Ball b, Vec2 out) {
    final speed = b.speed;
    if (speed < 0.1) {
      out.setFrom(b.pos);
      return;
    }
    var dist = BallPhysics.rollDistance(speed);
    if (b.z > 0.0 || b.vz > 0.0) {
      // Time in the air, then it rolls on (bounces ignored).
      final flight =
          (b.vz + math.sqrt(b.vz * b.vz + 2.0 * T.gravity * b.z)) / T.gravity;
      dist += speed * flight;
    }
    out.set(b.pos.x + b.vel.x / speed * dist, b.pos.y + b.vel.y / speed * dist);
  }

  /// The point on the ball's path closest to [d]: where to go to meet it.
  static void meetPoint(Ball b, Disc d, Vec2 out) {
    stopPoint(b, out);
    final t = projectOnSegment(
      d.pos.x,
      d.pos.y,
      b.pos.x,
      b.pos.y,
      out.x,
      out.y,
    );
    out.set(b.pos.x + (out.x - b.pos.x) * t, b.pos.y + (out.y - b.pos.y) * t);
  }
}
