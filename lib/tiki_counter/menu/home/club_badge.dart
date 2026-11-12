import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Shield crest with a disc and the club's short form on it.
class ClubBadge extends StatelessWidget {
  final String code;
  final double size;
  final bool away;

  const ClubBadge({super.key, required this.code, this.size = 52, this.away = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(
        painter: _ShieldPainter(away ? TikiPalette.amber : TikiPalette.cyan),
        child: Align(
          alignment: const Alignment(0, -0.18),
          child: Container(
            width: size * 0.52,
            height: size * 0.52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: away ? TikiPalette.awayFill : TikiPalette.homeFill,
            ),
            child: Text(
              code.toUpperCase(),
              style: TikiText.display(
                size: size * 0.17,
                weight: 900,
                color: away ? TikiPalette.awayText : TikiPalette.homeText,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final Color accent;

  _ShieldPainter(this.accent);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.03)
      ..lineTo(w * 0.95, h * 0.17)
      ..lineTo(w * 0.95, h * 0.5)
      ..cubicTo(w * 0.95, h * 0.76, w * 0.75, h * 0.9, w * 0.5, h * 0.97)
      ..cubicTo(w * 0.25, h * 0.9, w * 0.05, h * 0.76, w * 0.05, h * 0.5)
      ..lineTo(w * 0.05, h * 0.17)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFF0F1A15));
    c.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04,
    );
    c.drawLine(
      Offset(w * 0.26, h * 0.76),
      Offset(w * 0.74, h * 0.76),
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = w * 0.035,
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.accent != accent;
}
