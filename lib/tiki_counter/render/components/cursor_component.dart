import 'dart:ui';

import 'package:flame/components.dart';

import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';
import 'package:b_ball/tiki_counter/render/pitch_view.dart';
import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';

/// Markers for the player's team (eFootball style):
/// - cyan ring + triangle over the disc you control,
/// - small grey triangle over the next switch candidate,
/// - power bar under your disc while a button charges.
class CursorComponent extends Component with HasGameReference<TikiFlameGame> {
  CursorComponent() : super(priority: 30);

  final Paint _ring = Paint()
    ..color = TikiPalette.cyan
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _glow = Paint()
    ..color = TikiPalette.cyanGlow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0;
  final Paint _arrow = Paint()..color = TikiPalette.cyan;
  final Paint _next = Paint()..color = TikiPalette.slate;
  final Paint _barBack = Paint()..color = const Color(0x99000000);
  final Paint _barFill = Paint()..color = TikiPalette.cyan;
  final Path _tri = Path();

  @override
  void render(Canvas canvas) {
    final team = game.humanTeam;
    if (team == null) return; // bots only: no markers
    final s = game.runner.state;
    final v = game.view;
    final r = v.px(T.discRadius);

    final cursor = s.discs[team.cursorId];
    final cx = _x(v, cursor);
    final cy = _y(v, cursor);
    canvas.drawCircle(Offset(cx, cy), r + 5.0, _glow);
    canvas.drawCircle(Offset(cx, cy), r + 5.0, _ring);
    _triangle(canvas, cx, cy - r - 10.0, 9.0, _arrow);

    _drawNext(canvas, v, team, r);
    _drawPower(canvas, cx, cy, r);
  }

  void _drawNext(Canvas canvas, PitchView v, TeamState team, double r) {
    final id = team.nextCandidateId;
    if (id < 0 || id == team.cursorId) return;
    final d = game.runner.state.discs[id];
    _triangle(canvas, _x(v, d), _y(v, d) - r - 8.0, 6.0, _next);
  }

  void _drawPower(Canvas canvas, double cx, double cy, double r) {
    final level = game.input.chargeLevel;
    if (level < 0.0) return;
    const w = 36.0;
    const h = 5.0;
    final top = cy + r + 8.0;
    canvas.drawRect(Rect.fromLTWH(cx - w / 2, top, w, h), _barBack);
    canvas.drawRect(Rect.fromLTWH(cx - w / 2, top, w * level, h), _barFill);
  }

  /// Downward-pointing triangle with its tip at (x, tipY).
  void _triangle(Canvas canvas, double x, double tipY, double size, Paint p) {
    _tri
      ..reset()
      ..moveTo(x - size, tipY - size * 1.2)
      ..lineTo(x + size, tipY - size * 1.2)
      ..lineTo(x, tipY)
      ..close();
    canvas.drawPath(_tri, p);
  }

  double _x(PitchView v, Disc d) =>
      v.sx(d.prev.x + (d.pos.x - d.prev.x) * game.alpha);
  double _y(PitchView v, Disc d) =>
      v.sy(d.prev.y + (d.pos.y - d.prev.y) * game.alpha);
}
