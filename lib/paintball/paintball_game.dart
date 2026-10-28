import 'dart:math' as math;
import 'package:flame/game.dart';
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

/// Flame game engine for Paintball 1v1 duels.
///
/// Follows Paintball Plan §5 & §7:
/// - 60 fps fixed-frame budget with zero per-frame heap allocations.
/// - 5-lane 2.5D world projection with camera pan spring damping.
/// - Autonomous Bot AI integration ([PaintballBotBrain]).
/// - Deterministic ballistic trajectory arcs and target-side hit resolution.
class PaintballGame extends FlameGame {
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
  double _cachedWidth = 0.0;
  double _cachedHeight = 0.0;

  PaintballGame({int? botSeed}) {
    botBrain = PaintballBotBrain(seed: botSeed);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Backdrop (Priority 0)
    backdrop = PaintballBackdrop();
    await add(backdrop);

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

    // 7. Reticle (Priority 70)
    reticle = ReticleComponent();
    await add(reticle);

    match.startMatch();

    _isReady = true;

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

  void _layoutScene(double w, double h) {
    // Zoomed in: only ~2.8 lanes fit in the viewport at once
    final laneStep = w / PaintballK.visibleLanes;
    final centerX = w * 0.5;

    // Position Far Tires (at y ≈ 36% - 48%)
    // Each tire stack is chunky and wide (~80% of lane step)
    final farTireW = laneStep * 0.82;
    final farTireH = h * 0.15;
    final farY = h * 0.38;

    for (int i = 0; i < farTires.length; i++) {
      final cx = centerX + ((i - 2) * laneStep);
      farTires[i].size.setValues(farTireW, farTireH);
      farTires[i].position.setValues(cx - farTireW * 0.5, farY);
    }

    // Position Near Tires (at y ≈ 62% - 95%)
    final nearTireW = laneStep * 1.55;
    final nearTireH = h * 0.38;
    final nearY = h * 0.62;

    for (int i = 0; i < nearTires.length; i++) {
      final cx = centerX + ((i - 2) * laneStep);
      nearTires[i].size.setValues(nearTireW, nearTireH);
      nearTires[i].position.setValues(cx - nearTireW * 0.5, nearY);
    }

    // Player (Foreground, over-the-shoulder)
    final playerW = laneStep * 0.95;
    final playerH = h * 0.42;
    playerComponent.size.setValues(playerW, playerH);

    // Opponent (Distance)
    final oppW = laneStep * 0.65;
    final oppH = h * 0.24;
    opponentComponent.size.setValues(oppW, oppH);

    _updatePlayerPositions(w, h);
    _updateCameraTarget();
    _updateReticlePosition();
  }

  void _updatePlayerPositions(double w, double h) {
    final laneStep = w / PaintballK.visibleLanes;
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

    // Offset slightly right for authentic over-the-shoulder perspective
    playerComponent.position.setValues(
      playerLaneX - (playerComponent.size.x * 0.45),
      h * 0.58,
    );

    // 2. Opponent (Worker)
    double oppLaneX;
    final oppScreenLane = PaintballK.mirrorLane(match.opponent.lane);
    if (match.opponent.isSliding) {
      final oppFromScreen = PaintballK.mirrorLane(match.opponent.slideFromLane);
      final oppToScreen = PaintballK.mirrorLane(match.opponent.slideToLane);
      final fromX = centerX + ((oppFromScreen - 2) * laneStep);
      final toX = centerX + ((oppToScreen - 2) * laneStep);
      oppLaneX = fromX + (toX - fromX) * match.opponent.slideProgress;
    } else {
      oppLaneX = centerX + ((oppScreenLane - 2) * laneStep);
    }

    opponentComponent.position.setValues(
      oppLaneX - (opponentComponent.size.x * 0.5),
      h * 0.31,
    );
  }

  // ─── Camera Target Calculation ────────────────────────────────────────────

  void _updateCameraTarget() {
    if (_cachedWidth <= 0 || _cachedHeight <= 0) return;

    final laneStep = _cachedWidth / PaintballK.visibleLanes;

    // 1. Horizontal Tracking:
    // Anchor to player's current continuous lane so player remains on screen
    double playerContinuousLane;
    if (match.you.isSliding) {
      playerContinuousLane = match.you.slideFromLane +
          (match.you.slideToLane - match.you.slideFromLane) * match.you.slideProgress;
    } else {
      playerContinuousLane = match.you.lane.toDouble();
    }
    final playerLaneDelta = playerContinuousLane - 2.0; // [-2.0, 2.0]
    final laneTrackOffset = -playerLaneDelta * (laneStep * 0.65);

    // Additive look-ahead aim pan (±28% screen width)
    final aimPanOffset = -reticle.aimX * (_cachedWidth * PaintballK.cameraMaxPanFraction);

    _targetCameraPan = laneTrackOffset + aimPanOffset;

    // 2. Vertical Stance Dip:
    _targetCameraDip = switch (match.you.stance) {
      PaintballStance.stand => 0.0,
      PaintballStance.crouch => _cachedHeight * PaintballK.cameraCrouchDipFraction,
      PaintballStance.duck => _cachedHeight * PaintballK.cameraDuckDipFraction,
    };
  }

  // ─── Input & Aiming ───────────────────────────────────────────────────────

  /// Updates reticle aim coordinates via relative drag.
  void onAimDrag(double deltaX, double deltaY) {
    if (!_isReady || _cachedWidth <= 0 || _cachedHeight <= 0) return;

    // Relative sensitivity
    reticle.aimX = (reticle.aimX + (deltaX / (_cachedWidth * 0.35))).clamp(-1.0, 1.0);
    reticle.aimY = (reticle.aimY - (deltaY / (_cachedHeight * 0.25))).clamp(0.0, 1.0);

    _updateCameraTarget();
    _updateReticlePosition();
  }

  void _updateReticlePosition() {
    if (!_isReady || _cachedWidth <= 0 || _cachedHeight <= 0) return;

    final laneStep = _cachedWidth / PaintballK.visibleLanes;
    final centerX = _cachedWidth * 0.5;

    // Far horizon baseline + parallax vertical dip
    final farY = (_cachedHeight * 0.38) - (cameraDipOffset * PaintballK.parallaxFarTiresY);
    final targetX = centerX + (reticle.aimX * (laneStep * 2.0)) + (cameraPanOffset * PaintballK.parallaxFarTires);
    final targetY = farY - (reticle.aimY * (_cachedHeight * 0.14));

    reticle.position.setValues(targetX, targetY);

    // Check if reticle is hovering over exposed opponent
    final oppScreenLane = PaintballK.mirrorLane(match.opponent.lane);
    final aimLane = PaintballK.aimXToLane(reticle.aimX);

    final isLaneAligned = aimLane == oppScreenLane;
    final isExposed = PaintballK.isHeightExposed(match.opponent.stance, reticle.aimY);
    reticle.isLockedOn = isLaneAligned &&
        isExposed &&
        !match.opponent.isInvulnerable &&
        match.you.stance != PaintballStance.duck;
  }

  /// Fires a paintball from the local player toward the current reticle position.
  bool firePlayerShot() {
    if (!_isReady) return false;
    if (!match.you.tryFire()) return false;

    HapticFeedback.lightImpact();
    AudioEngine.playFloorBounce(7.0); // Pneumatic marker pop placeholder

    // Launch from player's gun barrel (accounting for current camera pan)
    final startX = playerComponent.position.x + (playerComponent.size.x * 0.70) + (cameraPanOffset * 1.0);
    final startY = playerComponent.position.y + (playerComponent.size.y * 0.22) - (cameraDipOffset * 0.40);

    final targetX = reticle.position.x;
    final targetY = reticle.position.y;

    _spawnBall(
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      color: const Color(0xFFEC4899), // Pink paintball
      targetLane: PaintballK.aimXToLane(reticle.aimX),
      heightY: reticle.aimY,
      isFiredByPlayer: true,
    );

    return true;
  }

  /// Fires a paintball from the bot toward the local player.
  void fireBotShot(double aimX, double aimY) {
    if (!_isReady) return;
    if (!match.opponent.tryFire()) return;

    AudioEngine.playFloorBounce(5.5);

    // Launch from bot's gun barrel (accounting for far parallax)
    final startX = opponentComponent.position.x + (opponentComponent.size.x * 0.25) + (cameraPanOffset * PaintballK.parallaxFarTires);
    final startY = opponentComponent.position.y + (opponentComponent.size.y * 0.35) - (cameraDipOffset * PaintballK.parallaxFarTiresY);

    // Calculate target coordinate on player's screen
    final laneOnPlayerScreen = PaintballK.mirrorLane(PaintballK.aimXToLane(aimX));
    final laneStep = _cachedWidth / PaintballK.visibleLanes;
    final centerX = _cachedWidth * 0.5;
    final targetX = centerX + ((laneOnPlayerScreen - 2) * laneStep) + (cameraPanOffset * 1.0);
    final targetY = (_cachedHeight * 0.65) - (aimY * (_cachedHeight * 0.15)) - (cameraDipOffset * 1.0);

    _spawnBall(
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      color: const Color(0xFF38BDF8), // Blue paintball
      targetLane: laneOnPlayerScreen,
      heightY: aimY,
      isFiredByPlayer: false,
    );
  }

  void _spawnBall({
    required double startX,
    required double startY,
    required double targetX,
    required double targetY,
    required Color color,
    required int targetLane,
    required double heightY,
    required bool isFiredByPlayer,
  }) {
    for (final ball in _ballPool) {
      if (!ball.isActive) {
        ball.launch(
          startX: startX,
          startY: startY,
          targetX: targetX,
          targetY: targetY,
          color: color,
        );

        if (isFiredByPlayer) {
          // Add threat tracker for bot defensive AI
          _activeProjectiles.add(
            IncomingProjectile(
              targetLane: targetLane,
              heightY: heightY,
              flightTimeRemaining: PaintballK.ballFlightSeconds,
            ),
          );
        }
        break;
      }
    }
  }

  void _handleBallLanding(FlyingPaintball ball) {
    final landX = ball.trajectory.targetX;
    final landY = ball.trajectory.targetY;
    final isPlayerBall = ball.ballColor == const Color(0xFFEC4899);

    // Unshift for splat canvas which applies parallax translation in render()
    final unshiftedX = landX - (cameraPanOffset * PaintballK.parallaxFarTires);
    final unshiftedY = landY - (-cameraDipOffset * PaintballK.parallaxFarTiresY);

    if (isPlayerBall) {
      // Shot targeted at Opponent
      final targetLane = PaintballK.aimXToLane(reticle.aimX);
      final result = HitResolver.resolveAtTargetLane(
        targetLane: targetLane,
        aimY: reticle.aimY,
        target: match.opponent.toSnapshot(),
      );

      if (result.isHit) {
        match.opponent.applyDamage();
        match.you.shotsHit++;
        splatCanvas.addSplat(x: unshiftedX, y: unshiftedY, color: ball.ballColor, radius: 14.0);
      } else {
        if (result.isDodged) {
          match.opponent.timesDodged++;
        }
        // Tire splat
        splatCanvas.addSplat(x: unshiftedX, y: unshiftedY, color: ball.ballColor, radius: 10.0);
      }
    } else {
      // Shot targeted at You (Player)
      final playerLane = match.you.lane;
      final result = HitResolver.resolveAtTargetLane(
        targetLane: playerLane,
        aimY: 0.65, // Standard bot hit check
        target: match.you.toSnapshot(),
      );

      if (result.isHit) {
        HapticFeedback.heavyImpact();
        match.you.applyDamage();
        match.opponent.shotsHit++;
        splatCanvas.addSplat(x: unshiftedX, y: unshiftedY, color: ball.ballColor, radius: 16.0);
      } else {
        if (result.isDodged) {
          match.you.timesDodged++;
        }
        splatCanvas.addSplat(x: unshiftedX, y: unshiftedY, color: ball.ballColor, radius: 12.0);
      }
    }
  }

  // ─── Game Loop ────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isReady) return;

    // 1. Advance Match Clock & State Machines
    match.tick(dt);

    // 2. Refresh Camera Targets & Advance Dual-Axis Damped Springs
    _updateCameraTarget();

    final diffX = _targetCameraPan - cameraPanOffset;
    cameraPanOffset += diffX * math.min(1.0, dt * 10.0);

    final diffY = _targetCameraDip - cameraDipOffset;
    cameraDipOffset += diffY * math.min(1.0, dt * 12.0);

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

    // 4. Advance Bot Cognition
    if (match.phase == PaintballMatchPhase.live ||
        match.phase == PaintballMatchPhase.suddenDeath) {
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
