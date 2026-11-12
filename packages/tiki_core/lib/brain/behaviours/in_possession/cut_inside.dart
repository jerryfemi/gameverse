import 'dart:math' as math;

import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';

/// A wide attacker moves into the half-space toward goal once the ball is
/// in the attacking half.
class CutInside implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.cutInside;

  @override
  Candidate? propose(DiscContext c) {
    final v = c.v;
    if (!v.weHaveBall || c.flank == 0.0) return null;
    if (v.ballX < -0.1 * v.halfL) return null;
    if (v.carrier?.id == c.d.id) return null;

    var tx = math.min(v.halfL - 4.0, math.max(v.ballX + 5.0, v.teamX(c.d)));
    if (v.offsideOn && tx > v.offsideLine - 0.5) tx = v.offsideLine - 0.5;
    final score = 1.3 + (v.ballX > 0.2 * v.halfL ? 0.5 : 0.0);
    return Candidate(
      kind: kind,
      x: v.worldX(tx),
      y: c.flank * v.halfW * 0.3,
      urgency: 1.1,
      score: score,
      job: 'cut inside',
      commit: 1.0,
    );
  }
}
