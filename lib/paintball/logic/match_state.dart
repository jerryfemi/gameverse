import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/hit_resolver.dart';

/// Current stage of a paintball duel.
enum PaintballMatchPhase {
  /// Arena overview pan + player walk-in before the countdown.
  intro,

  /// 3-2-1 countdown before combat begins.
  countdown,

  /// Active duel within standard 90-second round clock.
  live,

  /// Overtime sudden death: triggered if tied after the round clock. Next hit wins.
  suddenDeath,

  /// Between rounds: the "ROUND 2" banner (then the 3-2-1 countdown).
  roundOver,

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

  /// New round: position, stance, ammo and hits reset; match stats
  /// (shots, accuracy, dodges, longest alive) carry on.
  void resetForRound({int startLane = PaintballK.defaultStartLane}) {
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
    currentSurvivalSeconds = 0.0;
  }

  /// Resets everything for a new match.
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
  PaintballMatchPhase phase = PaintballMatchPhase.intro;

  /// Intro length: close-up on the opponent (0–1.5 s), pull-back sweep across
  /// the arena (1.5–3.0 s), you walk in (3.0–4.2 s), hold (to 4.5 s).
  /// Plays on every match, rematch included; a tap skips it.
  static const double introDurationSeconds = 4.5;

  /// Elapsed time within intro phase.
  double introElapsed = 0.0;

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

  /// Match winner (set at gameOver, decided on rounds).
  PaintballWinner? winner;

  // ─── Rounds (best of 3) ───────────────────────────────────────────────────
  int round = 1;
  int youRounds = 0;
  int opponentRounds = 0;

  /// Who took the round that just ended (shown on the break banner).
  PaintballWinner? roundWinner;

  /// Hits landed per finished round: (you, opponent).
  final List<(int, int)> roundHits = [];

  double roundBreakRemaining = 0.0;

  /// Online: wait at the break for the host's next-round start instead of
  /// running into it on the local clock ([beginNextRound]).
  bool holdBetweenRounds = false;

  /// Bumped each time a new round begins, so the game can clear paint,
  /// balls and poses.
  int roundSerial = 0;

  /// Total hits each player landed across the match.
  bool get _inRound =>
      phase == PaintballMatchPhase.live || phase == PaintballMatchPhase.suddenDeath;
  int get youHitsLanded =>
      roundHits.fold(0, (a, r) => a + r.$1) + (_inRound ? opponent.hitsTaken : 0);
  int get opponentHitsLanded =>
      roundHits.fold(0, (a, r) => a + r.$2) + (_inRound ? you.hitsTaken : 0);

  bool get isFinalRound => round >= PaintballK.maxRounds;

  /// Starts or restarts a match.
  void startMatch({bool skipIntro = false}) {
    if (skipIntro) {
      phase = PaintballMatchPhase.countdown;
      introElapsed = introDurationSeconds;
    } else {
      phase = PaintballMatchPhase.intro;
      introElapsed = 0.0;
    }
    countdownRemaining = 3.0;
    timeRemaining = PaintballK.matchDurationSeconds.toDouble();
    suddenDeathRemaining = PaintballK.suddenDeathDurationSeconds.toDouble();
    winner = null;
    round = 1;
    youRounds = 0;
    opponentRounds = 0;
    roundWinner = null;
    roundHits.clear();
    roundBreakRemaining = 0.0;
    roundSerial++;

    you.reset(startLane: PaintballK.defaultStartLane);
    opponent.reset(startLane: PaintballK.defaultStartLane);
  }

  /// Starts the next round now, with [countdownSeconds] of 3-2-1 left (online
  /// passes the time until the shared start). Optional [result] lets the host
  /// settle the round that just ended, so both sides agree on the score.
  void beginNextRound({double countdownSeconds = 3.0, PaintballWinner? result}) {
    if (phase == PaintballMatchPhase.gameOver) {
      // We thought it was over; the host's verdict says another round.
      if (result != null && result != roundWinner) _rescore(result);
      if (phase == PaintballMatchPhase.gameOver) return;
    } else if (phase == PaintballMatchPhase.live || phase == PaintballMatchPhase.suddenDeath) {
      _endRound(forced: result); // the host ended it before we did
      if (phase == PaintballMatchPhase.gameOver) return;
    } else if (result != null && result != roundWinner) {
      _rescore(result);
      if (phase == PaintballMatchPhase.gameOver) return;
    }
    round++;
    roundSerial++;
    phase = PaintballMatchPhase.countdown;
    countdownRemaining = countdownSeconds.clamp(0.3, 6.0);
    timeRemaining = PaintballK.matchDurationSeconds.toDouble();
    suddenDeathRemaining = PaintballK.suddenDeathDurationSeconds.toDouble();
    you.resetForRound();
    opponent.resetForRound();
  }

