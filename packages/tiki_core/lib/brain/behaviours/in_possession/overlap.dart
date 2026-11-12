import 'dart:math' as math;

import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Run past the carrier on the outside when the ball is on my flank.
class Overlap implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.overlap;

  @override
  Candidate? propose(DiscContext c) {
    final v = c.v;
    final carrier = v.carrier;
    if (!v.weHaveBall || carrier == null || carrier.id == c.d.id) return null;
    if (c.flank == 0.0 || signD(carrier.pos.y) != c.flank) return null;
    if (carrier.pos.y.abs() < v.halfW * 0.25) return null;
    final carrierX = v.teamX(carrier);
    if (carrierX - v.teamX(c.d) < 2.0) return null; // must come from behind

    final tx = math.min(carrierX + 8.0, v.halfL - 3.0);
    return Candidate(
      kind: kind,
      x: v.worldX(tx),
      y: c.flank * v.halfW * 0.85,
      urgency: 1.4,
      score: 2.0,
      job: 'overlap',
      commit: 2.0,
    );
  }
}
