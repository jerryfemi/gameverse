import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/hit_resolver.dart';

/// Current stage of a paintball duel.
enum PaintballMatchPhase {
  /// 3-2-1 countdown before combat begins.
  countdown,

  /// Active duel within standard 90-second round clock.
  live,

  /// Overtime sudden death: triggered if tied after 90 s. Next hit wins.
  suddenDeath,

  /// Match concluded: 3 hits reached or sudden death settled.
  gameOver,
}

/// Declared winner of a completed match.
enum PaintballWinner {
  you,
  opponent,
  tie,
}

/// Mutable in-game combat state for one player (you or opponent/bot).
class PaintballPlayerState {
  /// Current tire lane (0 to 4).
  int lane = PaintballK.defaultStartLane;

  /// Current stance (stand, crouch, or duck).
  PaintballStance stance = PaintballStance.stand;

  /// Current ammunition count (0 to 5).
  int ammo = PaintballK.initialAmmo;

  /// Hits taken this match (0 to 3).
  int hitsTaken = 0;

  // ─── Sliding State ────────────────────────────────────────────────────────
  bool isSliding = false;
  int slideFromLane = PaintballK.defaultStartLane;
  int slideToLane = PaintballK.defaultStartLane;
  double slideTimer = 0.0;

  /// Normalized slide completion from 0.0 to 1.0.
  double get slideProgress =>
      (slideTimer / PaintballK.slideDurationSeconds).clamp(0.0, 1.0);

  // ─── Stance Transition State ──────────────────────────────────────────────
  bool isStanceChanging = false;
  PaintballStance pendingStance = PaintballStance.stand;
  double stanceChangeTimer = 0.0;

  // ─── Reload Loop State ────────────────────────────────────────────────────
  /// Accumulator for reload while ducked. Every 0.40 s awards +1 ammo.
  double reloadTimer = 0.0;

  // ─── Invulnerability State ────────────────────────────────────────────────
  /// Countdown timer for post-hit grace period (1.0 s).
  double invulnerableTimer = 0.0;

  bool get isInvulnerable => invulnerableTimer > 0.0;

  // ─── Career / Match Analytics ─────────────────────────────────────────────
  int shotsFired = 0;
  int shotsHit = 0;
  int timesDodged = 0;

  /// Current continuous survival time without taking a hit (seconds).
  double currentSurvivalSeconds = 0.0;

  /// Longest survival streak this match (seconds).
  double longestSurvivalSeconds = 0.0;

  /// Whether the player has taken maximum damage (3 hits) and lost.
  bool get isEliminated => hitsTaken >= PaintballK.hitsToWin;

  /// Shooting accuracy percentage (0.0 to 100.0).
  double get accuracyPercent => shotsFired > 0
      ? (shotsHit / shotsFired * 100.0).clamp(0.0, 100.0)
      : 0.0;

  /// Creates a target snapshot evaluated by [HitResolver].
  TargetPlayerSnapshot toSnapshot() {
    return TargetPlayerSnapshot(
      lane: lane,
      stance: stance,
      isSliding: isSliding,
      slideFromLane: isSliding ? slideFromLane : null,
      slideToLane: isSliding ? slideToLane : null,
      slideProgress: isSliding ? slideProgress : 0.0,
      isInvulnerable: isInvulnerable,
    );
  }

  // ─── Player Actions ───────────────────────────────────────────────────────

  /// Initiates a slide to an adjacent lane (-1 for left, +1 for right).
  ///
  /// Returns true if the slide successfully started.
  bool trySlide(int direction) {
    if (isSliding || isEliminated) return false;

    final target = (lane + direction).clamp(PaintballK.minLane, PaintballK.maxLane);
    if (target == lane) return false;

    isSliding = true;
    slideFromLane = lane;
    slideToLane = target;
    slideTimer = 0.0;

    // Reset reload accumulator if moving
    reloadTimer = 0.0;
    return true;
  }

  /// Initiates a stance change (duck, crouch, or stand).
  ///
  /// Returns true if stance transition began.
  bool tryChangeStance(PaintballStance newStance) {
    if (stance == newStance || isEliminated) return false;

    stance = newStance;
    isStanceChanging = true;
    stanceChangeTimer = 0.0;

    // If leaving duck stance, reset reload progress
    if (newStance != PaintballStance.duck) {
      reloadTimer = 0.0;
    }
    return true;
  }

  /// Whether the player can fire a paintball right now.
  bool get canFire =>
      ammo > 0 &&
      stance != PaintballStance.duck &&
      !isSliding &&
      !isEliminated;

  /// Fires a paintball, consuming 1 ammo.
  ///
  /// Returns true if fired.
  bool tryFire() {
    if (!canFire) return false;
    ammo--;
    shotsFired++;
    return true;
  }

  /// Registers a hit received by this player.
  ///
  /// Returns true if hit registered damage (was not invulnerable or already eliminated).
  bool applyDamage() {
    if (isInvulnerable || isEliminated) return false;

    hitsTaken++;
    invulnerableTimer = PaintballK.hitInvulnerabilitySeconds;

    // Update survival streak
    if (currentSurvivalSeconds > longestSurvivalSeconds) {
      longestSurvivalSeconds = currentSurvivalSeconds;
    }
    currentSurvivalSeconds = 0.0;
    return true;
  }

