import 'package:flutter_test/flutter_test.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/net/paintball_clock.dart';
import 'package:b_ball/paintball/net/paintball_protocol.dart';

void main() {
  group('PaintballClock Tests', () {
    late PaintballClock clock;

    setUp(() {
      clock = PaintballClock();
    });

    test('initial state has 0 offset and normal latency', () {
      expect(clock.offsetMs, 0);
      expect(clock.latencyRating, PaintballLatencyRating.normal);
    });

    test('updateOffset applies server drift', () {
      clock.updateOffset(-150.4);
      expect(clock.offsetMs, -150);

      final now = DateTime.now();
      expect(clock.toServerMs(now), now.millisecondsSinceEpoch - 150);
      expect(
        clock.fromServerMs(1000).millisecondsSinceEpoch,
        1150,
      );
    });

    test('latency rating threshold transitions (normal -> amber -> red)', () {
      clock.recordRtt(100.0);
      expect(clock.latencyRating, PaintballLatencyRating.normal);

      // Force high RTT
      for (int i = 0; i < 15; i++) {
        clock.recordRtt(450.0);
      }
      expect(clock.latencyRating, PaintballLatencyRating.amber);

      for (int i = 0; i < 15; i++) {
        clock.recordRtt(750.0);
      }
      expect(clock.latencyRating, PaintballLatencyRating.red);
    });
  });

  group('PaintballProtocol Serialization & Rules', () {
    test('PaintballNetMeta roundtrips and checks version compatibility', () {
      const meta = PaintballNetMeta(
        hostUid: 'host123',
        guestUid: 'guest456',
        status: PaintballMatchNetStatus.live,
        startAtMs: 1700000000000,
        version: kPaintballProtocolVersion,
      );

      final map = meta.toMap();
      expect(map['h'], 'host123');
      expect(map['g'], 'guest456');
      expect(map['st'], 'l');
      expect(map['at'], 1700000000000);
      expect(map['v'], kPaintballProtocolVersion);

      final restored = PaintballNetMeta.fromMap(map);
      expect(restored.hostUid, 'host123');
      expect(restored.guestUid, 'guest456');
      expect(restored.status, PaintballMatchNetStatus.live);
      expect(restored.startAtMs, 1700000000000);
      expect(restored.isVersionCompatible, isTrue);

      final incompatible = PaintballNetMeta.fromMap({'v': 99});
      expect(incompatible.isVersionCompatible, isFalse);
    });

    test('PaintballNetPlayerState roundtrips with clamped invariants', () {
      const state = PaintballNetPlayerState(
        lane: 3,
        stance: 1,
        ammo: 4,
        hitsTaken: 2,
        aimBucket: -1,
        slideFromLane: 2,
        timestamp: 123456789,
        connected: true,
      );

      final map = state.toMap();
      final restored = PaintballNetPlayerState.fromMap(map);

      expect(restored.lane, 3);
      expect(restored.stance, 1);
      expect(restored.stanceEnum, PaintballStance.crouch);
      expect(restored.ammo, 4);
      expect(restored.hitsTaken, 2);
      expect(restored.aimBucket, -1);
      expect(restored.slideFromLane, 2);
      expect(restored.connected, isTrue);

      // Verify clamping on malformed input
      final malformed = PaintballNetPlayerState.fromMap({
        'l': 99,
        's': 5,
        'a': 100,
        'h': -5,
        'm': 4,
      });
      expect(malformed.lane, 4);
      expect(malformed.stance, 2);
      expect(malformed.ammo, PaintballK.maxAmmo);
      expect(malformed.hitsTaken, 0);
      expect(malformed.aimBucket, 1);
    });

    test('PaintballNetShot rounds coordinates to 3 decimal places', () {
      const shot = PaintballNetShot(
        id: 'shot_1',
        shooterUid: 'p1',
        serverMs: 5000,
        aimX: -0.123456,
        aimY: 0.67891,
      );

      final map = shot.toMap();
      expect(map['x'], -0.123);
      expect(map['y'], 0.679);

      final restored = PaintballNetShot.fromMap('shot_1', map);
      expect(restored.id, 'shot_1');
      expect(restored.shooterUid, 'p1');
      expect(restored.serverMs, 5000);
      expect(restored.aimX, -0.123);
      expect(restored.aimY, 0.679);
    });

    test('PaintballNetShotResult rounds dx and y to 2 decimal places', () {
      const result = PaintballNetShotResult(
        shotId: 'shot_1',
        outcome: PaintballNetHitOutcome.hit,
        dx: 0.4567,
        aimY: 0.7891,
      );

      final map = result.toMap();
      expect(map['k'], 1);
      expect(map['x'], 0.46);
      expect(map['y'], 0.79);

      final restored = PaintballNetShotResult.fromMap('shot_1', map);
      expect(restored.shotId, 'shot_1');
      expect(restored.isHit, isTrue);
      expect(restored.dx, 0.46);
      expect(restored.aimY, 0.79);
    });

    test('PaintballNetEnd serializes winner and termination reason', () {
      const end = PaintballNetEnd(
        winnerUid: 'host123',
        reason: PaintballEndReason.forfeit,
      );

      final map = end.toMap();
      expect(map['w'], 'host123');
      expect(map['by'], 'forfeit');

      final restored = PaintballNetEnd.fromMap(map);
      expect(restored.winnerUid, 'host123');
      expect(restored.reason, PaintballEndReason.forfeit);
      expect(restored.isTie, isFalse);
    });

    test('computeAimBucket hysteresis avoids boundary flickering', () {
      // Starting from center (0):
      expect(computeAimBucket(0.0, 0), 0);
      expect(computeAimBucket(0.25, 0), 0); // Below 0.30 threshold
      expect(computeAimBucket(0.35, 0), 1); // Exceeds 0.30 -> switch to right (1)

      // Currently right (1): should stay right even if dipping to 0.28 due to hysteresis
      expect(computeAimBucket(0.28, 1), 1);
      expect(computeAimBucket(0.24, 1), 0); // Dips below 0.25 (threshold - hysteresis) -> back to center (0)

      // Currently center (0) moving left:
      expect(computeAimBucket(-0.25, 0), 0);
      expect(computeAimBucket(-0.35, 0), -1);

      // Currently left (-1): should stay left until rising above -0.25
      expect(computeAimBucket(-0.28, -1), -1);
      expect(computeAimBucket(-0.24, -1), 0);
    });
  });
}
