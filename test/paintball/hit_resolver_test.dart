import 'package:flutter_test/flutter_test.dart';
import 'package:b_ball/paintball/logic/hit_resolver.dart';
import 'package:b_ball/paintball/paintball_constants.dart';

void main() {
  group('HitResolver Direct Lane Evaluation', () {
    test('standing player in lane is hit when aimY is within 0.35..1.0', () {
      const target = TargetPlayerSnapshot(
        lane: 2,
        stance: PaintballStance.stand,
      );

      final result = HitResolver.resolveAtTargetLane(
        targetLane: 2,
        aimY: 0.65,
        target: target,
      );

      expect(result.isHit, isTrue);
      expect(result.outcome, PaintballHitOutcome.hitBody);
      expect(result.targetLane, 2);
      expect(result.isDodged, isFalse);
    });

    test('standing player in lane blocks shot below 0.35 with tires', () {
      const target = TargetPlayerSnapshot(
        lane: 2,
        stance: PaintballStance.stand,
      );

      final result = HitResolver.resolveAtTargetLane(
        targetLane: 2,
        aimY: 0.20,
        target: target,
      );

      expect(result.isHit, isFalse);
      expect(result.outcome, PaintballHitOutcome.hitTire);
      expect(result.isDodged, isFalse);
    });

    test('shot at wrong lane completely misses', () {
      const target = TargetPlayerSnapshot(
        lane: 2,
        stance: PaintballStance.stand,
      );

      final result = HitResolver.resolveAtTargetLane(
        targetLane: 3,
        aimY: 0.65,
        target: target,
      );

      expect(result.isHit, isFalse);
      expect(result.outcome, PaintballHitOutcome.missedLane);
      expect(result.isDodged, isFalse);
    });

    test('crouched player is hit only on head/shoulders (0.55..0.80)', () {
      const target = TargetPlayerSnapshot(
        lane: 1,
        stance: PaintballStance.crouch,
      );

      // Height 0.65: head/shoulders peeking -> hit!
      final headHit = HitResolver.resolveAtTargetLane(
        targetLane: 1,
        aimY: 0.65,
        target: target,
      );
      expect(headHit.isHit, isTrue);
      expect(headHit.outcome, PaintballHitOutcome.hitBody);

      // Height 0.40: protected by tires -> tire hit & dodged
      final tireHit = HitResolver.resolveAtTargetLane(
        targetLane: 1,
        aimY: 0.40,
        target: target,
      );
      expect(tireHit.isHit, isFalse);
      expect(tireHit.outcome, PaintballHitOutcome.hitTire);
      expect(tireHit.isDodged, isTrue);

      // Height 0.90: shot flew over crouched head -> tire/miss & dodged
      final overHit = HitResolver.resolveAtTargetLane(
        targetLane: 1,
        aimY: 0.90,
        target: target,
      );
      expect(overHit.isHit, isFalse);
      expect(overHit.isDodged, isTrue);
    });

    test('ducked player is 100% immune and registers dodged stat', () {
      const target = TargetPlayerSnapshot(
        lane: 4,
        stance: PaintballStance.duck,
      );

      // Shot at chest height (would hit standing)
      final result = HitResolver.resolveAtTargetLane(
        targetLane: 4,
        aimY: 0.65,
        target: target,
      );

      expect(result.isHit, isFalse);
      expect(result.outcome, PaintballHitOutcome.hitTire);
      expect(result.isDodged, isTrue); // Saved by ducking!
    });

    test('invulnerable player takes no damage even if directly hit', () {
      const target = TargetPlayerSnapshot(
        lane: 2,
        stance: PaintballStance.stand,
        isInvulnerable: true,
      );

      final result = HitResolver.resolveAtTargetLane(
        targetLane: 2,
        aimY: 0.70,
        target: target,
      );

      expect(result.isHit, isFalse);
      expect(result.outcome, PaintballHitOutcome.invulnerable);
      expect(result.isDodged, isFalse);
    });
  });

  group('HitResolver Mid-Slide Dual Vulnerability', () {
    test('first half of slide (progress < 0.50): vulnerable in BOTH lanes', () {
      const slidingPlayer = TargetPlayerSnapshot(
        lane: 1,
        stance: PaintballStance.stand,
        isSliding: true,
        slideFromLane: 1,
        slideToLane: 2,
        slideProgress: 0.30, // 30% through slide
      );

      // Shot into departure lane 1 -> HITS
      final shotLane1 = HitResolver.resolveAtTargetLane(
        targetLane: 1,
        aimY: 0.65,
        target: slidingPlayer,
      );
      expect(shotLane1.isHit, isTrue);

      // Shot into arrival lane 2 -> ALSO HITS
      final shotLane2 = HitResolver.resolveAtTargetLane(
        targetLane: 2,
        aimY: 0.65,
        target: slidingPlayer,
      );
      expect(shotLane2.isHit, isTrue);

      // Shot into lane 0 -> misses
      final shotLane0 = HitResolver.resolveAtTargetLane(
        targetLane: 0,
        aimY: 0.65,
        target: slidingPlayer,
      );
      expect(shotLane0.isHit, isFalse);
    });

    test('second half of slide (progress >= 0.50): vulnerable ONLY in destination lane', () {
      const committedPlayer = TargetPlayerSnapshot(
        lane: 1,
        stance: PaintballStance.stand,
        isSliding: true,
        slideFromLane: 1,
        slideToLane: 2,
        slideProgress: 0.70, // 70% through slide
      );

      // Shot into departure lane 1 -> MISSES (left that lane)
      final shotLane1 = HitResolver.resolveAtTargetLane(
        targetLane: 1,
        aimY: 0.65,
        target: committedPlayer,
      );
      expect(shotLane1.isHit, isFalse);
      expect(shotLane1.outcome, PaintballHitOutcome.missedLane);

      // Shot into arrival lane 2 -> HITS
      final shotLane2 = HitResolver.resolveAtTargetLane(
        targetLane: 2,
        aimY: 0.65,
        target: committedPlayer,
      );
      expect(shotLane2.isHit, isTrue);
    });
  });

  group('HitResolver Shooter Coordinate Mirroring', () {
    test('shooter aim at far-left (aimX = -1.0) hits target at far-right (lane 4)', () {
      const targetAtLane4 = TargetPlayerSnapshot(
        lane: 4,
        stance: PaintballStance.stand,
      );

      final result = HitResolver.resolveFromShooterAim(
        shooterAimX: -1.0, // Shooter aims at their own far-left
        aimY: 0.65,
        target: targetAtLane4,
      );

      expect(result.isHit, isTrue);
      expect(result.targetLane, 4);
    });

    test('shooter aim at center (aimX = 0.0) hits target at center (lane 2)', () {
      const targetAtLane2 = TargetPlayerSnapshot(
        lane: 2,
        stance: PaintballStance.stand,
      );

      final result = HitResolver.resolveFromShooterAim(
        shooterAimX: 0.0,
        aimY: 0.65,
        target: targetAtLane2,
      );

      expect(result.isHit, isTrue);
      expect(result.targetLane, 2);
    });

    test('shooter aim at far-right (aimX = 1.0) hits target at far-left (lane 0)', () {
      const targetAtLane0 = TargetPlayerSnapshot(
        lane: 0,
        stance: PaintballStance.stand,
      );

      final result = HitResolver.resolveFromShooterAim(
        shooterAimX: 1.0,
        aimY: 0.65,
        target: targetAtLane0,
      );

      expect(result.isHit, isTrue);
      expect(result.targetLane, 0);
    });
  });
}