  /// Host's verdict differs from ours (a hit landed right at the buzzer).
  void _rescore(PaintballWinner result) {
    if (roundWinner == PaintballWinner.you) youRounds--;
    if (roundWinner == PaintballWinner.opponent) opponentRounds--;
    roundWinner = result;
    if (result == PaintballWinner.you) youRounds++;
    if (result == PaintballWinner.opponent) opponentRounds++;
    if (phase == PaintballMatchPhase.gameOver) {
      phase = PaintballMatchPhase.roundOver; // re-decide below
      winner = null;
    }
    _maybeEndMatch();
  }

  /// Online: the host ended the match (final round) with [result].
  void settleFinalRound(PaintballWinner result) {
    if (phase == PaintballMatchPhase.live || phase == PaintballMatchPhase.suddenDeath) {
      _endRound(forced: result);
    } else if (result != roundWinner && phase != PaintballMatchPhase.gameOver) {
      _rescore(result);
    }
  }

  /// Skips the intro sequence and jumps straight to countdown.
  void skipIntro() {
    if (phase == PaintballMatchPhase.intro) {
      phase = PaintballMatchPhase.countdown;
      introElapsed = introDurationSeconds;
    }
  }

  /// Advances match clock, countdown, and player state machines.
  void tick(double dt) {
    switch (phase) {
      case PaintballMatchPhase.intro:
        introElapsed += dt;
        if (introElapsed >= introDurationSeconds) {
          phase = PaintballMatchPhase.countdown;
        }
        return;

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
          _endRound();
          return;
        }

        // Timer expiration
        if (timeRemaining <= 0.0) {
          timeRemaining = 0.0;
          if (you.hitsTaken != opponent.hitsTaken) {
            _endRound();
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
          _endRound();
          return;
        }

        if (suddenDeathRemaining <= 0.0) {
          suddenDeathRemaining = 0.0;
          _endRound(); // tied round: nobody scores it
        }
        return;

      case PaintballMatchPhase.roundOver:
        if (holdBetweenRounds) return; // online: the host's start drives it
        roundBreakRemaining -= dt;
        if (roundBreakRemaining <= 0.0) beginNextRound();
        return;

      case PaintballMatchPhase.gameOver:
        return;
    }
  }

  /// Forfeit / opponent left: the match ends now, keeping this round's hits.
  void endByForfeit({required bool youWin}) {
    if (phase == PaintballMatchPhase.gameOver) return;
    if (phase == PaintballMatchPhase.live || phase == PaintballMatchPhase.suddenDeath) {
      roundHits.add((opponent.hitsTaken, you.hitsTaken));
    }
    winner = youWin ? PaintballWinner.you : PaintballWinner.opponent;
    phase = PaintballMatchPhase.gameOver;
  }

  void _endRound({PaintballWinner? forced}) {
    final w = forced ??
        (opponent.hitsTaken > you.hitsTaken
            ? PaintballWinner.you
            : you.hitsTaken > opponent.hitsTaken
                ? PaintballWinner.opponent
                : PaintballWinner.tie);
    roundWinner = w;
    if (w == PaintballWinner.you) youRounds++;
    if (w == PaintballWinner.opponent) opponentRounds++;
    roundHits.add((opponent.hitsTaken, you.hitsTaken));
    phase = PaintballMatchPhase.roundOver;
    roundBreakRemaining = PaintballK.roundBreakSeconds;
    _maybeEndMatch();
  }

  void _maybeEndMatch() {
    final decided = youRounds >= PaintballK.roundsToWin ||
        opponentRounds >= PaintballK.roundsToWin ||
        round >= PaintballK.maxRounds;
    if (!decided) return;
    phase = PaintballMatchPhase.gameOver;
    winner = youRounds > opponentRounds
        ? PaintballWinner.you
        : opponentRounds > youRounds
            ? PaintballWinner.opponent
            : PaintballWinner.tie;
  }
}
