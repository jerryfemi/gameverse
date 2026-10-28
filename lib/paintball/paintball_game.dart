import 'dart:math' as math;
import 'dart:ui' show Canvas;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flutter/services.dart';
import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/logic/bot_brain.dart';
import 'package:b_ball/paintball/logic/hit_resolver.dart';
import 'package:b_ball/paintball/components/backdrop.dart';
import 'package:b_ball/paintball/components/tyre_stack.dart';
import 'package:b_ball/paintball/components/player_sprite.dart';
import 'package:b_ball/paintball/components/reticle.dart';
import 'package:b_ball/paintball/components/paintball.dart';
import 'package:b_ball/paintball/components/splat.dart';
import 'package:b_ball/paintball/net/paintball_net_link.dart';
import 'package:b_ball/paintball/net/paintball_protocol.dart';

/// Flame game engine for Paintball 1v1 duels.
///
/// Follows Paintball Plan §5 & §7:
/// - 60 fps fixed-frame budget with zero per-frame heap allocations.
/// - 5-lane 2.5D world projection with camera pan spring damping.
/// - Autonomous Bot AI integration ([PaintballBotBrain]).
/// - Deterministic ballistic trajectory arcs and target-side hit resolution.
class PaintballGame extends FlameGame with KeyboardEvents {
  final PaintballMatchState match = PaintballMatchState();
  late final PaintballBotBrain botBrain;

  // ─── Scene Components ─────────────────────────────────────────────────────
  late final PaintballBackdrop backdrop;
  late final ReticleComponent reticle;
  late final PaintballPlayerComponent playerComponent;
  late final PaintballPlayerComponent opponentComponent;
  late final SplatCanvasComponent splatCanvas;

  final List<TyreStackComponent> farTires = [];
  final List<TyreStackComponent> nearTires = [];

  // Pooled projectiles
  static const int maxActiveBalls = 8;
  final List<FlyingPaintball> _ballPool = [];
  final List<IncomingProjectile> _activeProjectiles = [];

  // ─── Camera Dual-Axis Spring ──────────────────────────────────────────────
  double cameraPanOffset = 0.0;
  double _targetCameraPan = 0.0;
  double cameraDipOffset = 0.0;
  double _targetCameraDip = 0.0;

  // ─── Lifecycle & Layout Cache ─────────────────────────────────────────────
  bool _isReady = false;
  final Vector2 _muzzle = Vector2.zero();
  int _roundSerialSeen = -1;
  int _posesRound = 0;

  /// Seconds since the match ended. The results card waits for this so the
  /// death and win animations play first.
  double gameOverSeconds = 0.0;

  /// How long the results card waits after the match ends (the death clip
  /// runs ~2.8 s).
  static const double resultsDelaySeconds = 2.6;

  bool get showResults =>
      match.phase == PaintballMatchPhase.gameOver &&
      gameOverSeconds >= resultsDelaySeconds;
  double _cachedWidth = 0.0;
  double _cachedHeight = 0.0;

  PaintballGame({int? botSeed, this.online = false}) {
    botBrain = PaintballBotBrain(seed: botSeed);
  }

  // ─── Live 1v1 (RTDB) ──────────────────────────────────────────────────────
  // Online, the opponent is driven by network events instead of the bot. The
  // target decides every hit; your own shots wait for their verdict.

  /// True for a live 1v1. The match waits (no intro) until [startOnline].
  final bool online;

  /// Set by the session once connected.
  PaintballNetLink? net;

  /// Online: true until both players are in and the shared start is known.
  bool waitingForOpponent = true;

  bool _matchOverSent = false;
  final Set<String> _resolvedShots = <String>{};
  final Map<String, double> _myShotAim = <String, double>{};
  double? _pendingStartElapsed;
  int _pendingStartAtMs = 0;

  // Last state sent, so writes happen only on change (never per frame).
  int _sentLane = -1, _sentFrom = -2, _sentStance = -1, _sentAmmo = -1;
  int _sentHits = -1, _sentAim = 9, _aimBucket = 0;

  /// Bumped only when something the HUD or controls show has changed (hits,
  /// ammo, stance, lane, phase, whole clock seconds). The Flutter overlays
  /// listen to this instead of rebuilding on a timer.
  final ValueNotifier<int> uiVersion = ValueNotifier<int>(0);

  /// 0..1 while the arena loads (shown by the screen's loading card).
  final ValueNotifier<double> loadProgress = ValueNotifier<double>(0.0);
  int _uiSignature = 0;

  void _publishUi() {
    final y = match.you, o = match.opponent;
    final sig = Object.hash(
      match.phase.index,
      y.hitsTaken,
      o.hitsTaken,
      y.ammo,
      y.stance.index,
      y.isSliding,
      y.lane,
      canAct,
      playerCanFire,
      match.timeRemaining.ceil(),
      match.suddenDeathRemaining.ceil(),
      match.countdownRemaining.ceil(),
      showResults,
      waitingForOpponent,
      match.round,
      match.youRounds,
      match.opponentRounds,
    );
    if (sig != _uiSignature) {
      _uiSignature = sig;
      uiVersion.value++;
    }
  }

  /// Opponent's upper-body pose from the network (-1, 0, 1).
  int remoteAimBucket = 0;

  int get aimBucket => _aimBucket;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Backdrop (Priority 0)
    backdrop = PaintballBackdrop();
    await add(backdrop);
    loadProgress.value = 0.35;

