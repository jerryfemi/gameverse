import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';

/// Background pictures for the three home tiles, drawn in code so they
/// cost no download and stay sharp at any size. Each fills its whole box
/// (cropped like `BoxFit.cover`).

/// KICK OFF: a close-up of discs facing off at the centre circle, a ball
/// rolling along a chalk pass arrow. [t] (0..1, looping) drives the motion.
class KickOffArt extends CustomPainter {
  final Animation<double> t;

  KickOffArt(this.t) : super(repaint: t);

  static final Paint _bg = Paint();
  static final Paint _line = Paint()
    ..color = const Color(0x52E8F0EA)
    ..style = PaintingStyle.stroke;
  static final Paint _pass = Paint()
    ..color = const Color(0xD900FFCC)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _shadow = Paint()..color = const Color(0x59000000);
  static final Paint _fill = Paint();

  // Everything but the ball is recorded once per size and replayed.
  ui.Picture? _picture;
  Size? _pictureSize;
  ui.PathMetric? _passLine;
  double _u = 1.0;

  @override
  void paint(Canvas c, Size s) {
    if (_picture == null || _pictureSize != s) {
      _picture?.dispose();
      final rec = ui.PictureRecorder();
      _record(Canvas(rec), s);
      _picture = rec.endRecording();
      _pictureSize = s;
    }
    c.drawPicture(_picture!);

    // Ball travels along the first part of the pass, then resets.
    final line = _passLine!;
    final k = Curves.easeOut.transform((t.value * 1.4).clamp(0.0, 1.0).toDouble());
    final pos = line.getTangentForOffset(line.length * 0.6 * k)!.position;
    final u = _u;
    c.drawOval(
      Rect.fromCenter(center: pos + Offset(4 * u, 12 * u), width: 28 * u, height: 10 * u),
      _shadow,
    );
    _fill.color = TikiPalette.ball;
    c.drawCircle(pos, 11 * u, _fill);
  }

  void _record(Canvas c, Size s) {
    final u = math.max(s.width / 760, s.height / 560); // cover-scale
    _u = u;
    final o = Offset((s.width - 760 * u) / 2, (s.height - 560 * u) / 2);
    Offset p(double x, double y) => o + Offset(x * u, y * u);

    _bg.shader = const RadialGradient(
      center: Alignment(0.1, -0.2),
      radius: 0.9,
      colors: [Color(0xFF1F5A41), Color(0xFF0B2419)],
    ).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, _bg);

    _line.strokeWidth = 3 * u;
    c.drawCircle(p(380, 250), 120 * u, _line);
    c.drawLine(p(380, -10), p(380, 570), _line);

