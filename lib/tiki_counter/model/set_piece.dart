import 'package:b_ball/tiki_counter/core/vec2.dart';
import 'package:b_ball/tiki_counter/model/side.dart';

enum RestartKind { kickOff, throwIn, goalKick, corner, freeKick }

/// A restart in progress: the taker stands on the spot until it plays the
/// ball; opponents keep their distance.
class SetPiece {
  final RestartKind kind;
  final Side team;
  final Vec2 spot;
  int takerId = -1;

  /// Where the taker stands and faces; held there until the ball is played.
  final Vec2 takerPos = Vec2();
  final Vec2 takerFacing = Vec2(1.0, 0.0);

  /// Seconds since the taker got the ball.
  double timer = 0.0;

  SetPiece({required this.kind, required this.team, required this.spot});

  /// Throw-ins, goal kicks and corners can't be offside.
  bool get offsideExempt =>
      kind == RestartKind.throwIn ||
      kind == RestartKind.goalKick ||
      kind == RestartKind.corner;
}

/// A restart waiting to begin (the ball just went out, or a goal was scored).
class PendingRestart {
  final SetPiece setPiece;
  double delay;

  /// True after goals and at kick-offs: everyone goes back to formation.
  final bool resetShape;

  PendingRestart(this.setPiece, this.delay, {this.resetShape = false});
}
