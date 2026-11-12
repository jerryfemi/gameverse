import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/ball.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_state.dart';

/// The two ways the ball changes hands: a disc **takes** it, or a disc
/// **lets it go** (pass, shot, heavy touch, tackle that knocks it loose).
/// Every rule goes through here so the ball's bookkeeping stays consistent.
abstract final class BallControl {
  static void give(MatchState s, Disc d) {
    final b = s.ball;
    b.ownerId = d.id;
    b.lastTouchId = d.id;
    b.lastTouchSide = d.side;
    b.lastKick = null;
    b.vel.setZero();
    b.z = 0.0;
    b.vz = 0.0;
    b.dribbleTouch = false;
    b.intendedReceiverId = -1;
    b.offsideIds.clear();
    b.missedIds.clear();
    b.touchClock = 0.0;
    d.pickupCooldown = 0.0;
    placeAtFeet(b, d);
  }

  /// Ball sits just in front of the carrier.
  static void placeAtFeet(Ball b, Disc d) {
    const r = T.discRadius + T.ballRadius + T.carryGap;
    b.pos.set(d.pos.x + d.facing.x * r, d.pos.y + d.facing.y * r);
  }

  static void release(
    MatchState s,
    Disc from,
    double vx,
    double vy,
    double vz, {
    ActionKind? kick,
    int receiverId = -1,
    double cooldown = T.pickupCooldownAfterPass,
  }) {
    final b = s.ball;
    b.ownerId = -1;
    b.vel.set(vx, vy);
    b.vz = vz;
    b.z = vz > 0.0 ? 0.01 : 0.0;
    b.lastTouchId = from.id;
    b.lastTouchSide = from.side;
    b.lastKick = kick;
    b.intendedReceiverId = receiverId;
    b.dribbleTouch = false;
    b.offsideIds.clear();
    b.missedIds.clear();
    b.touchClock = 0.0;
    from.pickupCooldown = cooldown;
  }
}
