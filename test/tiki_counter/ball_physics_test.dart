import 'package:flutter_test/flutter_test.dart';

import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/ball.dart';
import 'package:b_ball/tiki_counter/sim/physics/ball_physics.dart';

void main() {
  test('speedForDistance is the inverse of rollDistance', () {
    for (final d in [2.0, 8.0, 15.0, 30.0]) {
      final v = BallPhysics.speedForDistance(d);
      expect(BallPhysics.rollDistance(v), closeTo(d, 0.01));
    }
  });

  test('a rolled ball stops about where rollDistance says', () {
    final b = Ball();
    final v = BallPhysics.speedForDistance(12.0);
    b.vel.set(v, 0.0);
    final physics = BallPhysics();
    for (var i = 0; i < 60 * 10; i++) {
      physics.step(b, T.fixedDt);
    }
    expect(b.speed, 0.0);
    expect(b.pos.x, closeTo(12.0, 0.4));
  });

  test('a lob goes up and comes back down', () {
    final b = Ball();
    b.vel.set(8.0, 0.0);
    b.vz = 6.0;
    b.z = 0.01;
    final physics = BallPhysics();
    var maxZ = 0.0;
    for (var i = 0; i < 60 * 4; i++) {
      physics.step(b, T.fixedDt);
      if (b.z > maxZ) maxZ = b.z;
    }
    expect(maxZ, greaterThan(1.5));
    expect(b.z, 0.0);
  });
}
