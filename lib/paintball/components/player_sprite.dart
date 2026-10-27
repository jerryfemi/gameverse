import 'dart:ui';
import 'package:flame/components.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';

/// Renders either the local player (Swat, back view, foreground) or
/// the opponent (Worker, front view, distance).
///
/// Follows Paintball Plan §5 & §7:
/// - Smooth horizontal slide between lanes (0.35 s).
/// - Dynamic stance heights: Stand (full), Crouch (half peek), Duck (tucked behind tire).
/// - Hit flash feedback when invulnerable.
/// - Ready for drop-in SpriteAnimationGroupComponent when WebP atlases are baked.
class PaintballPlayerComponent extends PositionComponent with HasGameReference {
  final bool isOpponent;
  final PaintballPlayerState state;

  double cameraPanOffset = 0.0;

  // ─── Pre-allocated Paints ─────────────────────────────────────────────────
  final Paint _bodyPaint = Paint()..isAntiAlias = true;
  final Paint _vestPaint = Paint()..isAntiAlias = true;
  final Paint _helmetPaint = Paint()..isAntiAlias = true;
  final Paint _gunPaint = Paint()..color = const Color(0xFF1F2937);
  final Paint _shadowPaint = Paint()
    ..color = const Color(0x44000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  final Paint _hitFlashPaint = Paint()..color = const Color(0x99EF4444);

  PaintballPlayerComponent({
    required this.isOpponent,
    required this.state,
  }) : super(priority: isOpponent ? 20 : 60);

  @override
  void render(Canvas canvas) {
    final shiftX = cameraPanOffset * (isOpponent ? PaintballK.parallaxFarTires : 1.0);

    canvas.save();
    canvas.translate(shiftX, 0);

    final w = size.x;
    final h = size.y;

    // 1. Calculate vertical stance offset
    // Duck hides down by 65% of height; Crouch drops by 30%
    final double stanceOffsetY = switch (state.stance) {
      PaintballStance.stand => 0.0,
      PaintballStance.crouch => h * 0.28,
      PaintballStance.duck => h * 0.68,
    };

    // 2. Drop shadow under feet (only visible when near ground)
    if (state.stance != PaintballStance.duck) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.98), width: w * 0.8, height: h * 0.15),
        _shadowPaint,
      );
    }

    canvas.save();
    canvas.translate(0, stanceOffsetY);

    if (isOpponent) {
      _renderWorkerFront(canvas, w, h);
    } else {
      _renderSwatBack(canvas, w, h);
    }

    // Hit flash overlay
    if (state.isInvulnerable) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)),
        _hitFlashPaint,
      );
    }

    canvas.restore();
    canvas.restore();
  }

  /// Renders Swat tactical character seen from behind (foreground).
  void _renderSwatBack(Canvas canvas, double w, double h) {
    _bodyPaint.color = const Color(0xFF334155);   // Dark camo slate
    _vestPaint.color = const Color(0xFF1E293B);   // Tactical vest
    _helmetPaint.color = const Color(0xFF0F172A); // Black helmet

    // Legs / Lower body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.55, w * 0.56, h * 0.42), const Radius.circular(6)),
      _bodyPaint,
    );

    // Torso / Tactical Vest
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, h * 0.35), const Radius.circular(8)),
      _vestPaint,
    );

    // Shoulders & Arms (holding marker raised forward)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.24, w * 0.20, h * 0.30), const Radius.circular(6)),
      _bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.68, h * 0.24, w * 0.20, h * 0.30), const Radius.circular(6)),
      _bodyPaint,
    );

    // Paintball marker (gun) poking forward
    canvas.drawRect(
      Rect.fromLTWH(w * 0.62, h * 0.18, w * 0.14, h * 0.22),
      _gunPaint,
    );

    // Tactical Helmet (back of head)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.15), width: w * 0.38, height: h * 0.24),
      _helmetPaint,
    );
  }

  /// Renders Worker character facing forward in distance (hardhat + orange vest).
  void _renderWorkerFront(Canvas canvas, double w, double h) {
    _bodyPaint.color = const Color(0xFF4B5563);   // Gray work uniform
    _vestPaint.color = const Color(0xFFF97316);   // Hi-vis safety orange vest
    _helmetPaint.color = const Color(0xFFFACC15); // Yellow hardhat

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.55, w * 0.50, h * 0.42), const Radius.circular(4)),
      _bodyPaint,
    );

    // Torso with hi-vis orange safety vest
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h * 0.26, w * 0.60, h * 0.32), const Radius.circular(5)),
      _vestPaint,
    );

    // Face / Head skin
    final skinPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.18), width: w * 0.32, height: h * 0.18),
      skinPaint,
    );

    // Yellow construction hardhat
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.11), width: w * 0.44, height: h * 0.18),
      _helmetPaint,
    );

    // Raised marker
    canvas.drawRect(
      Rect.fromLTWH(w * 0.15, h * 0.26, w * 0.12, h * 0.24),
      _gunPaint,
    );
  }
}
