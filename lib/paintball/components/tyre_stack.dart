import 'dart:ui';
import 'package:flame/components.dart';
import 'package:b_ball/paintball/paintball_constants.dart';

/// One 4-tire defensive stack positioned in a specific lane.
///
/// Follows Paintball Plan §4 & §7:
/// - Near variant (priority 50): Foreground cover stack in front of the player.
/// - Far variant (priority 10 / 30): Distance cover stacks across the far row.
/// - Parallax: Far tires shift horizontally by [cameraPanOffset] * [PaintballK.parallaxFarTires] (0.80x).
/// - 4 stacked black matte tires with rubber specular rim and drop shadow.
class TyreStackComponent extends PositionComponent with HasGameReference {
  final int lane;
  final bool isNear;
  double cameraPanOffset = 0.0;

  // ─── Pre-allocated Paints ─────────────────────────────────────────────────
  final Paint _shadowPaint = Paint()
    ..color = const Color(0x55000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  final Paint _tireBasePaint = Paint()..color = const Color(0xFF18181B); // deep rubber black
  final Paint _tireRimPaint = Paint()..color = const Color(0xFF27272A);  // tire side highlight
  final Paint _tireTopTreadPaint = Paint()..color = const Color(0xFF09090B); // dark center hole
  final Paint _rimHighlightPaint = Paint()
    ..color = const Color(0xFF3F3F46)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  TyreStackComponent({
    required this.lane,
    required this.isNear,
  }) : super(priority: isNear ? 50 : 25);

  @override
  void render(Canvas canvas) {
    final shiftX = cameraPanOffset * (isNear ? 1.0 : PaintballK.parallaxFarTires);

    canvas.save();
    canvas.translate(shiftX, 0);

    final w = size.x;
    final h = size.y;

    // 1. Contact shadow under bottom tire
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.98),
        width: w * 0.95,
        height: h * 0.18,
      ),
      _shadowPaint,
    );

    // 2. 4 stacked tires (bottom to top)
    final tireH = h * 0.28;
    final overlap = h * 0.06;

    for (int i = 3; i >= 0; i--) {
      final cy = h * 0.85 - (i * (tireH - overlap));
      _drawSingleTire(canvas, w * 0.5, cy, w, tireH, i == 0);
    }

    canvas.restore();
  }

  void _drawSingleTire(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    bool isTopTire,
  ) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.45));

    // Outer tire body
    canvas.drawRRect(rrect, _tireBasePaint);

    // Tread highlight ring
    canvas.drawRRect(rrect, _rimHighlightPaint);

    // Inner rim depth
    final innerW = w * 0.65;
    final innerH = h * 0.55;
    final innerRect = Rect.fromCenter(center: Offset(cx, cy), width: innerW, height: innerH);
    canvas.drawOval(innerRect, _tireRimPaint);

    if (isTopTire) {
      // Hollow center hole on the very top tire
      final holeRect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: innerW * 0.65,
        height: innerH * 0.65,
      );
      canvas.drawOval(holeRect, _tireTopTreadPaint);
    }
  }
}
