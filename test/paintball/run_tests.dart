// ignore_for_file: avoid_print
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/ball_trajectory.dart';
import 'package:b_ball/paintball/logic/hit_resolver.dart';

void expect(dynamic actual, dynamic expected, [String? message]) {
  if (actual != expected) {
    throw Exception('FAILED: expected $expected, got $actual. $message');
  }
}

void expectTrue(bool condition, [String? message]) {
  if (!condition) {
    throw Exception('FAILED: expected true. $message');
  }
}

void expectFalse(bool condition, [String? message]) {
  if (condition) {
    throw Exception('FAILED: expected false. $message');
  }
}

void expectClose(double actual, double expected, double delta, [String? message]) {
  if ((actual - expected).abs() > delta) {
    throw Exception('FAILED: expected $expected +/- $delta, got $actual. $message');
  }
}

void main() {
  int passed = 0;

  void runTest(String name, void Function() body) {
    try {
      body();
      passed++;
      print('  PASS: $name');
    } catch (e) {
      print('  FAIL: $name -> $e');
      rethrow;
    }
  }

  print('\n=== Running Paintball Pure Dart Unit Tests ===\n');

  // Group 1: PaintballK
  print('[Group: PaintballK Constants & Math]');
  runTest('mirrorLane mirrors 0..4 symmetrically', () {
    expect(PaintballK.mirrorLane(0), 4);
    expect(PaintballK.mirrorLane(1), 3);
    expect(PaintballK.mirrorLane(2), 2);
    expect(PaintballK.mirrorLane(3), 1);
    expect(PaintballK.mirrorLane(4), 0);
  });

  runTest('laneToAimX and aimXToLane convert accurately', () {
    expect(PaintballK.laneToAimX(0), -1.0);
    expect(PaintballK.laneToAimX(2), 0.0);
    expect(PaintballK.laneToAimX(4), 1.0);

    expect(PaintballK.aimXToLane(-1.0), 0);
    expect(PaintballK.aimXToLane(-0.5), 1);
    expect(PaintballK.aimXToLane(0.0), 2);
    expect(PaintballK.aimXToLane(0.5), 3);
    expect(PaintballK.aimXToLane(1.0), 4);
  });

  runTest('isHeightExposed calculates stand, crouch, duck bounds correctly', () {
    // Stand: 0.35..1.0
    expectFalse(PaintballK.isHeightExposed(PaintballStance.stand, 0.20));
    expectTrue(PaintballK.isHeightExposed(PaintballStance.stand, 0.35));
    expectTrue(PaintballK.isHeightExposed(PaintballStance.stand, 0.70));
    expectTrue(PaintballK.isHeightExposed(PaintballStance.stand, 1.00));
    expectFalse(PaintballK.isHeightExposed(PaintballStance.stand, 1.05));

    // Crouch: 0.55..0.80
    expectFalse(PaintballK.isHeightExposed(PaintballStance.crouch, 0.40));
    expectTrue(PaintballK.isHeightExposed(PaintballStance.crouch, 0.65));
    expectFalse(PaintballK.isHeightExposed(PaintballStance.crouch, 0.90));

    // Duck: 100% immune
    expectFalse(PaintballK.isHeightExposed(PaintballStance.duck, 0.0));
    expectFalse(PaintballK.isHeightExposed(PaintballStance.duck, 0.65));
    expectFalse(PaintballK.isHeightExposed(PaintballStance.duck, 1.0));
  });

  // Group 2: BallTrajectory
  print('\n[Group: BallTrajectory Ballistics]');
  runTest('trajectory evaluates start, midpoint peak, and landing', () {
    final t = BallTrajectory();
    t.setup(
      startX: 100,
      startY: 500,
      targetX: 200,
      targetY: 200,
      arcHeight: 60,
      startScale: 1.0,
      endScale: 0.3,
      durationSeconds: 0.40,
    );

    // Initial
    expect(t.x, 100.0);
    expect(t.y, 500.0);
    expect(t.z, 0.0);
    expect(t.scale, 1.0);
    expectFalse(t.isCompleted);

    // Midpoint t = 0.5
    t.evaluate(0.5);
    expect(t.x, 150.0);
    expect(t.y, 350.0 - 60.0); // 290.0
    expect(t.z, 0.5);
    expect(t.scale, 0.65);
    expectFalse(t.isCompleted);

    // Landing t = 1.0
    t.evaluate(1.0);
    expect(t.x, 200.0);
    expect(t.y, 200.0);
    expect(t.z, 1.0);
    expectClose(t.scale, 0.3, 0.001);
    expectTrue(t.isCompleted);
  });

  runTest('trajectory update and timestamp sync step smoothly', () {
    final t = BallTrajectory();
    t.setup(
      startX: 0,
      startY: 0,
      targetX: 100,
      targetY: 100,
      durationSeconds: 0.40,
    );
    t.update(0.20);
    expectClose(t.progress, 0.5, 0.001);
    expectFalse(t.isCompleted);

    t.update(0.20);
    expect(t.progress, 1.0);
    expectTrue(t.isCompleted);
  });

  // Group 3: HitResolver
  print('\n[Group: HitResolver Collision & Dodge Tracking]');
  runTest('resolves direct hit on standing target in occupied lane', () {
    const target = TargetPlayerSnapshot(lane: 2, stance: PaintballStance.stand);
    final res = HitResolver.resolveAtTargetLane(targetLane: 2, aimY: 0.60, target: target);
    expectTrue(res.isHit);
    expect(res.outcome, PaintballHitOutcome.hitBody);
    expectFalse(res.isDodged);
  });

  runTest('resolves hitTire and dodge tracking for ducked target', () {
    const target = TargetPlayerSnapshot(lane: 2, stance: PaintballStance.duck);
    final res = HitResolver.resolveAtTargetLane(targetLane: 2, aimY: 0.60, target: target);
    expectFalse(res.isHit);
    expect(res.outcome, PaintballHitOutcome.hitTire);
    expectTrue(res.isDodged);
  });

  runTest('resolves missed lane when target is in different lane', () {
    const target = TargetPlayerSnapshot(lane: 1, stance: PaintballStance.stand);
    final res = HitResolver.resolveAtTargetLane(targetLane: 3, aimY: 0.60, target: target);
    expectFalse(res.isHit);
    expect(res.outcome, PaintballHitOutcome.missedLane);
    expectFalse(res.isDodged);
  });

  runTest('evaluates mid-slide dual vulnerability (first 50% vs second 50%)', () {
    // 30% into slide: vulnerable in BOTH lane 1 and lane 2
    const slidingPlayer = TargetPlayerSnapshot(
      lane: 1,
      stance: PaintballStance.stand,
      isSliding: true,
      slideFromLane: 1,
      slideToLane: 2,
      slideProgress: 0.30,
    );
    final shot1 = HitResolver.resolveAtTargetLane(targetLane: 1, aimY: 0.60, target: slidingPlayer);
    final shot2 = HitResolver.resolveAtTargetLane(targetLane: 2, aimY: 0.60, target: slidingPlayer);
    expectTrue(shot1.isHit);
    expectTrue(shot2.isHit);

    // 70% into slide: vulnerable ONLY in destination lane 2
    const committedPlayer = TargetPlayerSnapshot(
      lane: 1,
      stance: PaintballStance.stand,
      isSliding: true,
      slideFromLane: 1,
      slideToLane: 2,
      slideProgress: 0.70,
    );
    final shot1Late = HitResolver.resolveAtTargetLane(targetLane: 1, aimY: 0.60, target: committedPlayer);
    final shot2Late = HitResolver.resolveAtTargetLane(targetLane: 2, aimY: 0.60, target: committedPlayer);
    expectFalse(shot1Late.isHit);
    expectTrue(shot2Late.isHit);
  });

  runTest('mirrors shooter aimX correctly across the field', () {
    const targetAtLane4 = TargetPlayerSnapshot(lane: 4, stance: PaintballStance.stand);
    // Shooter aims at their far-left (aimX = -1.0), which mirrors to lane 4
    final res = HitResolver.resolveFromShooterAim(
      shooterAimX: -1.0,
      aimY: 0.60,
      target: targetAtLane4,
    );
    expectTrue(res.isHit);
    expect(res.targetLane, 4);
  });

  runTest('honors post-hit invulnerability period', () {
    const target = TargetPlayerSnapshot(lane: 2, stance: PaintballStance.stand, isInvulnerable: true);
    final res = HitResolver.resolveAtTargetLane(targetLane: 2, aimY: 0.60, target: target);
    expectFalse(res.isHit);
    expect(res.outcome, PaintballHitOutcome.invulnerable);
  });

  print('\n=== ALL $passed PAINTBALL TESTS PASSED SUCCESSFULLY! ===\n');
}
