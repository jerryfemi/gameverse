import 'dart:ui';

import 'package:flame/components.dart';

import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/ball_look.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:tiki_core/core/tunables.dart';

/// The ball (yellow with black patches). It rolls as it moves; in the air
/// it rises, grows a little, and leaves its shadow on the grass so you can
/// read lobs.
class BallComponent extends Component with HasGameReference<TikiFlameGame> {
  BallComponent() : super(priority: 20);

  final Paint _shadow = Paint()..color = TikiPalette.shadow;

  /// How far the patches have turned (radians), from distance rolled.
  double _spin = 0.0;
  double _lastX = 0.0;
  double _lastY = 0.0;

  @override
  void render(Canvas canvas) {
    final v = game.view;
    final b = game.runner.state.ball;
    final a = game.alpha;
    final mx = b.prev.x + (b.pos.x - b.prev.x) * a;
    final my = b.prev.y + (b.pos.y - b.prev.y) * a;
    final x = v.sx(mx);
    final y = v.sy(my);
    final z = b.prevZ + (b.z - b.prevZ) * a;
    final r = v.px(T.ballRadius) * (1.0 + z * 0.12);
    final lift = v.px(z) * 0.6;

    // Roll: angle = distance / radius (metres), direction from the move.
    final dx = mx - _lastX;
    final dy = my - _lastY;
    final moved = dx.abs() + dy.abs();
    if (moved < 3.0) {
      _spin += (dx >= 0 ? 1.0 : -1.0) * moved / T.ballRadius * 0.35;
    }
    _lastX = mx;
    _lastY = my;

    canvas.drawCircle(Offset(x + r * 0.2, y + r * 0.5), r, _shadow);
    BallLook.draw(canvas, Offset(x, y - lift), r, _spin);
  }
}