    // 2. Far Tires & Near Tires
    for (int lane = 0; lane < PaintballK.laneCount; lane++) {
      final farTire = TyreStackComponent(lane: lane, isNear: false);
      farTires.add(farTire);
      await add(farTire);

      final nearTire = TyreStackComponent(lane: lane, isNear: true);
      nearTires.add(nearTire);
      await add(nearTire);
    }

    // 3. Opponent Component (Priority 20)
    opponentComponent = PaintballPlayerComponent(
      isOpponent: true,
      state: match.opponent,
    );
    await add(opponentComponent);
    loadProgress.value = 0.7;

    // 4. Splat Canvas (Priority 45)
    splatCanvas = SplatCanvasComponent();
    await add(splatCanvas);

    // 5. In-flight Paintball Pool (Priority 40)
    for (int i = 0; i < maxActiveBalls; i++) {
      final ball = FlyingPaintball(onLanding: _handleBallLanding);
      _ballPool.add(ball);
      await add(ball);
    }

    // 6. Foreground Player (Priority 60)
    playerComponent = PaintballPlayerComponent(
      isOpponent: false,
      state: match.you,
    );
    await add(playerComponent);
    loadProgress.value = 0.95;

    // 7. Reticle (Priority 70)
    reticle = ReticleComponent();
    await add(reticle);
    loadProgress.value = 1.0;

    if (!online) {
      match.startMatch();
      waitingForOpponent = false;
    }

    _isReady = true;

    final pending = _pendingStartElapsed;
    if (pending != null) {
      _pendingStartElapsed = null;
      startOnline(pending +
          (DateTime.now().millisecondsSinceEpoch - _pendingStartAtMs) / 1000.0);
    }

    if (_cachedWidth > 0 && _cachedHeight > 0) {
      _layoutScene(_cachedWidth, _cachedHeight);
    } else if (size.x > 0 && size.y > 0) {
      _cachedWidth = size.x;
      _cachedHeight = size.y;
      _layoutScene(size.x, size.y);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _cachedWidth = size.x;
    _cachedHeight = size.y;
    if (_isReady) {
      _layoutScene(size.x, size.y);
    }
  }

  // ─── Stage geometry ───────────────────────────────────────────────────────
  // Everything is laid out on a fixed 9:16 stage centred on screen, so a wide
  // window gets the same tyre layout (plus more scenery at the sides).

  double _stageWidth(double w, double h) =>
      math.min(w, h * PaintballK.stageAspect);

  /// Lane spacing of your own row (near tyres, your player).
  double _nearStep(double w, double h) =>
      _stageWidth(w, h) / PaintballK.visibleLanes;

  /// Lane spacing of the opponent's row: compact, so all five lanes are on screen.
  double _farStep(double w, double h) =>
      _nearStep(w, h) * PaintballK.farLaneScale;

  /// Your lane as a continuous value while sliding (0..4).
  double get _youContinuousLane => match.you.isSliding
      ? match.you.slideFromLane +
            (match.you.slideToLane - match.you.slideFromLane) *
                match.you.slideProgress
      : match.you.lane.toDouble();

  // ─── Body-relative aim ────────────────────────────────────────────────────
  // The drag sets an angle relative to where you face (_aimOffset). Sliding
  // carries the reticle with you at the same angle. reticle.aimX is the
  // resulting field position (-1..1), which the hit check and network use.
  double _aimOffset = 0.0;

  void _syncAimFromOffset() {
    final facing = (_youContinuousLane - 2.0) * 0.5; // laneToAimX, continuous
    reticle.aimX = (facing + _aimOffset).clamp(-1.0, 1.0);
  }

  void _layoutScene(double w, double h) {
    final laneStep = _nearStep(w, h);
    final farStep = _farStep(w, h);
    final centerX = w * 0.5;

    // Position Far Tires (at y ≈ 36% - 48%)
    // Each tire stack is chunky and wide (~80% of lane step)
    // The far tyre's top sits at tyreCoverHeight of a standing opponent, so a
    // ducked opponent is hidden and a crouched one peeks out (matches HitResolver).
    final oppH = h * PaintballK.oppStandHeight;
    final farGround = h * PaintballK.farGroundY;
    final farTireW = farStep;
    final farY = farGround - oppH * PaintballK.tyreCoverHeight;
    final farTireH = (farGround + h * 0.012) - farY;

    for (int i = 0; i < farTires.length; i++) {
      final cx = centerX + ((i - 2) * farStep);
      farTires[i].size.setValues(farTireW, farTireH);
      farTires[i].position.setValues(cx - farTireW * 0.5, farY);
    }

    // Near tyres: box top = the stack's front lip (cover line), box bottom =
    // its ground. The stack's top surface draws a little above the box.
    // Sized from height, not lane width, so your own cover never walls off
    // the far field.
    final nearGround = h * PaintballK.nearTyreGroundY;
    final nearTireH = h * PaintballK.nearTyreCoverHeight;
    final nearTireW = laneStep * 0.9;
    final nearY = nearGround - nearTireH;

    for (int i = 0; i < nearTires.length; i++) {
      final cx = centerX + ((i - 2) * laneStep);
      nearTires[i].size.setValues(nearTireW, nearTireH);
      nearTires[i].position.setValues(cx - nearTireW * 0.5, nearY);
    }

    // Players: position = ground point under the feet, standHeight = on-screen
    // height of the standing pose. Stance poses are baked into the sprites.
    playerComponent.standHeight = h * PaintballK.youStandHeight;
    opponentComponent.standHeight = oppH;

    _updatePlayerPositions(w, h);
    _updateCameraTarget();
    _updateReticlePosition();
  }

