import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';

/// The keeper: off his line toward the ball, comes for slow loose balls in
/// his box, and steps up a little behind a high line.
abstract final class Keeper {
  static void place(TeamView v, Disc d, double lineHeight) {
    final m = v.s.mode;
    final b = v.s.ball;
    final inBox = v.ballX < -(v.halfL - m.boxDepth) &&
        b.pos.y.abs() < m.boxWidth / 2.0;
    if (b.isLoose && inBox && b.speed < 6.0) {
      d.target.setFrom(b.pos);
      d.urgency = 1.3;
      d.job = 'keeper claims';
      return;
    }
    // Sweeper-keeper: up to 3 m further out behind a high line, when the
    // ball is far away.
    final far = v.ballX > 0.0 ? 1.0 : 0.0;
    final offLine = T.keeperOffLine + 3.0 * lineHeight * far;
    final gx = v.worldX(-(v.halfL - offLine));
    final gy = clampD(b.pos.y * 0.5, -m.goalWidth * 0.45, m.goalWidth * 0.45);
    d.target.set(gx, gy);
    d.urgency = 1.2;
    d.job = 'keeper';
  }
}
