import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/side.dart';

/// The ball pellet. Plain state: physics and rules change it.
class Ball {
  final Vec2 pos = Vec2();
  final Vec2 vel = Vec2();
  final Vec2 prev = Vec2();

  /// Height above the pitch (lobs, shots).
  double z = 0.0;
  double vz = 0.0;
  double prevZ = 0.0;

  /// Disc id holding the ball, or −1 when it's loose / travelling.
  int ownerId = -1;

  /// Last disc to touch it (for throw-ins, corners, stats).
  int lastTouchId = -1;
  Side? lastTouchSide;

  /// What the last kick was (null for loose balls after tackles).
  ActionKind? lastKick;

  /// True after a heavy touch while dashing: the carrier gets it back
  /// unless someone else gets there first.
  bool dribbleTouch = false;

  /// Who the last pass was meant for (−1 = into space / nobody).
  int intendedReceiverId = -1;

  /// Attackers that were offside when the last pass was played.
  final Set<int> offsideIds = <int>{};

  /// Discs that already tried and failed to stop this kick.
  final Set<int> missedIds = <int>{};

  /// Time while carrying, used for heavy-touch rhythm.
  double touchClock = 0.0;

  bool get isLoose => ownerId < 0;

  double get speed => vel.length;
}
