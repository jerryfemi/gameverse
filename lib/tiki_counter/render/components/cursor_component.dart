import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'package:b_ball/tiki_counter/render/pitch_view.dart';
import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/team_state.dart';

/// Markers for the player's team (eFootball style):
/// - cyan ring + triangle over the disc you control, with a pointer on
///   the ring showing which way that disc faces (where a pass goes when
///   the stick is centred),
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
  final Path _pointer = Path();

  /// Drawn facing angle (radians, screen space), eased toward the real one
  /// so the pointer turns smoothly instead of snapping.
  double _shownAngle = 0.0;
  int _shownFor = -1;

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
    _drawFacing(canvas, v, cursor, cx, cy, r + 5.0);

    _drawNext(canvas, v, team, r);
    _drawPower(canvas, cx, cy, r);
  }

  /// A chevron sitting on the ring, pointing the way the disc faces.
  void _drawFacing(
    Canvas canvas,
    PitchView v,
    Disc d,
    double cx,
    double cy,
    double ringR,
  ) {
    // Facing in screen space (the view may scale or flip the pitch).
    final fx = v.sx(d.pos.x + d.facing.x) - v.sx(d.pos.x);
    final fy = v.sy(d.pos.y + d.facing.y) - v.sy(d.pos.y);
    final target = math.atan2(fy, fx);
    if (_shownFor != d.id) {
      _shownFor = d.id;
      _shownAngle = target; // new cursor: no swing-in
    } else {
      var diff = target - _shownAngle;
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      _shownAngle += diff * 0.35;
    }
    final ux = math.cos(_shownAngle);
    final uy = math.sin(_shownAngle);
    final nx = -uy;
    final ny = ux;
    const size = 7.0;
    final tipX = cx + ux * (ringR + size + 3.0);
    final tipY = cy + uy * (ringR + size + 3.0);
    final baseX = cx + ux * (ringR + 1.0);
    final baseY = cy + uy * (ringR + 1.0);
    _pointer
      ..reset()
      ..moveTo(tipX, tipY)
      ..lineTo(baseX + nx * size, baseY + ny * size)
      ..lineTo(baseX - nx * size, baseY - ny * size)
      ..close();
    canvas.drawPath(_pointer, _arrow);
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
