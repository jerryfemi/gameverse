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

  // ─── Camera Pan Spring ────────────────────────────────────────────────────
  double cameraPanOffset = 0.0;
  double _targetCameraPan = 0.0;

  // ─── Layout Cache ─────────────────────────────────────────────────────────
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
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _cachedWidth = size.x;
    _cachedHeight = size.y;
    _layoutScene(size.x, size.y);
  }

  void _layoutScene(double w, double h) {
    final laneStep = w / (PaintballK.laneCount + 0.6);
    final leftMargin = (w - (laneStep * (PaintballK.laneCount - 1))) * 0.5;

    // Position Far Tires (at y ≈ 38% - 46%)
    final farTireW = w * 0.15;
    final farTireH = h * 0.12;
    final farY = h * 0.40;

    for (int i = 0; i < farTires.length; i++) {
      final cx = leftMargin + (i * laneStep);
      farTires[i].size.setValues(farTireW, farTireH);
      farTires[i].position.setValues(cx - farTireW * 0.5, farY);
    }

    // Position Near Tires (at y ≈ 68% - 85%)
    final nearTireW = w * 0.42;
    final nearTireH = h * 0.32;
    final nearY = h * 0.64;

    for (int i = 0; i < nearTires.length; i++) {
      final cx = leftMargin + (i * laneStep);
      nearTires[i].size.setValues(nearTireW, nearTireH);
      nearTires[i].position.setValues(cx - nearTireW * 0.5, nearY);
    }

    // Player (Foreground, over the shoulder)
    final playerW = w * 0.28;
    final playerH = h * 0.36;
    playerComponent.size.setValues(playerW, playerH);
    _updatePlayerPositions(w, h);

    // Opponent (Distance)
    final oppW = w * 0.14;
    final oppH = h * 0.18;
    opponentComponent.size.setValues(oppW, oppH);
    _updatePlayerPositions(w, h);

    _updateReticlePosition();
  }

  void _updatePlayerPositions(double w, double h) {
    final laneStep = w / (PaintballK.laneCount + 0.6);
    final leftMargin = (w - (laneStep * (PaintballK.laneCount - 1))) * 0.5;

    // 1. Local Player (Swat)
    double playerLaneX;
    if (match.you.isSliding) {
      final fromX = leftMargin + (match.you.slideFromLane * laneStep);
      final toX = leftMargin + (match.you.slideToLane * laneStep);
      playerLaneX = fromX + (toX - fromX) * match.you.slideProgress;
    } else {
      playerLaneX = leftMargin + (match.you.lane * laneStep);
    }

    // Offset slightly right for authentic over-the-shoulder perspective
    playerComponent.position.setValues(
      playerLaneX - (playerComponent.size.x * 0.45),
      h * 0.60,
    );

    // 2. Opponent (Worker)
    double oppLaneX;
    final oppScreenLane = PaintballK.mirrorLane(match.opponent.lane);
    if (match.opponent.isSliding) {
      final oppFromScreen = PaintballK.mirrorLane(match.opponent.slideFromLane);
      final oppToScreen = PaintballK.mirrorLane(match.opponent.slideToLane);
      final fromX = leftMargin + (oppFromScreen * laneStep);
      final toX = leftMargin + (oppToScreen * laneStep);
      oppLaneX = fromX + (toX - fromX) * match.opponent.slideProgress;
    } else {
      oppLaneX = leftMargin + (oppScreenLane * laneStep);
    }

    opponentComponent.position.setValues(
      oppLaneX - (opponentComponent.size.x * 0.5),
      h * 0.34,
    );
  }

  // ─── Input & Aiming ───────────────────────────────────────────────────────

  /// Updates reticle aim coordinates via relative drag.
  void onAimDrag(double deltaX, double deltaY) {
    if (_cachedWidth <= 0 || _cachedHeight <= 0) return;

    // Relative sensitivity
    reticle.aimX = (reticle.aimX + (deltaX / (_cachedWidth * 0.35))).clamp(-1.0, 1.0);
    reticle.aimY = (reticle.aimY - (deltaY / (_cachedHeight * 0.25))).clamp(0.0, 1.0);

    // Camera look-at target follows reticle horizontally (±15% max)
    _targetCameraPan = -reticle.aimX * (_cachedWidth * PaintballK.cameraMaxPanFraction);

    _updateReticlePosition();
  }

  void _updateReticlePosition() {
    if (_cachedWidth <= 0 || _cachedHeight <= 0) return;

    final farY = _cachedHeight * 0.40;
    final targetX = (_cachedWidth * 0.5) + (reticle.aimX * (_cachedWidth * 0.42));
    final targetY = farY - (reticle.aimY * (_cachedHeight * 0.12));

    reticle.position.setValues(targetX, targetY);

    // Check if reticle is hovering over exposed opponent
    final oppScreenLane = PaintballK.mirrorLane(match.opponent.lane);
    final aimLane = PaintballK.aimXToLane(reticle.aimX);

    final isLaneAligned = aimLane == oppScreenLane;
    final isExposed = PaintballK.isHeightExposed(match.opponent.stance, reticle.aimY);
    reticle.isLockedOn = isLaneAligned && isExposed && !match.opponent.isInvulnerable;
  }

  /// Fires a paintball from the local player toward the current reticle position.
  bool firePlayerShot() {
    if (!match.you.tryFire()) return false;

    HapticFeedback.lightImpact();
    AudioEngine.playFloorBounce(7.0); // Pneumatic marker pop placeholder

    // Launch from player's gun barrel
    final startX = playerComponent.position.x + (playerComponent.size.x * 0.70);
    final startY = playerComponent.position.y + (playerComponent.size.y * 0.22);

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
    if (!match.opponent.tryFire()) return;

    AudioEngine.playFloorBounce(5.5);

    // Launch from bot's gun barrel
    final startX = opponentComponent.position.x + (opponentComponent.size.x * 0.25);
    final startY = opponentComponent.position.y + (opponentComponent.size.y * 0.35);

    // Calculate target coordinate on player's screen
    final laneOnPlayerScreen = PaintballK.mirrorLane(PaintballK.aimXToLane(aimX));
    final laneStep = _cachedWidth / (PaintballK.laneCount + 0.6);
    final leftMargin = (_cachedWidth - (laneStep * (PaintballK.laneCount - 1))) * 0.5;
    final targetX = leftMargin + (laneOnPlayerScreen * laneStep);
    final targetY = _cachedHeight * 0.68 - (aimY * (_cachedHeight * 0.15));

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
        splatCanvas.addSplat(x: landX, y: landY, color: ball.ballColor, radius: 14.0);
      } else {
        if (result.isDodged) {
          match.opponent.timesDodged++;
        }
        // Tire splat
        splatCanvas.addSplat(x: landX, y: landY, color: ball.ballColor, radius: 10.0);
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
        splatCanvas.addSplat(x: landX, y: landY, color: ball.ballColor, radius: 16.0);
      } else {
        if (result.isDodged) {
          match.you.timesDodged++;
        }
        splatCanvas.addSplat(x: landX, y: landY, color: ball.ballColor, radius: 12.0);
      }
    }
  }

  // ─── Game Loop ────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Advance Match Clock & State Machines
    match.tick(dt);

    // 2. Camera Pan Damped Spring (settles toward target)
    final diff = _targetCameraPan - cameraPanOffset;
    cameraPanOffset += diff * math.min(1.0, dt * 10.0);

    // Distribute camera pan to parallax layers
    backdrop.cameraPanOffset = cameraPanOffset;
    for (final tire in farTires) {
      tire.cameraPanOffset = cameraPanOffset;
    }
    for (final tire in nearTires) {
      tire.cameraPanOffset = cameraPanOffset;
    }
    opponentComponent.cameraPanOffset = cameraPanOffset;
    playerComponent.cameraPanOffset = cameraPanOffset;

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
