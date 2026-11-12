import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:tiki_core/core/tunables.dart';

/// Debug view (toggle with the DBG pill): for every disc the brain steers,
/// a line to its target and the name of its current job. This is how you
/// see *why* a disc is doing what it does.
class DebugComponent extends Component with HasGameReference<TikiFlameGame> {
  DebugComponent() : super(priority: 40);

  final Paint _line = Paint()
    ..color = const Color(0x66FFFFFF)
    ..strokeWidth = 1.0;
  final Paint _dot = Paint()..color = const Color(0xAAFFFFFF);
  final Paint _offside = Paint()
    ..color = const Color(0xFFEF4444)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  /// Cached labels: re-laid out only when a disc's job text changes.
  final List<TextPainter?> _labels = [];
  final List<String> _texts = [];

  @override
  void render(Canvas canvas) {
    if (!game.showDebug) return;
    final s = game.runner.state;
    final v = game.view;
    final r = v.px(T.discRadius);
    while (_labels.length < s.discs.length) {
      _labels.add(null);
      _texts.add('');
    }
    for (final d in s.discs) {
      final x = v.sx(d.pos.x);
      final y = v.sy(d.pos.y);
      if (s.ball.offsideIds.contains(d.id)) {
        canvas.drawCircle(Offset(x, y), r + 3.0, _offside);
      }
      if (!d.manual) {
        final tx = v.sx(d.target.x);
        final ty = v.sy(d.target.y);
        canvas.drawLine(Offset(x, y), Offset(tx, ty), _line);
        canvas.drawCircle(Offset(tx, ty), 2.5, _dot);
      }
      final label = _label(d.id, d.job);
      label.paint(canvas, Offset(x - label.width / 2.0, y + r + 3.0));
    }
  }

  TextPainter _label(int id, String text) {
    final cached = _labels[id];
    if (cached != null && _texts[id] == text) return cached;
    cached?.dispose();
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xCCFFFFFF),
          fontSize: 9.0,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _labels[id] = p;
    _texts[id] = text;
    return p;
  }
}
