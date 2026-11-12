import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:tiki_core/preview/plan_preview.dart';

/// Plays a [PreviewScene] on a loop: discs stand still, then move to where
/// the team brain sends them, then hold. Arrows show each run (white), each
/// press (red) and the pass options from the ball (dashed cyan).
class PreviewBoard extends StatefulWidget {
  final PreviewScene scene;

  const PreviewBoard({super.key, required this.scene});

  @override
  State<PreviewBoard> createState() => _PreviewBoardState();
}

class _PreviewBoardState extends State<PreviewBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void didUpdateWidget(PreviewBoard old) {
    super.didUpdateWidget(old);
    if (!identical(old.scene, widget.scene)) {
      _loop
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PreviewPainter(widget.scene, _loop),
      child: const SizedBox.expand(),
    );
  }
}

/// Words in a job that mean "going at the ball".
bool isPressJob(String job) =>
    job.contains('press') || job.contains('2nd') || job.contains('chase');

class _PreviewPainter extends CustomPainter {
  final PreviewScene scene;
  final Animation<double> t;

  _PreviewPainter(this.scene, this.t) : super(repaint: t);

  /// Worked out once per scene, not every frame.
  late final List<PreviewDisc> _options = _passOptions();

  static final Paint _run = Paint()
    ..color = const Color(0xE6FFFFFF)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  static final Paint _press = Paint()
    ..color = const Color(0xFFEF4444)
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  static final Paint _pass = Paint()
    ..color = const Color(0xFF00FFCC)
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  /// 0 → 1 movement inside one loop: hold, move, hold.
  double _progress() {
    final v = t.value;
    if (v < 0.15) return 0.0;
    if (v > 0.7) return 1.0;
    return Curves.easeInOut.transform((v - 0.15) / 0.55);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(scene.mode, size);
    BoardPaint.pitch(canvas, g);
    final p = _progress();
    final ball = g.at(scene.ballX, scene.ballY);

    // Arrows under the discs. Each starts at the disc's start spot and
    // stops a disc-radius short of its target.
    final r = g.px(1.2);
    for (final d in scene.discs) {
      if (!d.moves) continue;
      final a = g.at(d.x, d.y);
      final b = g.at(d.tx, d.ty);
      final dir = b - a;
      final len = dir.distance;
      if (len < r * 2) continue;
      final u = dir / len;
      BoardPaint.arrow(
        canvas,
        a + u * r,
        b - u * r,
        isPressJob(d.job) ? _press : _run,
      );
    }
    if (scene.carrier >= 0) {
      for (final d in _options) {
        final b = g.at(d.tx, d.ty);
        final u = (b - ball) / (b - ball).distance;
        BoardPaint.arrow(canvas, ball + u * r, b - u * r, _pass, dashed: true, head: 7);
      }
    }

    // Opponents first, then ours on top.
    for (final ours in [false, true]) {
      for (final d in scene.discs) {
        if (d.ours != ours) continue;
        final x = lerpDouble(d.x, d.tx, p)!;
        final y = lerpDouble(d.y, d.ty, p)!;
        BoardPaint.disc(
          canvas,
          g,
          g.at(x, y),
          d.number,
          ours: ours,
          ring: ours && d.number == scene.carrier,
        );
      }
    }
    BoardPaint.ball(canvas, g, ball);
  }

  /// Up to three teammates the ball holder could pass to: the ones whose
  /// targets are nearest the ball, excluding the keeper.
  List<PreviewDisc> _passOptions() {
    final mates = [
      for (final d in scene.discs)
        if (d.ours && !d.keeper && d.number != scene.carrier) d,
    ];
    double dist(PreviewDisc d) {
      final dx = d.tx - scene.ballX;
      final dy = d.ty - scene.ballY;
      return dx * dx + dy * dy;
    }

    mates.sort((a, b) => dist(a).compareTo(dist(b)));
    return mates.take(3).toList();
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => !identical(old.scene, scene);
}
