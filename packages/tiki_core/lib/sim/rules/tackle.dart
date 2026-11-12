import 'dart:math' as math;

import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_event.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/sim/rules/ball_control.dart';

/// TACKLE: close enough to the carrier and you either win the ball, knock
/// it loose, or miss and lose about half a second.
class Tackle {
  final Rng rng;

  Tackle(this.rng);

  void execute(MatchState s, Disc d) {
    if (d.tackleCooldown > 0.0 || d.stunTimer > 0.0) return;
    if (s.setPiece != null) return; // no tackling at restarts
    d.tackleCooldown = T.tackleCooldown;

    final carrier = s.owner;
    if (carrier == null ||
        carrier.side == d.side ||
        carrier.pos.distTo(d.pos) > T.tackleRange) {
      _miss(s, d);
      return;
    }

    final r = rng.next();
    if (r < T.tackleWinChance) {
      s.team(d.side).stats.tacklesWon++;
      carrier.pickupCooldown = 0.4;
      BallControl.give(s, d);
      s.emit(MatchEventKind.tackleWon, d.side, d.id);
    } else if (r < T.tackleLooseChance) {
      final a = rng.range(0.0, math.pi * 2.0);
      BallControl.release(
        s,
        d,
        math.cos(a) * T.tackleLooseSpeed + carrier.vel.x * 0.5,
        math.sin(a) * T.tackleLooseSpeed + carrier.vel.y * 0.5,
        0.0,
        cooldown: 0.1,
      );
      carrier.pickupCooldown = 0.35;
      s.emit(MatchEventKind.tackleLoose, d.side, d.id);
    } else {
      _miss(s, d);
    }
  }

  void _miss(MatchState s, Disc d) {
    d.stunTimer = T.tackleMissStun;
    s.emit(MatchEventKind.tackleMiss, d.side, d.id);
  }
}
