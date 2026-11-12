import 'dart:ui';

import 'package:flame/components.dart';

import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/render/pitch_view.dart';
import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';

/// The board and chalk lines. They never change during a match, so they're
/// recorded once into a [Picture] and replayed every frame (re-recorded
/// only when the screen size changes).
class PitchComponent extends Component with HasGameReference<TikiFlameGame> {
  PitchComponent() : super(priority: 0);

  Picture? _picture;
  int _builtFor = -1;

  @override
  void render(Canvas canvas) {
    final view = game.view;
    if (_picture == null || _builtFor != view.version) {
      _picture?.dispose();
      _picture = _record(view, game.runner.state.mode);
      _builtFor = view.version;
    }
    canvas.drawPicture(_picture!);
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }

  Picture _record(PitchView v, GameMode m) {
    final recorder = PictureRecorder();
    final c = Canvas(recorder);
    final hl = m.halfLength;
    final hw = m.halfWidth;
    const frameM = PitchView.marginMetres;
    const runOff = 1.5;

    // Frame.
    final frame = Rect.fromLTRB(
      v.sx(-hl - frameM),
      v.sy(-hw - frameM),
      v.sx(hl + frameM),
      v.sy(hw + frameM),
    );
    final frameR = RRect.fromRectAndRadius(frame, Radius.circular(v.px(1.2)));
    c.drawRRect(frameR, Paint()..color = TikiPalette.frame);
    c.drawRRect(
      frameR,
      Paint()
        ..color = TikiPalette.frameBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Grass with mowing stripes (5 m bands).
    final grass = Rect.fromLTRB(
      v.sx(-hl - runOff),
      v.sy(-hw - runOff),
      v.sx(hl + runOff),
      v.sy(hw + runOff),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(grass, Radius.circular(v.px(0.4))),
      Paint()..color = TikiPalette.pitch,
    );
    final stripe = Paint()..color = TikiPalette.stripe;
    c.save();
    c.clipRect(grass);
    for (var x = -hl - runOff; x < hl + runOff; x += 10.0) {
      c.drawRect(
        Rect.fromLTRB(v.sx(x), grass.top, v.sx(x + 5.0), grass.bottom),
        stripe,
      );
    }
    c.restore();

    _lines(c, v, m);
    return recorder.endRecording();
  }

  void _lines(Canvas c, PitchView v, GameMode m) {
    final hl = m.halfLength;
    final hw = m.halfWidth;
    final chalk = Paint()
      ..color = TikiPalette.chalk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final dot = Paint()..color = TikiPalette.chalk;

    c.drawRect(Rect.fromLTRB(v.sx(-hl), v.sy(-hw), v.sx(hl), v.sy(hw)), chalk);
    c.drawLine(Offset(v.sx(0), v.sy(-hw)), Offset(v.sx(0), v.sy(hw)), chalk);
    c.drawCircle(Offset(v.sx(0), v.sy(0)), v.px(m.centreCircle), chalk);
    c.drawCircle(Offset(v.sx(0), v.sy(0)), 3.0, dot);

    for (final end in const [-1.0, 1.0]) {
      final line = end * hl;
      final inside = end * (hl - m.boxDepth);
      c.drawRect(
        Rect.fromLTRB(
          v.sx(end < 0 ? line : inside),
          v.sy(-m.boxWidth / 2.0),
          v.sx(end < 0 ? inside : line),
          v.sy(m.boxWidth / 2.0),
        ),
        chalk,
      );
      final spot = end * (hl - m.boxDepth * 0.66);
      c.drawCircle(Offset(v.sx(spot), v.sy(0)), 2.5, dot);

      // Goal: posts and net behind the line.
      final back = end * (hl + 1.2);
      final goal = Rect.fromLTRB(
        v.sx(end < 0 ? back : line),
        v.sy(-m.goalWidth / 2.0),
        v.sx(end < 0 ? line : back),
        v.sy(m.goalWidth / 2.0),
      );
      c.drawRect(goal, Paint()..color = const Color(0x22E8F0EA));
      c.drawRect(
        goal,
        Paint()
          ..color = TikiPalette.chalkSolid
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }
}
