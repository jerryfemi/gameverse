/// Every tuning number in Tiki Counter lives here, with what it does.
///
/// Units: metres, seconds, metres/second. Change a number here and the whole
/// game follows; logic files never hard-code these.
abstract final class T {
  // ── Loop ──────────────────────────────────────────────────────────────
  /// The sim always steps at exactly 60 Hz, whatever the screen does.
  static const double fixedDt = 1.0 / 60.0;

  /// A slow frame never asks for more than this much sim time
  /// (stops the "spiral of death" after a tab switch).
  static const double maxFrameDt = 0.1;

  // ── Match ─────────────────────────────────────────────────────────────
  /// Full match, real seconds (7 minutes). Half-time at half of this.
  static const double matchSeconds = 420.0;

  // ── Bodies ────────────────────────────────────────────────────────────
  static const double discRadius = 0.7;
  static const double ballRadius = 0.3;

  // ── Disc movement ─────────────────────────────────────────────────────
  static const double runSpeed = 5.0;
  static const double sprintSpeed = 7.0;

  /// Carrying the ball at normal pace.
  static const double carrySpeed = 4.4;

  /// Carrying the ball while holding DASH (heavy touches).
  static const double carryDashSpeed = 6.4;

  /// How fast a disc can change velocity (m/s²). Higher = snappier turns.
  static const double accel = 18.0;

  /// Lower accel while dashing with the ball = wider turning circle.
  static const double accelDashCarry = 8.0;

  /// Distance at which a disc starts slowing down for its target.
  static const double arriveRadius = 1.6;

  /// Speed multiplier after a missed tackle.
  static const double stunSpeedFactor = 0.35;

  // ── Ball physics ──────────────────────────────────────────────────────
  static const double gravity = 9.8;

  /// Constant rolling slow-down (m/s²).
  static const double rollDecel = 3.0;

  /// Extra slow-down proportional to speed (per second).
  static const double rollDrag = 0.12;

  static const double airDrag = 0.05;
  static const double bounceRestitution = 0.4;

  /// Below this downward speed a landing ball stops bouncing.
  static const double bounceMinVz = 1.5;

  /// Horizontal speed kept when the ball bounces.
  static const double bounceKeep = 0.85;

  // ── Carrying / heavy touch ────────────────────────────────────────────
  /// Gap between the carrier's edge and the ball.
  static const double carryGap = 0.05;

  /// Time between touches while dashing with the ball.
  static const double heavyTouchInterval = 0.45;

  /// Ball speed on a heavy touch = carrier speed × this + [heavyTouchBoost].
  static const double heavyTouchMultiplier = 1.15;
  static const double heavyTouchBoost = 1.0;

  // ── Picking up / intercepting ─────────────────────────────────────────
  /// Extra reach beyond touching bodies.
  static const double reachExtra = 0.25;

  /// Balls higher than this fly over everyone.
  static const double reachHeight = 1.0;

  /// Slower than this, the ball is just loose: first disc there takes it.
  static const double looseBallSpeed = 4.5;

  /// Teammates control anything slower than this for sure.
  static const double easyControlSpeed = 14.0;
  static const double hardControlChance = 0.6;

  /// Interception chance = base − (speed − looseBallSpeed) × falloff,
  /// then scaled by how close the ball passes.
  static const double interceptBase = 0.85;
  static const double interceptSpeedFalloff = 0.035;
  static const double interceptMin = 0.12;
  static const double interceptMax = 0.95;

  /// Keeper inside own box stopping a shot.
  static const double keeperSaveChance = 0.75;

  /// Extra reach for a keeper diving at a shot in his own box.
  static const double keeperDiveReach = 1.3;

  /// How far the keeper stands off his line (narrows the angle).
  static const double keeperOffLine = 1.5;

  /// When an interception fails the ball clips the disc.
  static const double deflectKeep = 0.85;
  static const double deflectMaxDeg = 8.0;

  static const double pickupCooldownAfterPass = 0.25;
  static const double pickupCooldownAfterTouch = 0.18;

  // ── Passing ───────────────────────────────────────────────────────────
  static const double passMinSpeed = 6.0;
  static const double passMaxSpeed = 22.0;

  /// Extra roll-on distance so a pass arrives with some pace.
  static const double passArriveExtra = 1.5;
  static const double passPowerExtra = 3.0;

  /// Pass into space (no teammate in the aim cone): 6 m + power × this.
  static const double spacePassBase = 6.0;
  static const double spacePassPower = 14.0;

  static const double passConeDeg = 50.0;
  static const double throughConeDeg = 60.0;

  /// How far ahead of the receiver a through ball goes.
  static const double throughLeadBase = 4.0;
  static const double throughLeadPower = 8.0;

  static const double lobVzBase = 5.5;
  static const double lobVzPower = 2.5;

  /// Lobs land a bit short of the target and roll on.
  static const double lobLandFraction = 0.85;

  static const double shootSpeedBase = 16.0;
  static const double shootSpeedPower = 12.0;
  /// Upward speed on a shot = this × power² (full power can go over the bar).
  static const double shootLiftPower = 6.0;

  /// Throw-ins are short.
  static const double throwMaxSpeed = 13.0;

  // ── Aim error ("passes miss, but only occasionally") ──────────────────
  static const double errPassDeg = 1.5;
  static const double errThroughDeg = 3.0;
  static const double errLobDeg = 4.0;
  static const double errShootDeg = 4.5;

  /// Opponent closer than this adds pressure to the error.
  static const double pressureRadius = 2.5;
  static const double bigMissChance = 0.08;
  static const double bigMissFactor = 3.0;
  static const double speedErrorFraction = 0.05;

  // ── Tackling ──────────────────────────────────────────────────────────
  /// Centre-to-centre distance for a tackle to reach the carrier.
  static const double tackleRange = 1.9;
  static const double tackleWinChance = 0.45;

  /// win < r < this → ball comes loose; above → miss.
  static const double tackleLooseChance = 0.80;
  static const double tackleMissStun = 0.5;
  static const double tackleCooldown = 0.6;
  static const double tackleLooseSpeed = 4.5;

  // ── Pressing (PRESS / DASH off the ball) ──────────────────────────────
  /// Stand this far off the carrier, on the goal side.
  static const double pressStandOff = 1.1;
  static const double pressSpeedFactor = 0.9;

  // ── Switching ─────────────────────────────────────────────────────────
  static const double switchInterval = 0.15;

  /// A new candidate must be this many seconds better to take over.
  static const double switchHysteresis = 0.3;
  static const double goalSideBonus = 0.25;

  /// Assisted switching is off for this long after a manual switch.
  static const double manualSwitchLock = 1.0;

  // ── Set pieces ────────────────────────────────────────────────────────
  static const double restartDelay = 0.6;
  static const double goalCelebration = 1.8;
  static const double setPieceClearance = 3.5;

  /// Nobody touching the ball for this long → the taker passes on its own.
  static const double setPieceAutoTake = 5.0;

  // ── Team brain (placeholder until milestone 4) ────────────────────────
  static const double brainInterval = 0.2;

  // ── Input ─────────────────────────────────────────────────────────────
  /// Holding PASS/SHOOT this long gives full power.
  static const double maxChargeSeconds = 0.9;

  /// Stick values below this count as "no direction".
  static const double stickDeadZone = 0.15;
}
