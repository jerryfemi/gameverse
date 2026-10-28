import 'dart:ui';
import 'package:flame/components.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/paintball_game.dart';

/// Floating circular aim reticle on the far field.
///
/// Follows Paintball Plan §5b & §8:
/// - Priority 70.
/// - 34 px red ring (`#EF4444`) with center dot.
/// - Turns solid / glow when hovering directly over exposed opponent body.
class ReticleComponent extends PositionComponent with HasGameReference<PaintballGame> {
  bool isLockedOn = false;
  double aimX = 0.0; // [-1.0, 1.0]
  double aimY = 0.65; // [0.0, 1.0]

  // ─── Pre-allocated Paints ─────────────────────────────────────────────────
  final Paint _ringPaint = Paint()
    ..color = const Color(0xFFEF4444)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..isAntiAlias = true;

  final Paint _fillLockedPaint = Paint()
    ..color = const Color(0x44EF4444)
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  final Paint _centerDotPaint = Paint()
    ..color = const Color(0xFFEF4444)
    ..isAntiAlias = true;

  final Paint _crosshairPaint = Paint()
    ..color = const Color(0xCCEF4444)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  ReticleComponent() : super(priority: 70);

  @override
  void render(Canvas canvas) {
    if (game.match.phase == PaintballMatchPhase.intro) return;

    const radius = 17.0; // 34 px diameter

    // Center dot
    canvas.drawCircle(Offset.zero, 2.5, _centerDotPaint);

    if (isLockedOn) {
      // Glow fill when locked on target
      canvas.drawCircle(Offset.zero, radius, _fillLockedPaint);
      _ringPaint.strokeWidth = 3.5;
    } else {
      _ringPaint.strokeWidth = 2.2;
    }

    // Outer ring
    canvas.drawCircle(Offset.zero, radius, _ringPaint);

    // Crosshair tick marks
    const tickLen = 5.0;
    const gap = 12.0;

    // Left
    canvas.drawLine(const Offset(-gap - tickLen, 0), const Offset(-gap, 0), _crosshairPaint);
    // Right
    canvas.drawLine(const Offset(gap, 0), const Offset(gap + tickLen, 0), _crosshairPaint);
    // Top
    canvas.drawLine(const Offset(0, -gap - tickLen), const Offset(0, -gap), _crosshairPaint);
    // Bottom
    canvas.drawLine(const Offset(0, gap), const Offset(0, gap + tickLen), _crosshairPaint);
  }
}