  void _updatePlayerPositions(double w, double h) {
    final laneStep = _nearStep(w, h);
    final farStep = _farStep(w, h);
    final centerX = w * 0.5;

    // 1. Local Player (Swat)
    double playerLaneX;
    if (match.you.isSliding) {
      final fromX = centerX + ((match.you.slideFromLane - 2) * laneStep);
      final toX = centerX + ((match.you.slideToLane - 2) * laneStep);
      playerLaneX = fromX + (toX - fromX) * match.you.slideProgress;
    } else {
      playerLaneX = centerX + ((match.you.lane - 2) * laneStep);
    }

    // Ground point evaluation (including intro walk-in sequence: 2.5–4.0s)
    double youGroundY = h * PaintballK.nearGroundY;
    double oppGroundY = h * PaintballK.farGroundY;

    if (match.phase == PaintballMatchPhase.intro) {
      final t = match.introElapsed;
      // Opponent walks up to his tyre during the close-up (0–1.5 s).
      final opp = _ease(t / _introCloseEnd);
      oppGroundY = h * (PaintballK.farGroundY - 0.04 * (1.0 - opp));
      opponentComponent.isWalking = t < _introCloseEnd;
      // You walk into your lane from below the screen (3.0–4.2 s).
      final you = _ease(
        (t - _introSweepEnd) / (_introWalkEnd - _introSweepEnd),
      );
      youGroundY = h * (PaintballK.nearGroundY + 0.28 * (1.0 - you));
      playerComponent.isWalking = t >= _introSweepEnd && t < _introWalkEnd;
    } else {
      playerComponent.isWalking = false;
      opponentComponent.isWalking = false;
    }

    // Ground point, offset slightly left so the marker (right hand) sits near
    // screen centre for the over-the-shoulder look.
    playerComponent.position.setValues(
      playerLaneX - laneStep * 0.10,
      youGroundY,
    );

    // 2. Opponent (Worker)
    double oppLaneX;
    final oppScreenLane = PaintballK.mirrorLane(match.opponent.lane);
    if (match.opponent.isSliding) {
      final oppFromScreen = PaintballK.mirrorLane(match.opponent.slideFromLane);
      final oppToScreen = PaintballK.mirrorLane(match.opponent.slideToLane);
      final fromX = centerX + ((oppFromScreen - 2) * farStep);
      final toX = centerX + ((oppToScreen - 2) * farStep);
      oppLaneX = fromX + (toX - fromX) * match.opponent.slideProgress;
    } else {
      oppLaneX = centerX + ((oppScreenLane - 2) * farStep);
    }

    opponentComponent.position.setValues(oppLaneX, oppGroundY);
  }

  // ─── Camera Target Calculation ────────────────────────────────────────────

  void _updateCameraTarget() {
    if (_cachedWidth <= 0 || _cachedHeight <= 0) return;

    final laneStep = _nearStep(_cachedWidth, _cachedHeight);
    final stageW = _stageWidth(_cachedWidth, _cachedHeight);

    // 1. Horizontal tracking: follow your lane so you stay on screen.
    final playerLaneDelta = _youContinuousLane - 2.0; // [-2.0, 2.0]
    final laneTrackOffset = -playerLaneDelta * (laneStep * 0.65);

    // 2. Look-ahead pan from the aim angle (relative to where you face).
    final facing = playerLaneDelta * 0.5;
    final aimAngle = reticle.aimX - facing;
    final aimPanOffset = -aimAngle * stageW * PaintballK.aimPanFraction;

    _targetCameraPan = laneTrackOffset + aimPanOffset;

    // 2. Vertical Stance Dip:
    _targetCameraDip = switch (match.you.stance) {
      PaintballStance.stand => 0.0,
      PaintballStance.crouch =>
        _cachedHeight * PaintballK.cameraCrouchDipFraction,
      PaintballStance.duck => _cachedHeight * PaintballK.cameraDuckDipFraction,
    };
  }

  // ─── Match Phase Gate ─────────────────────────────────────────────────────

  /// Players may only move, change stance and fire while the duel is live.
  bool get canAct =>
      _isReady &&
      (match.phase == PaintballMatchPhase.live ||
          match.phase == PaintballMatchPhase.suddenDeath);

  /// Slides the local player one lane (-1 left, +1 right). Ignored outside live play.
  /// Taps during a slide aren't dropped: the latest one is queued and
  /// plays the moment the current slide lands (fast double-taps work).
  int _queuedSlide = 0;
  int _queuedStance = 0;

  bool playerSlide(int direction) {
    if (!canAct) return false;
    if (match.you.isSliding) {
      _queuedSlide = direction;
      _queuedStance = 0;
      return true;
    }
    return match.you.trySlide(direction);
  }

  void _runQueuedInput() {
    if (!canAct || match.you.isSliding) return;
    if (_queuedSlide != 0) {
      final d = _queuedSlide;
      _queuedSlide = 0;
      match.you.trySlide(d);
    } else if (_queuedStance != 0) {
      final st = _queuedStance;
      _queuedStance = 0;
      playerStanceStep(st);
    }
  }

  /// Moves the local player one stance up (+1) or down (-1). Ignored outside live play.
  bool playerStanceStep(int step) {
    if (!canAct) return false;
    if (match.you.isSliding) {
      _queuedStance = step;
      return true;
    }
    final i = (match.you.stance.index - step).clamp(
      0,
      PaintballStance.values.length - 1,
    );
    return match.you.tryChangeStance(PaintballStance.values[i]);
  }

