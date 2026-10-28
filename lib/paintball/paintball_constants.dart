/// Player stance in the arena.
enum PaintballStance {
  /// Standing upright: exposed above the tyre top (height 0.55–1.0), can shoot.
  stand,

  /// Crouched behind tire stack: head & shoulders exposed (height 0.55–0.72), can peek & shoot.
  crouch,

  /// Ducked completely behind tire stack: immune (exposure 0.0), cannot shoot, auto-reloads.
  duck,
}

/// Hit outcome resolved when a paintball lands at t0 + 400 ms.
enum PaintballHitOutcome {
  /// Direct hit on exposed player body. Deals 1 damage.
  hitBody,

  /// Splat on the tire stack (player was in lane but height hit the tire, or player was ducked).
  hitTire,

  /// Shot missed the player's lane completely (splats on far wall/grass/empty tire).
  missedLane,

  /// Player is currently in post-hit invulnerability grace period.
  invulnerable,
}

/// Single Source of Truth (SSOT) for all tunable Paintball parameters.
///
/// Follows GamePigeon-style real-time tactical duel feel:
/// - 5 tire lanes (0–4) facing each other across an arena.
/// - 3 stances: Stand, Crouch, Duck.
/// - 400 ms deterministic ball flight.
/// - Target-side hit evaluation at landing time.
/// - Max 5 ammo, reload only while ducked.
/// - 3 hits to win, 90 s match timer with sudden death.
abstract final class PaintballK {
  // ─── Lanes & Field Geometry ───────────────────────────────────────────────

  /// Total number of tire lanes on each side (0 to 4).
  static const int laneCount = 5;

  /// Default starting lane for both players (center lane).
  static const int defaultStartLane = 2;

  /// Minimum lane index.
  static const int minLane = 0;

  /// Maximum lane index.
  static const int maxLane = 4;

  /// Converts an opponent's lane index to the corresponding lane index on your screen.
  ///
  /// Your lane 0 (far left) faces the opponent's lane 4 (their far right).
  /// Formula: `oppLaneOnMyScreen = 4 - oppLane`.
  static int mirrorLane(int lane) => (maxLane - lane).clamp(minLane, maxLane);

  /// Normalized horizontal center for a lane index (0..4) in range [-1.0, 1.0].
  ///
  /// Lane 0 -> -1.0
  /// Lane 1 -> -0.5
  /// Lane 2 ->  0.0
  /// Lane 3 ->  0.5
  /// Lane 4 ->  1.0
  static double laneToAimX(int lane) {
    final clamped = lane.clamp(minLane, maxLane);
    return (clamped - 2) * 0.5;
  }

  /// Converts a normalized horizontal aim coordinate [-1.0, 1.0] into a lane index (0..4).
  ///
  /// Thresholds (with half-step boundaries):
  /// - Lane 0: aimX < -0.75
  /// - Lane 1: -0.75 <= aimX < -0.25
  /// - Lane 2: -0.25 <= aimX < 0.25
  /// - Lane 3:  0.25 <= aimX < 0.75
  /// - Lane 4: aimX >= 0.75
  static int aimXToLane(double aimX) {
    if (aimX < -0.75) return 0;
    if (aimX < -0.25) return 1;
    if (aimX < 0.25) return 2;
    if (aimX < 0.75) return 3;
    return 4;
  }

  // ─── Stances & Exposure Ranges (normalized height 0.0 ground to 1.0 head) ──

  /// Height of the tyre stack's top as a fraction of a standing player's height,
  /// measured from the player's feet. Matches the baked sprites: the duck pose
  /// tops out at ~0.48 (hidden), the crouch pose at ~0.70 (head and shoulders
  /// peek out). See PAINTBALL_SPRITES.md.
  static const double tyreCoverHeight = 0.55;

  /// Minimum exposed height for [PaintballStance.stand] (below this the tyres cover you).
  static const double standMinExposureY = tyreCoverHeight;

  /// Maximum exposed height for [PaintballStance.stand] (top of head).
  static const double standMaxExposureY = 1.00;

  /// Minimum exposed height for [PaintballStance.crouch] (peeking over top tire).
  static const double crouchMinExposureY = tyreCoverHeight;

  /// Maximum exposed height for [PaintballStance.crouch] (top of the crouched head).
  static const double crouchMaxExposureY = 0.72;

  /// Returns true if [heightY] (0.0–1.0) is exposed for the given [stance].
  ///
  /// When [PaintballStance.duck] is active, the player is completely hidden (0% exposure).
  static bool isHeightExposed(PaintballStance stance, double heightY) {
    return switch (stance) {
      PaintballStance.stand =>
        heightY >= standMinExposureY && heightY <= standMaxExposureY,
      PaintballStance.crouch =>
        heightY >= crouchMinExposureY && heightY <= crouchMaxExposureY,
      PaintballStance.duck => false,
    };
  }

  // ─── Timings & Physics Durations ──────────────────────────────────────────

