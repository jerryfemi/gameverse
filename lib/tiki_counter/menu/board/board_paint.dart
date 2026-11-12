import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'package:b_ball/tiki_counter/theme/ball_look.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:tiki_core/model/game_mode.dart';

/// Maps pitch metres (centre = 0,0; +x = the goal we attack) onto a
/// canvas of a given size, keeping the pitch's proportions.
class BoardGeometry {
  final GameMode mode;
  final Size size;
  late final double scale;
  late final Offset origin;

  static const double margin = 3.2; // board around the lines (room for labels)

  BoardGeometry(this.mode, this.size) {
    final w = mode.length + margin * 2;
    final h = mode.width + margin * 2;
    scale = math.min(size.width / w, size.height / h);
    origin = Offset(size.width / 2, size.height / 2);
  }

  Offset at(double x, double y) =>
      Offset(origin.dx + x * scale, origin.dy + y * scale);

  double px(double metres) => metres * scale;

  /// The pitch as fractions of the canvas (for placing Flutter widgets).
  Offset fraction(double x, double y) {
    final p = at(x, y);
    return Offset(p.dx / size.width, p.dy / size.height);
  }
}

/// Drawing helpers shared by every menu board. Paints are made once.
abstract final class BoardPaint {
  static final Paint _grass = Paint()..color = TikiPalette.pitch;
  static final Paint _stripe = Paint()..color = TikiPalette.stripe;
  static final Paint _chalk = Paint()
    ..color = TikiPalette.chalk
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final Paint _shadow = Paint()..color = const Color(0x55000000);
  static final Paint _fill = Paint();
  static final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = TikiPalette.cyan;

  static final Paint _head = Paint()..style = PaintingStyle.fill;

  static final Map<String, TextPainter> _labels = {};

  /// Grass, mowing stripes and chalk lines.
  static void pitch(Canvas c, BoardGeometry g) {
    final m = g.mode;
    final hl = m.halfLength;
    final hw = m.halfWidth;
    final grass = Rect.fromPoints(
      g.at(-hl - 1.2, -hw - 1.2),
      g.at(hl + 1.2, hw + 1.2),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(grass, Radius.circular(g.px(0.8))),
      _grass,
    );
    c.save();
    c.clipRect(grass);
    for (var x = -hl - 1.2; x < hl + 1.2; x += 10.0) {
      c.drawRect(
        Rect.fromLTRB(g.at(x, 0).dx, grass.top, g.at(x + 5.0, 0).dx, grass.bottom),
        _stripe,
      );
    }
    c.restore();
    c.drawRect(Rect.fromPoints(g.at(-hl, -hw), g.at(hl, hw)), _chalk);
    c.drawLine(g.at(0, -hw), g.at(0, hw), _chalk);
    c.drawCircle(g.at(0, 0), g.px(m.centreCircle), _chalk);
    for (final s in [-1.0, 1.0]) {
      final bx = s * hl;
      final ix = s * (hl - m.boxDepth);
      c.drawRect(
        Rect.fromPoints(g.at(bx, -m.boxWidth / 2), g.at(ix, m.boxWidth / 2)),
        _chalk,
      );
      final gx = s * (hl + 0.9);
      c.drawRect(
        Rect.fromPoints(g.at(bx, -m.goalWidth / 2), g.at(gx, m.goalWidth / 2)),
        _chalk,
      );
    }
  }

  /// "YOUR GOAL" / "THEIR GOAL" by the goals and "ATTACKING →" under the
  /// pitch, so there's never a doubt which way the team plays. Menu boards
  /// always show your team attacking to the right.
  static void directionLabels(Canvas c, BoardGeometry g) {
    final hl = g.mode.halfLength;
    final hw = g.mode.halfWidth;
    final size = (g.px(1.15)).clamp(9.0, 13.0).toDouble();
    final yours = _caption('YOUR GOAL', size, const Color(0xB3E8F0EA));
    final theirs = _caption('THEIR GOAL', size, const Color(0xB3F59E0B));
    final attack = _caption('ATTACKING  →', size, TikiPalette.cyan);
    final top = g.at(0, -hw - 0.5).dy - yours.height - 2;
    yours.paint(c, Offset(g.at(-hl, 0).dx, top));
    theirs.paint(c, Offset(g.at(hl, 0).dx - theirs.width, top));
    final under = g.at(0, hw + 0.5).dy + 2;
    attack.paint(c, Offset(g.at(0, 0).dx - attack.width / 2, under));
  }

  static TextPainter _caption(String text, double size, Color color) {
    final key = 'cap|$text|$size';
    return _labels.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Archivo',
            fontWeight: FontWeight.w800,
            fontSize: size,
            letterSpacing: 1.4,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  /// A magnet disc with a number. [ours] = bone, else amber.
  static void disc(
    Canvas c,
    BoardGeometry g,
    Offset at,
    int number, {
    required bool ours,
    bool ring = false,
    double radiusM = 1.15,
  }) {
    final r = g.px(radiusM);
    c.drawOval(
      Rect.fromCenter(center: at + Offset(r * 0.15, r * 0.45), width: r * 2.2, height: r * 1.1),
      _shadow,
    );
    _fill.color = ours ? TikiPalette.homeEdge : TikiPalette.awayEdge;
    c.drawCircle(at + Offset(0, r * 0.14), r, _fill);
    _fill.color = ours ? TikiPalette.homeFill : TikiPalette.awayFill;
    c.drawCircle(at, r * 0.94, _fill);
    if (ring) c.drawCircle(at, r * 1.25, _ring);
    final tp = _label('$number', ours, r);
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  static void ball(Canvas c, BoardGeometry g, Offset at) {
    final r = g.px(0.5);
    c.drawCircle(at + Offset(r * 0.3, r * 0.5), r, _shadow);
    BallLook.draw(c, at, r, 0.3);
  }

  /// Cached number labels (keyed by text, colour and size).
  static TextPainter _label(String text, bool ours, double r) {
    final size = (r * 1.05).roundToDouble();
    final key = '$text|$ours|$size';
    return _labels.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Archivo',
            fontWeight: FontWeight.w800,
            fontSize: size,
            color: ours ? TikiPalette.homeText : TikiPalette.awayText,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  /// Straight arrow from [a] to [b] (head at [b]); [dashed] for passes.
  static void arrow(
    Canvas c,
    Offset a,
    Offset b,
    Paint paint, {
    bool dashed = false,
    double head = 9,
  }) {
    final d = b - a;
    final len = d.distance;
    if (len < 4) return;
    final u = d / len;
    final end = b - u * (head * 0.6);
    if (dashed) {
      const dash = 7.0;
      const gap = 5.0;
      var t = 0.0;
      while (t < len - head) {
        final t2 = math.min(t + dash, len - head);
        c.drawLine(a + u * t, a + u * t2, paint);
        t += dash + gap;
      }
    } else {
      c.drawLine(a, end, paint);
    }
    final n = Offset(-u.dy, u.dx);
    final path = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(b.dx - u.dx * head + n.dx * head * 0.55, b.dy - u.dy * head + n.dy * head * 0.55)
      ..lineTo(b.dx - u.dx * head - n.dx * head * 0.55, b.dy - u.dy * head - n.dy * head * 0.55)
      ..close();
    _head.color = paint.color;
    c.drawPath(path, _head);
  }
}
