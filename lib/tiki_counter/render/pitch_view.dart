import 'dart:math' as math;

import 'package:b_ball/tiki_counter/model/game_mode.dart';

/// Converts pitch metres to screen pixels.
///
/// The whole board (pitch + a margin for goals and the frame) is fitted
/// inside the screen below the score bar. Only this class knows pixels;
/// the sim only knows metres.
class PitchView {
  /// Metres of board around the pitch lines (goals, run-off, frame).
  static const double marginMetres = 3.0;

  /// Space kept free at the top for the score bar.
  static const double topInset = 52.0;
  static const double pad = 10.0;

  double scale = 10.0;
  double ox = 0.0;
  double oy = 0.0;

  /// Bumps every time the layout changes, so cached drawings can refresh.
  int version = 0;

  void fit(double w, double h, GameMode mode) {
    final boardW = mode.length + marginMetres * 2.0;
    final boardH = mode.width + marginMetres * 2.0;
    final availH = math.max(1.0, h - topInset - pad);
    scale = math.max(
      1.0,
      math.min((w - pad * 2.0) / boardW, availH / boardH),
    );
    ox = w / 2.0;
    oy = topInset + availH / 2.0;
    version++;
  }

  double sx(double x) => ox + x * scale;
  double sy(double y) => oy + y * scale;
  double px(double metres) => metres * scale;
}
