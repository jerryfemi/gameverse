import 'package:tiki_core/model/game_mode.dart';

/// The four moments the game plan screen can show.
enum PreviewMoment {
  attacking('Attacking'),
  defending('Defending'),
  gainingPossession('Gaining possession'),
  losingPossession('Losing possession');

  final String label;
  const PreviewMoment(this.label);
}

/// One disc in a preview: where it stands and where it goes.
class PreviewDisc {
  final int number;
  final bool ours;
  final bool keeper;
  final double x;
  final double y;
  final double tx;
  final double ty;

  /// What it's doing, in the brain's words ("run in behind", …). Ours only.
  final String job;

  const PreviewDisc({
    required this.number,
    required this.ours,
    required this.keeper,
    required this.x,
    required this.y,
    required this.tx,
    required this.ty,
    required this.job,
  });

  bool get moves => ours && ((tx - x).abs() + (ty - y).abs()) > 1.2;

  /// How far it moves, squared (for sorting).
  double get distanceSquared {
    final dx = tx - x;
    final dy = ty - y;
    return dx * dx + dy * dy;
  }
}

/// A point the ball travels through after the runs are made.
typedef BallStop = ({double x, double y});

/// A staged moment, ready to draw: discs (start → target), the ball, the
/// pass(es) the ball plays at the end of the loop, and a caption.
class PreviewScene {
  final GameMode mode;
  final List<PreviewDisc> discs;
  final double ballX;
  final double ballY;

  /// Number of our disc on the ball, or -1.
  final int carrier;

  /// Where the ball goes once the runs are made (empty = it stays).
  final List<BallStop> ballPath;

  /// One or two plain sentences: what's happening, what to watch.
  final String caption;

  const PreviewScene(
    this.mode,
    this.discs,
    this.ballX,
    this.ballY,
    this.carrier, {
    this.ballPath = const [],
    this.caption = '',
  });
}
