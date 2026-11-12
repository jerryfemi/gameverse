import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/side.dart';
import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';

/// Draws every disc: drop shadow, raised edge, face, rim and shirt number.
///
/// One component draws all discs (cheaper than one component each). Paints
/// and number labels are made once and reused, so a frame allocates nothing.
class DiscsComponent extends Component with HasGameReference<TikiFlameGame> {
  DiscsComponent() : super(priority: 10);

  final Paint _shadow = Paint()..color = TikiPalette.shadow;
  final Map<Side, Paint> _fill = {
    Side.home: Paint()..color = TikiPalette.homeFill,
    Side.away: Paint()..color = TikiPalette.awayFill,
  };
  final Map<Side, Paint> _edge = {
    Side.home: Paint()..color = TikiPalette.homeEdge,
    Side.away: Paint()..color = TikiPalette.awayEdge,
  };
  final Map<Side, Paint> _rim = {
    Side.home: Paint()
      ..color = TikiPalette.homeRim
      ..style = PaintingStyle.stroke,
    Side.away: Paint()
      ..color = TikiPalette.awayRim
      ..style = PaintingStyle.stroke,
  };

  /// One label per disc, rebuilt only when the board is resized.
  final List<TextPainter> _labels = [];
  int _labelsFor = -1;

  @override
  void render(Canvas canvas) {
    final v = game.view;
    final s = game.runner.state;
    final a = game.alpha;
    final r = v.px(T.discRadius);
    if (_labelsFor != v.version) _buildLabels(s.discs, r);
    final rimWidth = r * 0.2;
    _rim[Side.home]!.strokeWidth = rimWidth;
    _rim[Side.away]!.strokeWidth = rimWidth;

    for (final d in s.discs) {
      final x = v.sx(d.prev.x + (d.pos.x - d.prev.x) * a);
      final y = v.sy(d.prev.y + (d.pos.y - d.prev.y) * a);
      canvas.drawCircle(Offset(x + r * 0.15, y + r * 0.45), r, _shadow);
      canvas.drawCircle(Offset(x, y + r * 0.2), r, _edge[d.side]!);
      canvas.drawCircle(Offset(x, y), r, _fill[d.side]!);
      canvas.drawCircle(Offset(x, y), r - rimWidth / 2.0, _rim[d.side]!);
      final label = _labels[d.id];
      label.paint(
        canvas,
        Offset(x - label.width / 2.0, y - label.height / 2.0),
      );
    }
  }

  void _buildLabels(List<Disc> discs, double r) {
    for (final l in _labels) {
      l.dispose();
    }
    _labels.clear();
    for (final d in discs) {
      final color =
          d.side == Side.home ? TikiPalette.homeText : TikiPalette.awayText;
      _labels.add(
        TextPainter(
          text: TextSpan(
            text: '${d.number}',
            style: TextStyle(
              color: color,
              fontSize: r * 0.85,
              fontWeight: FontWeight.w700,
              fontFamily: 'Archivo',
              fontVariations: const [FontVariation('wght', 700)],
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
    }
    _labelsFor = game.view.version;
  }

  @override
  void onRemove() {
    for (final l in _labels) {
      l.dispose();
    }
    _labels.clear();
    super.onRemove();
  }
}