  /// Whether the FIRE button should be enabled.
  bool get playerCanFire => canAct && match.you.canFire;

  // ─── Rounds ───────────────────────────────────────────────────────────────

  /// Between rounds: everyone back to the middle, paint and balls cleared.
  void _resetRoundVisuals() {
    for (final ball in _ballPool) {
      ball.cancel();
    }
    _activeProjectiles.clear();
    splatCanvas.clear();
    playerComponent.clearBodySplats();
    opponentComponent.clearBodySplats();
    botBrain.reset();
    _queuedSlide = 0;
    _queuedStance = 0;
    _aimOffset = 0.0;
    reticle.aimY = 0.65;
    _myShotAim.clear();
    playerComponent.resetVisual();
    opponentComponent.resetVisual();
    if (_cachedWidth > 0 && _cachedHeight > 0) {
      _updatePlayerPositions(_cachedWidth, _cachedHeight);
    }
  }

  // ─── Rematch ──────────────────────────────────────────────────────────────

  /// Resets everything for a fresh match: rules state, balls in flight,
  /// threat trackers, splats, bot timers, reticle and camera.
  void resetMatch() {
    for (final ball in _ballPool) {
      ball.cancel();
    }
    _activeProjectiles.clear();
    splatCanvas.clear();
    playerComponent.clearBodySplats();
    opponentComponent.clearBodySplats();
    botBrain.reset();
    _aimOffset = 0.0;
    reticle.aimX = 0.0;
    reticle.aimY = 0.65;
    reticle.isLockedOn = false;
    cameraPanOffset = 0.0;
    _targetCameraPan = 0.0;
    cameraDipOffset = 0.0;
    _targetCameraDip = 0.0;
    match.startMatch();
    _posesRound = 0;
    gameOverSeconds = 0.0;
    _matchOverSent = false;
    _resolvedShots.clear();
    _myShotAim.clear();
    _sentLane = -1;
    _queuedSlide = 0;
    _queuedStance = 0;
    remoteAimBucket = 0;
    playerComponent.resetVisual();
    opponentComponent.resetVisual();
    if (_cachedWidth > 0 && _cachedHeight > 0) {
      _layoutScene(_cachedWidth, _cachedHeight);
    }
  }

  /// Online: both players are in. [elapsedSeconds] is the time since the
  /// shared start (server clock); a late joiner fast-forwards to stay in sync.
  /// The intro always plays from the shared start.
  void startOnline(double elapsedSeconds) {
    if (!_isReady) {
      _pendingStartElapsed = elapsedSeconds;
      _pendingStartAtMs = DateTime.now().millisecondsSinceEpoch;
      return;
    }
    resetMatch();
    match.holdBetweenRounds = true; // the host's round start drives round 2/3
    waitingForOpponent = false;
    var left = elapsedSeconds.clamp(0.0, 30.0);
    while (left > 0) {
      final step = left > 0.05 ? 0.05 : left;
      match.tick(step);
      left -= step;
    }
  }

  /// Online: [opponent]'s lane, stance and ammo arrived. Slides and stance
  /// changes play through the same timers as local moves; never a teleport.
  void applyRemoteState(PaintballNetPlayerState st) {
    final opp = match.opponent;
    remoteAimBucket = st.aimBucket;
    // Trust the target's own hit count if it is ahead of ours.
    if (st.hitsTaken > opp.hitsTaken) opp.hitsTaken = st.hitsTaken;

    final to = st.lane;
    if (st.slideFromLane >= 0 && st.slideFromLane != to) {
      if (!(opp.isSliding && opp.slideToLane == to)) {
        opp.isSliding = false;
        opp.lane = st.slideFromLane;
        opp.trySlide(to > st.slideFromLane ? 1 : -1);
      }
    } else if (!opp.isSliding && opp.lane != to) {
      opp.lane = to;
      opp.slideFromLane = to;
      opp.slideToLane = to;
    }
    if (st.stanceEnum != opp.stance) opp.tryChangeStance(st.stanceEnum);
  }

  /// Online: the opponent fired. [elapsedSeconds] since they fired, so a late
  /// packet starts the ball part-way through its flight.
  void applyRemoteShot(String shotId, double aimX, double aimY, double elapsedSeconds) {
    if (!canAct) return;
    match.opponent.shotsFired++;
    _launchOpponentBall(aimX, aimY, shotId: shotId, elapsed: elapsedSeconds);
  }

  /// Online: the opponent judged one of your shots. Applied once per shot.
  void applyRemoteResult(PaintballNetShotResult r) {
    // Only shots fired this round (the map is cleared between rounds).
    if (!_myShotAim.containsKey(r.shotId)) return;
    if (!_resolvedShots.add(r.shotId)) return;
    if (!canAct) return;
    final opp = match.opponent;
    switch (r.outcome) {
      case PaintballNetHitOutcome.hit:
        if (!opp.applyDamage() && !opp.isEliminated) opp.hitsTaken++;
        match.you.shotsHit++;
        opponentComponent.addBodySplat(r.dx, r.aimY, blue: false);
        AudioEngine.playPaintballHitOpponent();
      case PaintballNetHitOutcome.invulnerable:
        opponentComponent.addBodySplat(r.dx, r.aimY, blue: false);
        AudioEngine.playPaintballSplat(near: false);
      case PaintballNetHitOutcome.tyre:
        // Splat on their tyre where your aim was (unshifted far-layer coords).
        if (_cachedWidth > 0 && _cachedHeight > 0) {
          final farStep = _farStep(_cachedWidth, _cachedHeight);
          final x = _cachedWidth * 0.5 + (_myShotAim[r.shotId] ?? 0.0) * farStep * 2.0;
          final y = _cachedHeight * PaintballK.farGroundY -
              r.aimY * _cachedHeight * PaintballK.oppStandHeight;
          AudioEngine.playPaintballSplat(near: false);
          splatCanvas.addSplat(
            x: x,
            y: y,
            color: const Color(0xFFEC4899),
            radius: 8.0,
          );
        }
      case PaintballNetHitOutcome.miss:
        opp.timesDodged++;
    }
  }