    // Pass arrow (dashed curve).
    _pass.strokeWidth = 3 * u;
    final a = p(300, 300);
    final c1 = p(360, 240);
    final c2 = p(420, 210);
    final e = p(500, 192);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e.dx, e.dy);
    final metric = path.computeMetrics().first;
    _passLine = metric;
    var d = 0.0;
    while (d < metric.length) {
      c.drawPath(metric.extractPath(d, math.min(d + 9 * u, metric.length)), _pass);
      d += 17 * u;
    }

    _disc(c, p(285, 296), 40 * u, '8', home: true);
    _disc(c, p(520, 186), 36 * u, '9', home: true);
    _disc(c, p(425, 346), 38 * u, '4', home: false);
    _disc(c, p(620, 328), 34 * u, '5', home: false);
  }

  void _disc(Canvas c, Offset at, double r, String n, {required bool home}) {
    c.drawOval(
      Rect.fromCenter(center: at + Offset(r * 0.2, r * 0.6), width: r * 2.3, height: r * 0.7),
      _shadow,
    );
    _fill.color = home ? const Color(0xFF6E7685) : TikiPalette.awayEdge;
    c.drawCircle(at + Offset(0, r * 0.15), r, _fill);
    _fill.shader = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      colors: home
          ? const [Color(0xFFFFFFFF), TikiPalette.homeFill, Color(0xFFB9B3A6)]
          : const [Color(0xFFFFD58A), TikiPalette.awayFill, Color(0xFF9A5A07)],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromCircle(center: at, radius: r));
    c.drawCircle(at, r * 0.95, _fill);
    _fill.shader = null;
    final tp = TextPainter(
      text: TextSpan(
        text: n,
        style: TextStyle(
          fontFamily: 'Archivo',
          fontWeight: FontWeight.w900,
          fontSize: r * 0.8,
          color: home ? const Color(0xFF0A100D) : const Color(0xFF2A1503),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(KickOffArt old) => false;
}

/// GAME PLAN: a chalk sketch — X's, O's and run arrows on a dark slate.
class GamePlanArt extends CustomPainter {
  static final Paint _chalk = Paint()
    ..color = const Color(0xB3E8F0EA)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _faint = Paint()
    ..color = const Color(0x2EE8F0EA)
    ..style = PaintingStyle.stroke;
  static final Paint _cyan = Paint()
    ..color = const Color(0xCC00FFCC)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A23), Color(0xFF0C1511)],
        ).createShader(Offset.zero & s),
    );
    final u = math.max(s.width / 460, s.height / 250);
    final o = Offset((s.width - 460 * u) / 2, (s.height - 250 * u) / 2);
    Offset p(double x, double y) => o + Offset(x * u, y * u);
    _faint.strokeWidth = 2 * u;
    _chalk.strokeWidth = 3 * u;
    _cyan.strokeWidth = 3 * u;
    c.drawRect(Rect.fromPoints(p(150, 16), p(450, 234)), _faint);
    c.drawLine(p(300, 16), p(300, 234), _faint);
    c.drawCircle(p(300, 125), 34 * u, _faint);
    for (final x in [p(206, 76), p(221, 171), p(336, 116)]) {
      c.drawLine(x - Offset(6 * u, 6 * u), x + Offset(6 * u, 6 * u), _chalk);
      c.drawLine(x + Offset(-6 * u, 6 * u), x + Offset(6 * u, -6 * u), _chalk);
    }
    for (final pt in [p(270, 75), p(285, 170), p(390, 125)]) {
      c.drawCircle(pt, 9 * u, _cyan);
    }
    final a = Path()
      ..moveTo(p(272, 88).dx, p(272, 88).dy)
      ..cubicTo(p(300, 130).dx, p(300, 130).dy, p(340, 150).dx, p(340, 150).dy, p(378, 132).dx, p(378, 132).dy);
    c.drawPath(a, _chalk);
    final b = Path()
      ..moveTo(p(287, 158).dx, p(287, 158).dy)
      ..cubicTo(p(320, 100).dx, p(320, 100).dy, p(360, 90).dx, p(360, 90).dy, p(410, 70).dx, p(410, 70).dy);
    c.drawPath(b, _cyan);
  }

  @override
  bool shouldRepaint(GamePlanArt old) => false;
}

/// LAB: a disc leaving a ghost trail across grid paper, an opponent
/// tracking it.
class LabArt extends CustomPainter {
  static final Paint _grid = Paint()
    ..color = const Color(0x1200FFCC)
    ..strokeWidth = 1;
  static final Paint _fill = Paint();
  static final Paint _trail = Paint()
    ..color = const Color(0x8000FFCC)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _fill..color = const Color(0xFF0E1613));
    for (var x = 0.0; x < s.width; x += 20) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), _grid);
    }
    for (var y = 0.0; y < s.height; y += 20) {
      c.drawLine(Offset(0, y), Offset(s.width, y), _grid);
    }
    final u = math.max(s.width / 460, s.height / 250);
    final o = Offset((s.width - 460 * u) / 2, (s.height - 250 * u) / 2);
    Offset p(double x, double y) => o + Offset(x * u, y * u);
    _trail.strokeWidth = 2 * u;
    c.drawLine(p(150, 190), p(345, 80), _trail);
    const ghosts = [(190.0, 180.0, 0x1F), (240.0, 150.0, 0x38), (290.0, 112.0, 0x61)];
    for (final g in ghosts) {
      c.drawCircle(p(g.$1, g.$2), 16 * u, _fill..color = Color((g.$3 << 24) | 0xF1EDE4));
    }
    c.drawCircle(p(345, 80), 18 * u, _fill..color = TikiPalette.homeFill);
    c.drawCircle(p(400, 160), 16 * u, _fill..color = const Color(0xD9F59E0B));
  }

  @override
  bool shouldRepaint(LabArt old) => false;
}
