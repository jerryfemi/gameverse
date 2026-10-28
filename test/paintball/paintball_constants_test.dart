import 'package:flutter_test/flutter_test.dart';
import 'package:b_ball/paintball/paintball_constants.dart';

void main() {
  group('PaintballK Lane Mirroring', () {
    test('mirrors all 5 lanes symmetrically', () {
      expect(PaintballK.mirrorLane(0), 4);
      expect(PaintballK.mirrorLane(1), 3);
      expect(PaintballK.mirrorLane(2), 2);
      expect(PaintballK.mirrorLane(3), 1);
      expect(PaintballK.mirrorLane(4), 0);
    });

    test('clamps out-of-range lanes safely', () {
      expect(PaintballK.mirrorLane(-1), 4);
      expect(PaintballK.mirrorLane(99), 0);
    });
  });

  group('PaintballK AimX Coordinate Conversion', () {
    test('maps lane centers correctly to [-1.0, 1.0]', () {
      expect(PaintballK.laneToAimX(0), -1.0);
      expect(PaintballK.laneToAimX(1), -0.5);
      expect(PaintballK.laneToAimX(2), 0.0);
      expect(PaintballK.laneToAimX(3), 0.5);
      expect(PaintballK.laneToAimX(4), 1.0);
    });

    test('converts continuous aimX into correct lane index', () {
      // Lane 0: aimX < -0.75
      expect(PaintballK.aimXToLane(-1.0), 0);
      expect(PaintballK.aimXToLane(-0.8), 0);

      // Lane 1: -0.75 <= aimX < -0.25
      expect(PaintballK.aimXToLane(-0.74), 1);
      expect(PaintballK.aimXToLane(-0.5), 1);
      expect(PaintballK.aimXToLane(-0.26), 1);

      // Lane 2: -0.25 <= aimX < 0.25 (center)
      expect(PaintballK.aimXToLane(-0.24), 2);
      expect(PaintballK.aimXToLane(0.0), 2);
      expect(PaintballK.aimXToLane(0.24), 2);

      // Lane 3: 0.25 <= aimX < 0.75
      expect(PaintballK.aimXToLane(0.26), 3);
      expect(PaintballK.aimXToLane(0.5), 3);
      expect(PaintballK.aimXToLane(0.74), 3);

      // Lane 4: aimX >= 0.75
      expect(PaintballK.aimXToLane(0.75), 4);
      expect(PaintballK.aimXToLane(1.0), 4);
      expect(PaintballK.aimXToLane(1.5), 4);
    });
  });

  group('PaintballK Stance Exposure Calculations', () {
    test('stand stance exposes from the tyre top (0.55) to 1.0', () {
      expect(PaintballK.isHeightExposed(PaintballStance.stand, 0.0), isFalse);
      expect(PaintballK.isHeightExposed(PaintballStance.stand, 0.35), isFalse);
      expect(PaintballK.isHeightExposed(PaintballStance.stand, 0.54), isFalse);
      expect(PaintballK.isHeightExposed(PaintballStance.stand, 0.55), isTrue);
      expect(PaintballK.isHeightExposed(PaintballStance.stand, 0.70), isTrue);
      expect(PaintballK.isHeightExposed(PaintballStance.stand, 1.00), isTrue);
      expect(PaintballK.isHeightExposed(PaintballStance.stand, 1.05), isFalse);
    });

    test('crouch stance exposes only head/shoulders between 0.55 and 0.72', () {
      expect(PaintballK.isHeightExposed(PaintballStance.crouch, 0.40), isFalse);
      expect(PaintballK.isHeightExposed(PaintballStance.crouch, 0.55), isTrue);
      expect(PaintballK.isHeightExposed(PaintballStance.crouch, 0.65), isTrue);
      expect(PaintballK.isHeightExposed(PaintballStance.crouch, 0.72), isTrue);
      expect(PaintballK.isHeightExposed(PaintballStance.crouch, 0.80), isFalse);
    });

    test('tyre top matches the stand and crouch lower bounds', () {
      expect(PaintballK.standMinExposureY, PaintballK.tyreCoverHeight);
      expect(PaintballK.crouchMinExposureY, PaintballK.tyreCoverHeight);
    });

    test('duck stance is completely immune at all heights', () {
      expect(PaintballK.isHeightExposed(PaintballStance.duck, 0.0), isFalse);
      expect(PaintballK.isHeightExposed(PaintballStance.duck, 0.35), isFalse);
      expect(PaintballK.isHeightExposed(PaintballStance.duck, 0.65), isFalse);
      expect(PaintballK.isHeightExposed(PaintballStance.duck, 1.0), isFalse);
    });
  });
}