  /// Online: the match was decided elsewhere (opponent forfeited or left).
  void forceEnd({required bool youWin}) {
    if (match.phase == PaintballMatchPhase.gameOver) return;
    match.endByForfeit(youWin: youWin);
    _matchOverSent = true; // decided remotely: nothing more to publish
  }

  void _syncNetState() {
    final link = net;
    if (link == null || waitingForOpponent) return;
    final you = match.you;
    final lane = you.isSliding ? you.slideToLane : you.lane;
    final from = you.isSliding ? you.slideFromLane : -1;
    _aimBucket = computeAimBucket(playerComponent.aimTurn, _aimBucket);
    if (lane == _sentLane &&
        from == _sentFrom &&
        you.stance.index == _sentStance &&
        you.ammo == _sentAmmo &&
        you.hitsTaken == _sentHits &&
        _aimBucket == _sentAim) {
      return;
    }
    _sentLane = lane;
    _sentFrom = from;
    _sentStance = you.stance.index;
    _sentAmmo = you.ammo;
    _sentHits = you.hitsTaken;
    _sentAim = _aimBucket;
    link.sendState();
  }

  // ─── Arena intro (cinematic) ──────────────────────────────────────────────
  // 0–1.5 s   close-up on the opponent (1.8x zoom, slow drift) as he walks in
  // 1.5–3.0 s pull back to 1x while sweeping across the props and netting
  // 3.0–4.2 s settle behind you as you walk into your lane
  // 4.2–4.5 s hold, then 3-2-1. Plays every match; a tap skips it.
  static const double _introCloseEnd = 1.5;
  static const double _introSweepEnd = 3.0;
  static const double _introWalkEnd = 4.2;
  static const double _introCloseZoom = 1.8;

  /// Whole-scene zoom during the intro (1 = normal). Applied in [render]
  /// around [_zoomFocusX]/[_zoomFocusY]; the Flutter HUD is not affected.
  double introZoom = 1.0;
  double _zoomFocusX = 0.0;
  double _zoomFocusY = 0.0;

