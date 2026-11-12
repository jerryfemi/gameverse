import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/ball.dart';
import 'package:tiki_core/sim/physics/ball_physics.dart';

import 'harness.dart';

void ballPhysicsChecks() {
  check('speedForDistance is the inverse of rollDistance', () {
    for (final d in [2.0, 8.0, 15.0, 30.0]) {
      final v = BallPhysics.speedForDistance(d);
      expectClose(BallPhysics.rollDistance(v), d, 0.01, 'distance for $d m');
    }
  });

  check('a rolled ball stops about where rollDistance says', () {
    final b = Ball();
    b.vel.set(BallPhysics.speedForDistance(12.0), 0.0);
    final physics = BallPhysics();
    for (var i = 0; i < 60 * 10; i++) {
      physics.step(b, T.fixedDt);
    }
    expectEqual(b.speed, 0.0, 'final speed');
    expectClose(b.pos.x, 12.0, 0.4, 'stop point');
  });

  check('a lob goes up and comes back down', () {
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
    expectThat(maxZ > 1.5, 'peak height > 1.5 m (was $maxZ)');
    expectEqual(b.z, 0.0, 'height after landing');
  });
}
