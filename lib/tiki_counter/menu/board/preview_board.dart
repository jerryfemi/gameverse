import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:tiki_core/preview/preview_scene.dart';

/// Plays a [PreviewScene] on a loop:
/// 1. everyone stands still for a moment,
/// 2. your players make their runs (white arrows; red = pressing),
/// 3. the ball plays the pass(es) along the dashed cyan line,
/// 4. hold, then start again.
/// Opponents are faded so your team stands out. With [animate] off the
/// board just shows the runs' end positions (used while dragging the ball).
class PreviewBoard extends StatefulWidget {
  final PreviewScene scene;
  final bool animate;

  const PreviewBoard({super.key, required this.scene, this.animate = true});

  @override
  State<PreviewBoard> createState() => _PreviewBoardState();
}

class _PreviewBoardState extends State<PreviewBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _loop.repeat();
  }

  @override
  void didUpdateWidget(PreviewBoard old) {
    super.didUpdateWidget(old);
    if (!widget.animate) {
      _loop.stop();
      _loop.value = 0.62; // runs done, ball not yet played
    } else if (!identical(old.scene, widget.scene) || !old.animate) {
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
      painter: _PreviewPainter(widget.scene, _loop, showArrows: widget.animate),
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
  final bool showArrows;

  _PreviewPainter(this.scene, this.t, {required this.showArrows})
    : super(repaint: t);

  static final Paint _run = Paint()
    ..color = const Color(0xE6FFFFFF)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  static final Paint _press = Paint()
    ..color = const Color(0xFFEF4444)
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  static final Paint _passPaint = Paint()
    ..color = const Color(0xFF00FFCC)
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;

  // Loop timing (fractions of the loop).
  static const double _runStart = 0.10;
  static const double _runEnd = 0.55;
  static const double _passStart = 0.62;
  static const double _passEnd = 0.88;

  /// 0 → 1: how far the runs are.
  double _runs(double v) {
    if (v < _runStart) return 0.0;
    if (v > _runEnd) return 1.0;
    return Curves.easeInOut.transform((v - _runStart) / (_runEnd - _runStart));
  }

  /// 0 → 1: how far the ball is along its path.
  double _pass(double v) {
    if (v < _passStart) return 0.0;
    if (v > _passEnd) return 1.0;
    return Curves.easeOut.transform((v - _passStart) / (_passEnd - _passStart));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(scene.mode, size);
    BoardPaint.pitch(canvas, g);
    BoardPaint.directionLabels(canvas, g);
    final v = t.value;
    final p = _runs(v);
    final start = g.at(scene.ballX, scene.ballY);
    final r = g.px(1.2);

    if (showArrows) {
      // Runs: from the start spot, stopping a disc-radius short.
      for (final d in scene.discs) {
        if (!d.moves) continue;
        final a = g.at(d.x, d.y);
        final b = g.at(d.tx, d.ty);
        final dir = b - a;
        final len = dir.distance;
        if (len < r * 2) continue;
        final u = dir / len;
        BoardPaint.arrow(canvas, a + u * r, b - u * r, isPressJob(d.job) ? _press : _run);
      }
      // The pass route, leg by leg.
      var from = start;
      for (final stop in scene.ballPath) {
        final to = g.at(stop.x, stop.y);
        final leg = to - from;
        if (leg.distance > r * 2) {
          final u = leg / leg.distance;
          BoardPaint.arrow(canvas, from + u * r * 0.6, to - u * r, _passPaint, dashed: true, head: 7);
        }
        from = to;
      }
    }

    // Opponents (faded) first, then ours on top.
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
          faded: !ours,
          ring: ours && d.number == scene.carrier,
        );
      }
    }
    BoardPaint.ball(canvas, g, _ballAt(g, start, _pass(v)));
  }

  /// The ball's position [k] (0..1) of the way along its whole route.
  Offset _ballAt(BoardGeometry g, Offset start, double k) {
    final path = scene.ballPath;
    if (path.isEmpty || k <= 0.0) return start;
    final legs = path.length;
    final f = k * legs;
    final i = f.floor() < legs ? f.floor() : legs - 1;
    final a = i == 0 ? start : g.at(path[i - 1].x, path[i - 1].y);
    final b = g.at(path[i].x, path[i].y);
    return Offset.lerp(a, b, k >= 1.0 ? 1.0 : f - i)!;
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      !identical(old.scene, scene) || old.showArrows != showArrows;
}