  /// Fixed flight duration of a paintball from launch to impact (seconds).
  ///
  /// Constant 400 ms provides fair, readable network latency compensation.
  static const double ballFlightSeconds = 0.40;

  /// Fixed flight duration in milliseconds (400 ms).
  static const int ballFlightMs = 400;

  /// Time required to slide horizontally between adjacent lanes (seconds).
  static const double slideDurationSeconds = 0.35;

  /// Time required to slide horizontally between adjacent lanes (milliseconds).
  static const int slideDurationMs = 350;

  /// Fraction of slide duration during which the player counts as exposed in
  /// BOTH the departure lane and the destination lane.
  static const double slideDualVulnerabilityRatio = 0.50;

  /// Time required to transition between stances (seconds).
  static const double stanceTransitionSeconds = 0.15;

  /// Duration of invulnerability granted after being hit (seconds).
  static const double hitInvulnerabilitySeconds = 1.0;

  /// Duration of invulnerability in milliseconds.
  static const int hitInvulnerabilityMs = 1000;

  // ─── Ammo & Reload Rules ──────────────────────────────────────────────────

  /// Maximum ammo capacity.
  static const int maxAmmo = 5;

  /// Initial ammo at round start.
  static const int initialAmmo = 5;

  /// Time required to reload a single paintball while ducked (seconds).
  static const double reloadIntervalPerBallSeconds = 0.40;

  /// Time required to reload a single paintball while ducked (milliseconds).
  static const int reloadIntervalPerBallMs = 400;

  // ─── Match Rules & Scoring ────────────────────────────────────────────────

  /// Hits required to win the match.
  static const int hitsToWin = 3;

  /// Standard round duration in seconds.
  static const int matchDurationSeconds = 90;

  /// Sudden death round duration in seconds.
  static const int suddenDeathDurationSeconds = 30;

  // ─── Camera & 2.5D Parallax ───────────────────────────────────────────────

  /// Number of lanes visible on screen (~2.8 creates tight over-the-shoulder framing).
  static const double visibleLanes = 2.8;

  /// Peak vertical arc offset (normalized screen height fraction) at mid-flight (t = 0.5).
  static const double trajectoryArcPeak = 0.08;

  /// Size multiplier for paintball at shooter muzzle (t = 0).
  static const double ballStartScale = 1.00;

  /// Size multiplier for paintball at far opponent plane (t = 1).
  static const double ballEndScale = 0.28;

  /// Camera look-at horizontal pan limit as a fraction of screen width (±28%).
  static const double cameraMaxPanFraction = 0.28;

  /// Vertical camera dip when player crouches (normalized screen height fraction).
  static const double cameraCrouchDipFraction = 0.05;

  /// Vertical camera dip when player ducks (normalized screen height fraction).
  static const double cameraDuckDipFraction = 0.11;

  /// Camera spring dampening settling duration (seconds).
  static const double cameraSettleSeconds = 0.25;

  /// Parallax shift multiplier for background layer (horizontal).
  static const double parallaxBackdrop = 0.20;

  /// Parallax shift multiplier for background layer (vertical dip).
  static const double parallaxBackdropY = 0.15;

  /// Parallax shift multiplier for far tire & opponent layer (horizontal).
  static const double parallaxFarTires = 0.85;

  /// Parallax shift multiplier for far tire & opponent layer (vertical dip).
  static const double parallaxFarTiresY = 0.65;

  // ─── Screen layout (fractions of screen height) ───────────────────────────

  /// Ground line under the opponent's feet.
  static const double farGroundY = 0.52;

  /// On-screen height of the standing opponent.
  static const double oppStandHeight = 0.13;

  /// Ground line under your own player's feet.
  static const double nearGroundY = 0.97;

  /// On-screen height of your standing player (over-the-shoulder, close).
  static const double youStandHeight = 0.40;

  /// Width of the play stage as a fraction of screen height (9:16 portrait).
  /// Lane spacing comes from this stage, never from the window width, so a
  /// wide window shows more scenery at the sides with the same layout.
  static const double stageAspect = 0.5625;

  /// Far-row lane spacing relative to your row (perspective). At 0.5 all five
  /// far stacks and the opponent fit on screen at once.
  static const double farLaneScale = 0.5;

  /// Furthest you can aim from straight ahead, in aimX units (1.0 = two lanes).
  /// 2.0 lets you reach any far lane from any lane.
  static const double maxAimOffset = 2.0;

  /// Camera pan from aiming, as a fraction of stage width per 1.0 of aim offset.
  static const double aimPanFraction = 0.10;

  /// Ground line under your own tyre stacks (a step in front of your feet).
  static const double nearTyreGroundY = 0.90;

  /// Front-lip height of your own tyre stacks, as a fraction of screen height.
  /// The stack's top surface adds roughly 40% more above this line.
  static const double nearTyreCoverHeight = 0.22;

  /// Reticle snap-assist radius in logical pixels.
  static const double reticleSnapRadiusPx = 20.0;
}
