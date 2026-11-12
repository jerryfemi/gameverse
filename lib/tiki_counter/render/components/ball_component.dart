import 'dart:ui';

import 'package:flame/components.dart';

import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:tiki_core/core/tunables.dart';

/// The white pellet. In the air it rises, grows a little, and leaves its
/// shadow on the grass so you can read lobs.
class BallComponent extends Component with HasGameReference<TikiFlameGame> {
  BallComponent() : super(priority: 20);

  final Paint _shadow = Paint()..color = TikiPalette.shadow;
  final Paint _fill = Paint()..color = TikiPalette.ball;
  final Paint _outline = Paint()
    ..color = TikiPalette.ballOutline
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final v = game.view;
    final b = game.runner.state.ball;
    final a = game.alpha;
    final x = v.sx(b.prev.x + (b.pos.x - b.prev.x) * a);
    final y = v.sy(b.prev.y + (b.pos.y - b.prev.y) * a);
    final z = b.prevZ + (b.z - b.prevZ) * a;
    final r = v.px(T.ballRadius) * (1.0 + z * 0.12);
    final lift = v.px(z) * 0.6;

    canvas.drawCircle(Offset(x + r * 0.2, y + r * 0.5), r, _shadow);
    _outline.strokeWidth = r * 0.3;
    canvas.drawCircle(Offset(x, y - lift), r, _fill);
    canvas.drawCircle(Offset(x, y - lift), r, _outline);
  }
}