  /// Smootherstep 0..1 (zero velocity at both ends, so moves settle softly).
  static double _ease(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  void _updateIntroCamera(double t) {
    final w = _cachedWidth, h = _cachedHeight;
    if (w <= 0 || h <= 0) return;
    final stageW = _stageWidth(w, h);
    final pull = _ease(
      (t - _introCloseEnd) / (_introSweepEnd - _introCloseEnd),
    );

    // Zoom: hold the close-up with a slight push, then pull back to 1x.
    final close = _introCloseZoom - 0.08 * (t / _introCloseEnd).clamp(0.0, 1.0);
    introZoom = close + (1.0 - close) * pull;

    // Focus on the opponent's chest during the close-up, easing to the
    // screen centre as the zoom comes out (so 1x lands exactly on the layout).
    final oppX =
        opponentComponent.position.x +
        cameraPanOffset * PaintballK.parallaxFarTires;
    final oppY =
        h * PaintballK.farGroundY - h * PaintballK.oppStandHeight * 0.55;
    _zoomFocusX = oppX + (w * 0.5 - oppX) * pull;
    _zoomFocusY = oppY + (h * 0.5 - oppY) * pull;

    // Pan: a slow drift in the close-up, then a sweep out to one side of the
    // arena and back to your lane during the pull-back.
    final drift = 0.06 * stageW * (1.0 - (t / _introCloseEnd).clamp(0.0, 1.0));
    final sweepU = ((t - _introCloseEnd) / (_introSweepEnd - _introCloseEnd))
        .clamp(0.0, 1.0);
    final sweep = 0.75 * stageW * math.sin(math.pi * _ease(sweepU));
    cameraPanOffset = t < _introCloseEnd ? drift : sweep;
    _targetCameraPan = cameraPanOffset;
    cameraDipOffset = 0.0;
    _targetCameraDip = 0.0;
  }

  @override
  void render(Canvas canvas) {
    if (introZoom == 1.0) {
      super.render(canvas);
      return;
    }
    canvas.save();
    canvas.translate(_zoomFocusX, _zoomFocusY);
    canvas.scale(introZoom);
    canvas.translate(-_zoomFocusX, -_zoomFocusY);
    super.render(canvas);
    canvas.restore();
  }

  /// Skips the arena intro and immediately begins the countdown.
  void skipIntro() {
    if (match.phase == PaintballMatchPhase.intro) {
      match.skipIntro();
      introZoom = 1.0;
      playerComponent.isWalking = false;
      opponentComponent.isWalking = false;
      cameraPanOffset = 0.0;
      _targetCameraPan = 0.0;
      cameraDipOffset = 0.0;
      _targetCameraDip = 0.0;
      if (_cachedWidth > 0 && _cachedHeight > 0) {
        _updatePlayerPositions(_cachedWidth, _cachedHeight);
      }
    }
  }

  // ─── Keyboard (PC) ────────────────────────────────────────────────────────
  // ← → or A D slide, ↑ ↓ or W S change stance, Space fires.
  // Aim stays on the mouse: dragging on the right half works like a trackpad.

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored; // no auto-repeat
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      playerSlide(-1);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      playerSlide(1);
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW) {
      playerStanceStep(1);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      playerStanceStep(-1);
    } else if (key == LogicalKeyboardKey.space) {
      if (playerCanFire) firePlayerShot();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ─── Input & Aiming ───────────────────────────────────────────────────────

  /// Updates reticle aim coordinates via relative drag.
  void onAimDrag(double deltaX, double deltaY) {
    if (!_isReady || _cachedWidth <= 0 || _cachedHeight <= 0) return;

    // Relative drag sets the aim angle from where you face (Option A: the
    // angle is kept exactly when you slide).
    final stageW = _stageWidth(_cachedWidth, _cachedHeight);
    final facing = (_youContinuousLane - 2.0) * 0.5;
    _aimOffset = (_aimOffset + (deltaX / (stageW * 0.35)))
        .clamp(-PaintballK.maxAimOffset, PaintballK.maxAimOffset)
        // Don't let the stored angle run past the field edge, or dragging
        // back would feel dead.
        .clamp(-1.0 - facing, 1.0 - facing);
    _syncAimFromOffset();
    reticle.aimY = (reticle.aimY - (deltaY / (_cachedHeight * 0.25))).clamp(
      0.0,
      1.0,
    );

    _updateCameraTarget();
    _updateReticlePosition();
  }

  void _updateReticlePosition() {
    if (!_isReady || _cachedWidth <= 0 || _cachedHeight <= 0) return;

    final farStep = _farStep(_cachedWidth, _cachedHeight);
    final centerX = _cachedWidth * 0.5;

    // aimY is a fraction of a standing opponent's height above their feet,
    // the same scale HitResolver uses for exposure.
    final farGround =
        (_cachedHeight * PaintballK.farGroundY) -
        (cameraDipOffset * PaintballK.parallaxFarTiresY);
    final targetX =
        centerX +
        (reticle.aimX * (farStep * 2.0)) +
        (cameraPanOffset * PaintballK.parallaxFarTires);
    final targetY =
        farGround -
        (reticle.aimY * (_cachedHeight * PaintballK.oppStandHeight));

    reticle.position.setValues(targetX, targetY);

    // Check if reticle is hovering over exposed opponent
    // Same body test the hit uses, so "locked on" means "would hit now".
    // Allocation-free version of the hit test (runs every frame).
    final dx =
        (reticle.aimX - _seenByShooterAimX(match.opponent)) *
        2.0 *
        _farLaneStands;
    reticle.isLockedOn =
        match.you.stance != PaintballStance.duck &&
        !match.opponent.isInvulnerable &&
        reticle.aimY >= PaintballK.tyreCoverHeight &&
        opponentComponent.bodyAt(dx, reticle.aimY);
  }

  /// Fires a paintball from the local player toward the current reticle position.
  bool firePlayerShot() {
    if (!canAct) return false;
    if (!match.you.tryFire()) return false;

    HapticFeedback.lightImpact();
    AudioEngine.playPaintballShot();

    // Launch from player's gun barrel (accounting for current camera pan)
    playerComponent.muzzle(_muzzle);
    final startX = _muzzle.x + (cameraPanOffset * 1.0);
    final startY = _muzzle.y - (cameraDipOffset * 0.40);

    final targetX = reticle.position.x;
    final targetY = reticle.position.y;
    final shotId = net?.sendShot(reticle.aimX, reticle.aimY);
    if (shotId != null) _myShotAim[shotId] = reticle.aimX;

    _spawnBall(
      shotId: shotId,
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      color: const Color(0xFFEC4899), // Pink paintball
      aimX: reticle.aimX,
      aimY: reticle.aimY,
      isFiredByPlayer: true,
    );

    return true;
  }

  /// Fires a paintball from the bot toward the local player.
  void fireBotShot(double aimX, double aimY) {
    if (!canAct) return;
    if (!match.opponent.tryFire()) return;
    _launchOpponentBall(aimX, aimY);
  }

  void _launchOpponentBall(
    double aimX,
    double aimY, {
    String? shotId,
    double elapsed = 0.0,
  }) {
    AudioEngine.playPaintballShot(opponent: true);

    // Launch from bot's gun barrel (accounting for far parallax)
    opponentComponent.muzzle(_muzzle);
    final startX = _muzzle.x + (cameraPanOffset * PaintballK.parallaxFarTires);
    final startY = _muzzle.y - (cameraDipOffset * PaintballK.parallaxFarTiresY);

    // Calculate target coordinate on player's screen
    final laneOnPlayerScreen = PaintballK.mirrorLane(
      PaintballK.aimXToLane(aimX),
    );
    final laneStep = _nearStep(_cachedWidth, _cachedHeight);
    final centerX = _cachedWidth * 0.5;
    final targetX =
        centerX +
        ((laneOnPlayerScreen - 2) * laneStep) +
        (cameraPanOffset * 1.0);
    final targetY =
        (_cachedHeight * PaintballK.nearGroundY) -
        (aimY * (_cachedHeight * PaintballK.youStandHeight)) -
        (cameraDipOffset * 0.40);

    _spawnBall(
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      color: const Color(0xFF38BDF8), // Blue paintball
      aimX: aimX,
      aimY: aimY,
      isFiredByPlayer: false,
      shotId: shotId,
      elapsed: elapsed,
    );
  }

  void _spawnBall({
    required double startX,
    required double startY,
    required double targetX,
    required double targetY,
    required Color color,
    required double aimX,
    required double aimY,
    required bool isFiredByPlayer,
    String? shotId,
    double elapsed = 0.0,
  }) {
    for (final ball in _ballPool) {
      if (!ball.isActive) {
        // Your balls fly away from the camera and shrink; incoming balls grow.
        ball.launch(
          startX: startX,
          startY: startY,
          targetX: targetX,
          targetY: targetY,
          color: color,
          firedByYou: isFiredByPlayer,
          aimX: aimX,
          aimY: aimY,
          startScale: isFiredByPlayer
              ? PaintballK.ballStartScale
              : PaintballK.ballEndScale,
          endScale: isFiredByPlayer
              ? PaintballK.ballEndScale
              : PaintballK.ballStartScale,
          shotId: shotId,
          elapsed: elapsed,
        );

        if (isFiredByPlayer) {
          // Threat tracker for the bot's defensive AI, in the bot's own lane numbers.
          _activeProjectiles.add(
            IncomingProjectile(
              targetLane: PaintballK.mirrorLane(PaintballK.aimXToLane(aimX)),
              heightY: aimY,
              flightTimeRemaining: PaintballK.ballFlightSeconds,
            ),
          );
        }
        break;
      }
    }
  }

  // ─── Body-accurate hit geometry ───────────────────────────────────────────
  // Every shot is judged the way the shooter sees the target: front view,
  // far-row lane spacing, in standing heights from the target's feet.

  /// One far lane in the opponent's standing heights.
  double get _farLaneStands {
    if (_cachedWidth <= 0 || _cachedHeight <= 0) return 0.77;
    return _farStep(_cachedWidth, _cachedHeight) /
        (_cachedHeight * PaintballK.oppStandHeight);
  }

  /// Where [p] stands on the screen of the player shooting at them (aimX units,
  /// continuous while sliding). Each side sees the other mirrored.
  static double _seenByShooterAimX(PaintballPlayerState p) {
    final from = PaintballK.maxLane - p.slideFromLane;
    final to = PaintballK.maxLane - p.slideToLane;
    final lane = p.isSliding
        ? from + (to - from) * p.slideProgress
        : (PaintballK.maxLane - p.lane).toDouble();
    return (lane - 2.0) * 0.5;
  }

  HitResult _resolveShot({
    required bool atOpponent,
    required double aimX,
    required double aimY,
  }) {
    final target = atOpponent ? match.opponent : match.you;
    final comp = atOpponent ? opponentComponent : playerComponent;
    return HitResolver.resolveBody(
      shooterAimX: aimX,
      aimY: aimY,
      targetAimX: _seenByShooterAimX(target),
      targetInvulnerable: target.isInvulnerable,
      laneWidthStands: _farLaneStands,
      isBody: comp.bodyAt,
      isBodyStanding: comp.standingBodyAt,
    );
  }

  void _handleBallLanding(FlyingPaintball ball) {
    // A ball still landing after the match ended changes nothing.
    if (!canAct) return;

    // Online, your shots are judged by the opponent's device (applyRemoteResult).
    if (online && ball.firedByYou) return;

    // Target-side check at landing, with the aim captured when the ball was
    // fired, against the target's real body outline in its current pose.
    final atOpponent = ball.firedByYou;
    final target = atOpponent ? match.opponent : match.you;
    final shooter = atOpponent ? match.you : match.opponent;
    final targetComp = atOpponent ? opponentComponent : playerComponent;
    final result = _resolveShot(
      atOpponent: atOpponent,
      aimX: ball.aimX,
      aimY: ball.aimY,
    );
    final blue = ball.ballColor.b > ball.ballColor.r;

    // Online: you were the target, so your verdict is the one that counts.
    final id = ball.shotId;
    if (online && id != null) {
      net?.sendResult(
        id,
        result.outcome,
        (ball.aimX - _seenByShooterAimX(target)) * 2.0 * _farLaneStands,
        ball.aimY,
      );
    }

    if (result.isHit) {
      target.applyDamage();
      shooter.shotsHit++;
      // Paint sticks to the body where it hit and fades after 3 s.
      final dx =
          (ball.aimX - _seenByShooterAimX(target)) * 2.0 * _farLaneStands;
      targetComp.addBodySplat(dx, ball.aimY, blue: blue);
      // Hit sounds carry their own haptic (medium, on you only).
      if (atOpponent) {
        AudioEngine.playPaintballHitOpponent();
      } else {
        AudioEngine.playPaintballHitYou();
      }
      return;
    }

    if (result.isDodged) target.timesDodged++;

    // Paint on the body that didn't count (invulnerable) sticks too.
    if (result.outcome == PaintballHitOutcome.invulnerable) {
      final dx =
          (ball.aimX - _seenByShooterAimX(target)) * 2.0 * _farLaneStands;
      targetComp.addBodySplat(dx, ball.aimY, blue: blue);
      AudioEngine.playPaintballSplat(near: !atOpponent);
      return;
    }

    // Flew past: no splat on a tyre.
    if (result.outcome != PaintballHitOutcome.hitTire) return;

    // The tyre took it: splat where it landed. Splats live on a parallax
    // layer (far for your shots, near for the opponent's); store unshifted.
    final near = !ball.firedByYou;
    final unshiftedX =
        ball.trajectory.targetX -
        cameraPanOffset * (near ? 1.0 : PaintballK.parallaxFarTires);
    final unshiftedY =
        ball.trajectory.targetY +
        cameraDipOffset * (near ? 1.0 : PaintballK.parallaxFarTiresY);
    AudioEngine.playPaintballSplat(near: near);
    splatCanvas.addSplat(
      x: unshiftedX,
      y: unshiftedY,
      color: ball.ballColor,
      radius: near ? 22.0 : 8.0,
      near: near,
    );
  }

  // ─── Game Loop ────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isReady) return;
    _publishUi();
    if (waitingForOpponent) {
      if (_cachedWidth > 0 && _cachedHeight > 0) {
        _updatePlayerPositions(_cachedWidth, _cachedHeight);
      }
      return;
    }

    // 1. Advance Match Clock & State Machines
    match.tick(dt);
    _runQueuedInput();

    if (online && match.phase == PaintballMatchPhase.gameOver && !_matchOverSent) {
      _matchOverSent = true;
      net?.matchOver(match.winner);
    }

    if (match.phase == PaintballMatchPhase.gameOver) gameOverSeconds += dt;

    // New round: clear paint, balls, poses and the bot's plans.
    if (match.roundSerial != _roundSerialSeen) {
      _roundSerialSeen = match.roundSerial;
      _resetRoundVisuals();
    }

    // Win / death poses at the end of each round (and of the match).
    final ended = match.phase == PaintballMatchPhase.roundOver ||
        match.phase == PaintballMatchPhase.gameOver;
    if (ended && _posesRound != match.round) {
      _posesRound = match.round;
      final w = match.phase == PaintballMatchPhase.gameOver ? match.winner : match.roundWinner;
      playerComponent.showWin = w == PaintballWinner.you;
      opponentComponent.showWin = w == PaintballWinner.opponent;
      playerComponent.showDeath = match.you.isEliminated;
      opponentComponent.showDeath = match.opponent.isEliminated;
      // Online: the host announces the next round's shared start.
      if (online && match.phase == PaintballMatchPhase.roundOver) {
        net?.roundOver(match.round, match.roundWinner);
      }
    }

    // Carry the aim with you while sliding (same angle from where you face).
    _syncAimFromOffset();

    // Upper-body aim poses. aimTurn > 0 turns towards the character's own left.
    // Your aim angle: negative (screen-left) is your own left.
    playerComponent.aimTurn =
        -(reticle.aimX - (_youContinuousLane - 2.0) * 0.5);
    // The opponent looks towards your lane, measured on their own screen
    // (from behind them, screen-left is their own left).
    final oppFacing = PaintballK.laneToAimX(match.opponent.lane);
    final oppTarget = PaintballK.laneToAimX(
      PaintballK.mirrorLane(match.you.lane),
    );
    opponentComponent.aimTurn =
        online ? remoteAimBucket * 0.6 : -(oppTarget - oppFacing);

    // 2. Refresh Camera Targets & Advance Dual-Axis Damped Springs
    if (match.phase == PaintballMatchPhase.intro) {
      _updateIntroCamera(match.introElapsed);
    } else {
      introZoom = 1.0;
      _updateCameraTarget();

      final diffX = _targetCameraPan - cameraPanOffset;
      cameraPanOffset += diffX * math.min(1.0, dt * 10.0);

      final diffY = _targetCameraDip - cameraDipOffset;
      cameraDipOffset += diffY * math.min(1.0, dt * 12.0);
    }

    // Distribute camera pan & dip to parallax layers
    backdrop.cameraPanOffset = cameraPanOffset;
    backdrop.cameraDipOffset = cameraDipOffset;

    for (final tire in farTires) {
      tire.cameraPanOffset = cameraPanOffset;
      tire.cameraDipOffset = cameraDipOffset;
    }
    for (final tire in nearTires) {
      tire.cameraPanOffset = cameraPanOffset;
      tire.cameraDipOffset = cameraDipOffset;
    }

    splatCanvas.cameraPanOffset = cameraPanOffset;
    splatCanvas.cameraDipOffset = cameraDipOffset;

    opponentComponent.cameraPanOffset = cameraPanOffset;
    opponentComponent.cameraDipOffset = cameraDipOffset;

    playerComponent.cameraPanOffset = cameraPanOffset;
    playerComponent.cameraDipOffset = cameraDipOffset;

    _updateReticlePosition();

    // 3. Update Projectile Threat Timers
    for (int i = _activeProjectiles.length - 1; i >= 0; i--) {
      _activeProjectiles[i].flightTimeRemaining -= dt;
      if (_activeProjectiles[i].flightTimeRemaining <= 0.0) {
        _activeProjectiles.removeAt(i);
      }
    }

    _syncNetState();

    // 4. Advance Bot Cognition (bot mode only)
    if (!online &&
        (match.phase == PaintballMatchPhase.live ||
            match.phase == PaintballMatchPhase.suddenDeath)) {
      final botAction = botBrain.tick(
        dt: dt,
        bot: match.opponent,
        opponent: match.you,
        incomingProjectiles: _activeProjectiles,
      );

      if (botAction != null) {
        _executeBotAction(botAction);
      }
    }

    // 5. Update Screen Positions
    if (_cachedWidth > 0 && _cachedHeight > 0) {
      _updatePlayerPositions(_cachedWidth, _cachedHeight);
    }
  }

  void _executeBotAction(BotAction action) {
    switch (action) {
      case BotSlideAction(:final direction):
        match.opponent.trySlide(direction);
      case BotStanceAction(:final stance):
        match.opponent.tryChangeStance(stance);
      case BotFireAction(:final aimX, :final aimY):
        fireBotShot(aimX, aimY);
    }
  }
}