  /// Advances physics, slide progress, stance transitions, and duck-reload.
  void tick(double dt) {
    if (isEliminated) return;

    // 1. Advance survival timer
    currentSurvivalSeconds += dt;
    if (currentSurvivalSeconds > longestSurvivalSeconds) {
      longestSurvivalSeconds = currentSurvivalSeconds;
    }

    // 2. Advance invulnerability
    if (invulnerableTimer > 0.0) {
      invulnerableTimer = (invulnerableTimer - dt).clamp(0.0, double.infinity);
    }

    // 3. Advance sliding
    if (isSliding) {
      slideTimer += dt;
      if (slideTimer >= PaintballK.slideDurationSeconds) {
        lane = slideToLane;
        isSliding = false;
        slideTimer = 0.0;
      }
    }

    // 4. Advance stance cooldown
    if (isStanceChanging) {
      stanceChangeTimer += dt;
      if (stanceChangeTimer >= PaintballK.stanceTransitionSeconds) {
        isStanceChanging = false;
        stanceChangeTimer = 0.0;
      }
    }

    // 5. Automatic reload loop (only while ducked)
    if (stance == PaintballStance.duck && ammo < PaintballK.maxAmmo && !isSliding) {
      reloadTimer += dt;
      if (reloadTimer >= PaintballK.reloadIntervalPerBallSeconds) {
        ammo = (ammo + 1).clamp(0, PaintballK.maxAmmo);
        reloadTimer = 0.0;
      }
    } else {
      reloadTimer = 0.0;
    }
  }

  /// Resets state for a new round.
  void reset({int startLane = PaintballK.defaultStartLane}) {
    lane = startLane;
    stance = PaintballStance.stand;
    ammo = PaintballK.initialAmmo;
    hitsTaken = 0;
    isSliding = false;
    slideFromLane = startLane;
    slideToLane = startLane;
    slideTimer = 0.0;
    isStanceChanging = false;
    stanceChangeTimer = 0.0;
    reloadTimer = 0.0;
    invulnerableTimer = 0.0;
    shotsFired = 0;
    shotsHit = 0;
    timesDodged = 0;
    currentSurvivalSeconds = 0.0;
    longestSurvivalSeconds = 0.0;
  }
}

/// SSOT deterministic match manager for a Paintball duel.
class PaintballMatchState {
  PaintballMatchPhase phase = PaintballMatchPhase.countdown;

  /// Countdown before match start (seconds).
  double countdownRemaining = 3.0;

  /// Main match clock (counts down from 90 s).
  double timeRemaining = PaintballK.matchDurationSeconds.toDouble();

  /// Sudden death countdown if tied at 0:00 (30 s).
  double suddenDeathRemaining = PaintballK.suddenDeathDurationSeconds.toDouble();

  /// The local player state (you / Swat).
  final PaintballPlayerState you = PaintballPlayerState();

  /// The opponent state (bot or remote / Worker).
  final PaintballPlayerState opponent = PaintballPlayerState();

  PaintballWinner? winner;

  /// Starts or restarts a match.
  void startMatch() {
    phase = PaintballMatchPhase.countdown;
    countdownRemaining = 3.0;
    timeRemaining = PaintballK.matchDurationSeconds.toDouble();
    suddenDeathRemaining = PaintballK.suddenDeathDurationSeconds.toDouble();
    winner = null;

    you.reset(startLane: PaintballK.defaultStartLane);
    opponent.reset(startLane: PaintballK.defaultStartLane);
  }

  /// Advances match clock, countdown, and player state machines.
  void tick(double dt) {
    switch (phase) {
      case PaintballMatchPhase.countdown:
        countdownRemaining -= dt;
        if (countdownRemaining <= 0.0) {
          countdownRemaining = 0.0;
          phase = PaintballMatchPhase.live;
        }
        return;

      case PaintballMatchPhase.live:
        timeRemaining -= dt;
        you.tick(dt);
        opponent.tick(dt);

        // Check 3-hit win condition
        if (opponent.isEliminated || you.isEliminated) {
          _endMatch();
          return;
        }

        // Timer expiration
        if (timeRemaining <= 0.0) {
          timeRemaining = 0.0;
          if (you.hitsTaken < opponent.hitsTaken) {
            winner = PaintballWinner.you;
            phase = PaintballMatchPhase.gameOver;
          } else if (opponent.hitsTaken < you.hitsTaken) {
            winner = PaintballWinner.opponent;
            phase = PaintballMatchPhase.gameOver;
          } else {
            // Tied: enter sudden death
            phase = PaintballMatchPhase.suddenDeath;
          }
        }
        return;

      case PaintballMatchPhase.suddenDeath:
        suddenDeathRemaining -= dt;
        you.tick(dt);
        opponent.tick(dt);

        // Next hit wins
        if (opponent.isEliminated || you.isEliminated || you.hitsTaken != opponent.hitsTaken) {
          _endMatch();
          return;
        }

        if (suddenDeathRemaining <= 0.0) {
          suddenDeathRemaining = 0.0;
          winner = PaintballWinner.tie;
          phase = PaintballMatchPhase.gameOver;
        }
        return;

      case PaintballMatchPhase.gameOver:
        return;
    }
  }

  void _endMatch() {
    phase = PaintballMatchPhase.gameOver;
    if (opponent.hitsTaken > you.hitsTaken) {
      winner = PaintballWinner.you;
    } else if (you.hitsTaken > opponent.hitsTaken) {
      winner = PaintballWinner.opponent;
    } else {
      winner = PaintballWinner.tie;
    }
  }
}
