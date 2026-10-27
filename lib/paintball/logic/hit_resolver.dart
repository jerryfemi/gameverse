import 'package:b_ball/paintball/paintball_constants.dart';

/// Immutable snapshot of a target player's state at the moment of ball landing.
class TargetPlayerSnapshot {
  /// The lane the player is currently occupying (0..4).
  final int lane;

  /// The active stance (stand, crouch, or duck).
  final PaintballStance stance;

  /// Whether the player is actively sliding between lanes at landing time.
  final bool isSliding;

  /// The lane the player departed from (if sliding).
  final int? slideFromLane;

  /// The lane the player is sliding towards (if sliding).
  final int? slideToLane;

  /// Normalized slide progress from 0.0 (departure) to 1.0 (arrival).
  final double slideProgress;

  /// Whether the player is currently within their post-hit invulnerability grace period.
  final bool isInvulnerable;

  const TargetPlayerSnapshot({
    required this.lane,
    required this.stance,
    this.isSliding = false,
    this.slideFromLane,
    this.slideToLane,
    this.slideProgress = 0.0,
    this.isInvulnerable = false,
  });

  /// Returns true if the player currently occupies [targetLane], factoring in the
  /// mid-slide dual-vulnerability window (first 50% counts in both lanes).
  bool occupiesLane(int targetLane) {
    if (!isSliding) {
      return lane == targetLane;
    }

    final from = slideFromLane ?? lane;
    final to = slideToLane ?? lane;

    if (slideProgress < PaintballK.slideDualVulnerabilityRatio) {
      // First half of slide: vulnerable in BOTH departure and arrival lanes.
      return targetLane == from || targetLane == to;
    } else {
      // Second half of slide: committed to destination lane only.
      return targetLane == to;
    }
  }
}

/// Detailed result of evaluating a shot against a target player.
class HitResult {
  /// Whether the shot successfully damaged the target.
  final bool isHit;

  /// Detailed category of the shot resolution.
  final PaintballHitOutcome outcome;

  /// The lane index on the target's side where the ball landed (0..4).
  final int targetLane;

  /// The vertical height coordinate where the ball landed (0.0 ground .. 1.0 head).
  final double hitHeightY;

  /// True if the ball landed in the player's occupied lane and would have hit
  /// if they were standing, but was avoided due to ducking or crouching.
  ///
  /// Used directly for the "Times dodged" match statistic.
  final bool isDodged;

  const HitResult({
    required this.isHit,
    required this.outcome,
    required this.targetLane,
    required this.hitHeightY,
    this.isDodged = false,
  });

  @override
  String toString() =>
      'HitResult(isHit: $isHit, outcome: $outcome, lane: $targetLane, y: $hitHeightY, dodged: $isDodged)';
}

/// Pure Dart hit resolution engine for live Paintball duels.
///
/// Follows Paintball Plan §5d:
/// - Executed strictly on the target's client at landing time `t0 + 400 ms`.
/// - Evaluates lane match (accounting for mid-slide vulnerability).
/// - Evaluates stance exposure height.
/// - Determines whether the shot was cleanly dodged for career stats.
abstract final class HitResolver {
  /// Evaluates an incoming shot fired by a shooter at [shooterAimX] and [aimY].
  ///
  /// Automatically mirrors [shooterAimX] across the field to find the
  /// corresponding lane on the target player's screen.
  static HitResult resolveFromShooterAim({
    required double shooterAimX,
    required double aimY,
    required TargetPlayerSnapshot target,
  }) {
    // 1. Shooter's target lane on their own screen
    final shooterLane = PaintballK.aimXToLane(shooterAimX);

    // 2. Mirror across field to target's screen
    final targetLane = PaintballK.mirrorLane(shooterLane);

    return resolveAtTargetLane(
      targetLane: targetLane,
      aimY: aimY,
      target: target,
    );
  }

  /// Evaluates a shot landing directly at [targetLane] (0..4) and [aimY] (0.0..1.0).
  static HitResult resolveAtTargetLane({
    required int targetLane,
    required double aimY,
    required TargetPlayerSnapshot target,
  }) {
    final clampedLane = targetLane.clamp(PaintballK.minLane, PaintballK.maxLane);
    final clampedHeight = aimY.clamp(0.0, 1.0);

    // 1. Lane occupancy check
    final inOccupiedLane = target.occupiesLane(clampedLane);
    if (!inOccupiedLane) {
      return HitResult(
        isHit: false,
        outcome: PaintballHitOutcome.missedLane,
        targetLane: clampedLane,
        hitHeightY: clampedHeight,
        isDodged: false,
      );
    }

    // 2. Check if a standing player would have been hit (stand exposure: 0.35–1.0)
    final wouldHitIfStanding = PaintballK.isHeightExposed(
      PaintballStance.stand,
      clampedHeight,
    );

    // 3. Post-hit invulnerability check
    if (target.isInvulnerable) {
      return HitResult(
        isHit: false,
        outcome: PaintballHitOutcome.invulnerable,
        targetLane: clampedLane,
        hitHeightY: clampedHeight,
        isDodged: false,
      );
    }

    // 4. Stance exposure check
    final isExposed = PaintballK.isHeightExposed(target.stance, clampedHeight);

    if (isExposed) {
      return HitResult(
        isHit: true,
        outcome: PaintballHitOutcome.hitBody,
        targetLane: clampedLane,
        hitHeightY: clampedHeight,
        isDodged: false,
      );
    }

    // Not exposed: The shot hit the tire stack protecting the player.
    // Check if this counts as an active dodge (ducked or crouched under the shot).
    final isDodge = wouldHitIfStanding && (target.stance == PaintballStance.duck || target.stance == PaintballStance.crouch);

    return HitResult(
      isHit: false,
      outcome: PaintballHitOutcome.hitTire,
      targetLane: clampedLane,
      hitHeightY: clampedHeight,
      isDodged: isDodge,
    );
  }
}
