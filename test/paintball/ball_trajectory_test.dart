import 'package:flutter_test/flutter_test.dart';
import 'package:b_ball/paintball/logic/ball_trajectory.dart';
import 'package:b_ball/paintball/paintball_constants.dart';

void main() {
  group('BallTrajectory Physics & Math', () {
    late BallTrajectory trajectory;

    setUp(() {
      trajectory = BallTrajectory();
      trajectory.setup(
        startX: 200.0,
        startY: 700.0,
        targetX: 250.0,
        targetY: 300.0,
        arcHeight: 50.0,
        startScale: 1.0,
        endScale: 0.25,
        durationSeconds: 0.40,
      );
    });

    test('initial state is at launch coordinate with progress 0', () {
      expect(trajectory.x, 200.0);
      expect(trajectory.y, 700.0);
      expect(trajectory.z, 0.0);
      expect(trajectory.scale, 1.0);
      expect(trajectory.progress, 0.0);
      expect(trajectory.isCompleted, isFalse);
    });

    test('midpoint evaluation (t = 0.5) reaches arc peak', () {
      trajectory.evaluate(0.5);

      // x: halfway between 200 and 250 = 225
      expect(trajectory.x, 225.0);

      // linear y: halfway between 700 and 300 = 500
      // arc offset: 4 * 50 * 0.5 * 0.5 = 50.0 upward
      // y = 500 - 50 = 450
      expect(trajectory.y, 450.0);
      expect(trajectory.y, equals(trajectory.peakY));

      // z = 0.5
      expect(trajectory.z, 0.5);

      // scale: halfway between 1.0 and 0.25 = 0.625
      expect(trajectory.scale, 0.625);
      expect(trajectory.isCompleted, isFalse);
    });

    test('landing evaluation (t = 1.0) lands exactly at target', () {
      trajectory.evaluate(1.0);

      expect(trajectory.x, 250.0);
      expect(trajectory.y, 300.0);
      expect(trajectory.z, 1.0);
      expect(trajectory.scale, 0.25);
      expect(trajectory.progress, 1.0);
      expect(trajectory.isCompleted, isTrue);
    });

    test('update() steps forward deterministically and completes at 0.40s', () {
      trajectory.update(0.20); // 50% elapsed
      expect(trajectory.progress, closeTo(0.50, 0.001));
      expect(trajectory.x, closeTo(225.0, 0.001));
      expect(trajectory.isCompleted, isFalse);

      trajectory.update(0.20); // 100% elapsed
      expect(trajectory.progress, 1.0);
      expect(trajectory.x, 250.0);
      expect(trajectory.y, 300.0);
      expect(trajectory.isCompleted, isTrue);

      // Further updates do not overshoot
      trajectory.update(0.10);
      expect(trajectory.progress, 1.0);
      expect(trajectory.isCompleted, isTrue);
    });

    test('syncToTimestamp() evaluates position from server timestamp', () {
      trajectory.setup(
        startX: 100.0,
        startY: 500.0,
        targetX: 100.0,
        targetY: 200.0,
        launchTimestampMs: 1000,
        durationSeconds: PaintballK.ballFlightSeconds, // 400 ms
      );

      // At launch timestamp: t = 0
      trajectory.syncToTimestamp(1000);
      expect(trajectory.progress, 0.0);

      // 200 ms after launch: t = 0.5
      trajectory.syncToTimestamp(1200);
      expect(trajectory.progress, closeTo(0.5, 0.001));

      // 400 ms after launch: t = 1.0
      trajectory.syncToTimestamp(1400);
      expect(trajectory.progress, 1.0);
      expect(trajectory.isCompleted, isTrue);
    });
  });
}
