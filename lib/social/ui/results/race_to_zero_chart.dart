import 'dart:math' as math;

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';

import 'package:b_ball/social/ui/common/section_label.dart';

/// Interactive/static Race-to-Zero line chart visualizing the 301 countdown
/// trajectory for both players across all played rounds.
class RaceToZeroChart extends StatelessWidget {
  final List<int> p1RoundScores;
  final List<int> p2RoundScores;
  final String p1Name;
  final String p2Name;

  const RaceToZeroChart({
    super.key,
    required this.p1RoundScores,
    required this.p2RoundScores,
    this.p1Name = 'You',
    this.p2Name = 'Opponent',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(text: 'RACE TO ZERO'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          ),
          child: SizedBox(
            height: 140.0,
            child: CustomPaint(
              painter: _RaceToZeroPainter(
                p1Scores: p1RoundScores,
                p2Scores: p2RoundScores,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RaceToZeroPainter extends CustomPainter {
  final List<int> p1Scores;
  final List<int> p2Scores;

  _RaceToZeroPainter({required this.p1Scores, required this.p2Scores});

  static const Color youColor = Color(0xFF38BDF8);
  static const Color oppColor = Color(0xFFF59E0B);
  static const Color mintCheckout = Color(0xFF00FFCC);
  static const Color gridColor = Color(0xFF1E293B);
  static const Color axisLabelColor = Color(0xFF64748B);

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 32.0;
    const double bottomMargin = 22.0;
    const double topMargin = 8.0;
    const double rightMargin = 12.0;

    final double plotWidth = size.width - leftMargin - rightMargin;
    final double plotHeight = size.height - topMargin - bottomMargin;

    if (plotWidth <= 0 || plotHeight <= 0) return;

    final int totalRounds = math.max(
      1,
      math.max(p1Scores.length, p2Scores.length),
    );

    // 1. Calculate trajectory data points
    List<int> calculateTrajectory(List<int> scores) {
      final list = <int>[301];
      int remaining = 301;
      for (final s in scores) {
        remaining = math.max(0, remaining - s);
        list.add(remaining);
      }
      return list;
    }

    final p1Points = calculateTrajectory(p1Scores);
    final p2Points = calculateTrajectory(p2Scores);

    // 2. Draw Y-axis gridlines and labels: 301, 150, 0
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final yValues = [301, 150, 0];
    for (final val in yValues) {
      final double normalizedY = 1.0 - (val / 301.0);
      final double y = topMargin + normalizedY * plotHeight;

      // Draw horizontal line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );

      // Y-axis text label
      final tp = TextPainter(
        text: TextSpan(
          text: '$val',
          style: UiFont.style(size: 10.0, weight: 600, color: axisLabelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(leftMargin - tp.width - 6.0, y - tp.height / 2));
    }

    // 3. Draw X-axis labels (R1... Rn)
    for (int r = 1; r <= totalRounds; r++) {
      final double x = leftMargin + (r / totalRounds) * plotWidth;
      final tp = TextPainter(
        text: TextSpan(
          text: 'R$r',
          style: UiFont.style(size: 10.0, weight: 600, color: axisLabelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(x - tp.width / 2, size.height - bottomMargin + 6.0),
      );
    }

    // Helper to map (roundIndex, remaining) -> Offset
    Offset toOffset(int roundIndex, int remainingScore) {
      final double x = leftMargin + (roundIndex / totalRounds) * plotWidth;
      final double normalizedY = 1.0 - (remainingScore.clamp(0, 301) / 301.0);
      final double y = topMargin + normalizedY * plotHeight;
      return Offset(x, y);
    }

    void drawTrajectory(List<int> points, Color color) {
      if (points.isEmpty) return;

      final path = Path();
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      final startOffset = toOffset(0, points[0]);
      path.moveTo(startOffset.dx, startOffset.dy);

      for (int i = 1; i < points.length; i++) {
        final pt = toOffset(i, points[i]);
        path.lineTo(pt.dx, pt.dy);
      }

      canvas.drawPath(path, linePaint);

      // If the last point reached 0 (checkout), draw a glowing mint dot
      if (points.last == 0) {
        final checkoutPt = toOffset(points.length - 1, 0);

        final haloPaint = Paint()
          ..color = mintCheckout.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(checkoutPt, 7.5, haloPaint);

        final dotPaint = Paint()
          ..color = mintCheckout
          ..style = PaintingStyle.fill;
        canvas.drawCircle(checkoutPt, 4.0, dotPaint);

        final corePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(checkoutPt, 1.8, corePaint);
      }
    }

    // Draw Opponent line first (underneath), then You (on top)
    drawTrajectory(p2Points, oppColor);
    drawTrajectory(p1Points, youColor);
  }

  @override
  bool shouldRepaint(covariant _RaceToZeroPainter oldDelegate) =>
      oldDelegate.p1Scores != p1Scores || oldDelegate.p2Scores != p2Scores;
}
