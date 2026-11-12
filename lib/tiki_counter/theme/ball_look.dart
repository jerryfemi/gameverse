import 'dart:math' as math;
import 'dart:ui';

/// The match ball: a yellow futsal-style ball with black patches, like a
/// tactics-board clip. Drawn the same on the match board and the menu
/// boards. Everything is built once; drawing only transforms the canvas.
abstract final class BallLook {
  static const Color _yellow = Color(0xFFF5C518);
  static const Color _patch = Color(0xFF151515);
  static const Color _outline = Color(0xFF0A100D);

  static final Paint _fill = Paint()..color = _yellow;
  static final Paint _patchPaint = Paint()..color = _patch;
  static final Paint _shine = Paint()..color = const Color(0x59FFFFFF);
  static final Paint _rim = Paint()
    ..color = _outline
    ..style = PaintingStyle.stroke;

  /// Patches for a ball of radius 1 at angle 0: a pentagon in the middle
  /// and five around the edge (clipped by the ball's outline).
  static final Path _patches = _buildPatches();
  static final Path _unitCircle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1.0));

  static Path _buildPatches() {
    final p = Path()..addPath(_pentagon(0.0, 0.0, 0.30, -math.pi / 2), Offset.zero);
    for (var k = 0; k < 5; k++) {
      final a = -math.pi / 2 + math.pi / 5 + k * 2 * math.pi / 5;
      p.addPath(
        _pentagon(math.cos(a) * 1.02, math.sin(a) * 1.02, 0.30, a + math.pi),
        Offset.zero,
      );
    }
    return p;
  }

  static Path _pentagon(double cx, double cy, double r, double start) {
    final p = Path();
    for (var i = 0; i < 5; i++) {
      final a = start + i * 2 * math.pi / 5;
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    return p..close();
  }

  /// Draws the ball at [at] with radius [r] (pixels), turned by [spin]
  /// radians so it rolls.
  static void draw(Canvas c, Offset at, double r, double spin) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r);
    c.drawCircle(Offset.zero, 1.0, _fill);
    c.save();
    c.clipPath(_unitCircle);
    c.rotate(spin);
    c.drawPath(_patches, _patchPaint);
    c.restore();
    c.drawCircle(const Offset(-0.38, -0.42), 0.18, _shine);
    _rim.strokeWidth = r < 6 ? 1.6 / r : 0.14;
    c.drawCircle(Offset.zero, 1.0, _rim);
    c.restore();
  }
}
