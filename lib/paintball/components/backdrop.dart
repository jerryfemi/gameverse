import 'dart:ui';
import 'package:flame/components.dart';
import 'package:b_ball/paintball/paintball_constants.dart';

/// 2.5D outdoor paintball arena backdrop with parallax scrolling.
///
/// Follows Paintball Plan §5c & §7:
/// - Priority 0 (drawn at the very back).
/// - Sky gradient, soft mountain/tree horizon, and grassy tournament field with sand traps.
/// - Shifts horizontally by [cameraPanOffset] * [PaintballK.parallaxBackdrop] (0.30x).
/// - Zero heap allocations during [render].
class PaintballBackdrop extends Component with HasGameReference {
  double cameraPanOffset = 0.0;
  double cameraDipOffset = 0.0;

  // ─── Pre-allocated Paints ─────────────────────────────────────────────────
  final Paint _skyPaint = Paint();
  final Paint _groundPaint = Paint()..color = const Color(0xFF65A30D);
  final Paint _groundAccentPaint = Paint()..color = const Color(0xFF4D7C0F);
  final Paint _sandPaint = Paint()..color = const Color(0xFFE5D2A0);
  final Paint _treePaintNear = Paint()..color = const Color(0xFFA3E635);
  final Paint _treePaintMid = Paint()..color = const Color(0xFF86EFAC);
  final Paint _treePaintFar = Paint()..color = const Color(0xFF99F6E4);

  // Cached geometry
  Size _lastSize = Size.zero;
  Rect _skyRect = Rect.zero;
  Rect _groundRect = Rect.zero;

  @override
  int get priority => 0;

  @override
  void render(Canvas canvas) {
    final size = game.size;
    if (size.x <= 0 || size.y <= 0) return;

    if (_lastSize.width != size.x || _lastSize.height != size.y) {
      _lastSize = Size(size.x, size.y);
      _rebuildStaticGeometry(size.x, size.y);
    }

    // Parallax horizontal & vertical shift for backdrop
    final shiftX = cameraPanOffset * PaintballK.parallaxBackdrop;
    final shiftY = -cameraDipOffset * PaintballK.parallaxBackdropY;

    canvas.save();
    canvas.translate(shiftX, shiftY);

    // 1. Sky
    canvas.drawRect(_skyRect, _skyPaint);

    // 2. Far & Mid Tree Line (Stylized Poly Clusters)
    _renderTreeLine(canvas, size.x, size.y);

    // 3. Grassy Field Ground
    canvas.drawRect(_groundRect, _groundPaint);

    // 4. Sand Bunkers / Dirt Patches
    _renderGroundPatches(canvas, size.x, size.y);

    canvas.restore();
  }

  void _rebuildStaticGeometry(double w, double h) {
    final horizonY = h * 0.38;

    _skyRect = Rect.fromLTWH(-w * 0.8, -h * 0.3, w * 2.6, horizonY + (h * 0.3));
    _groundRect = Rect.fromLTWH(-w * 0.8, horizonY, w * 2.6, (h - horizonY) + (h * 0.5));

    _skyPaint.shader = Gradient.linear(
      Offset(w * 0.5, -h * 0.3),
      Offset(w * 0.5, horizonY),
      const [
        Color(0xFF38BDF8), // vibrant clear sky cyan
        Color(0xFF7DD3FC),
        Color(0xFFBAE6FD), // soft horizon
      ],
      const [0.0, 0.6, 1.0],
    );
  }

  void _renderTreeLine(Canvas canvas, double w, double h) {
    final horizonY = h * 0.38;

    // Distant soft tree domes
    final step = w * 0.22;
    for (double x = -w * 0.7; x < w * 1.8; x += step) {
      // Far layer
      canvas.drawCircle(Offset(x, horizonY - 10), step * 0.60, _treePaintFar);
      // Mid layer
      canvas.drawCircle(Offset(x + step * 0.4, horizonY), step * 0.52, _treePaintMid);
      // Near layer
      canvas.drawCircle(Offset(x + step * 0.15, horizonY + 8), step * 0.45, _treePaintNear);
    }
  }

  void _renderGroundPatches(Canvas canvas, double w, double h) {
    final horizonY = h * 0.38;

    // Distant fairway curve
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.35, horizonY + (h * 0.14)),
        width: w * 0.90,
        height: h * 0.12,
      ),
      _sandPaint,
    );

    // Foreground tactical sand bunker
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.15, h * 0.66),
        width: w * 0.70,
        height: h * 0.16,
      ),
      _sandPaint,
    );

    // Additional subtle lawn bands
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.85, h * 0.62),
        width: w * 0.65,
        height: h * 0.14,
      ),
      _groundAccentPaint,
    );
  }
}
