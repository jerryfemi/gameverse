import 'dart:math' as math;

import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Man marking: stay a step goal-side of my assigned opponent.
class MarkMan implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.markMan;

  @override
  Candidate? propose(DiscContext c) {
    final target = c.a.marks[c.d.id];
    if (target == null) return null;
    final o = c.v.s.discs[target];
    var gx = c.v.worldX(-c.v.halfL) - o.pos.x;
    var gy = -o.pos.y;
    final gl = math.sqrt(gx * gx + gy * gy);
    if (gl > 1e-6) {
      gx /= gl;
      gy /= gl;
    }
    return Candidate(
      kind: kind,
      x: o.pos.x + gx * 1.2,
      y: o.pos.y + gy * 1.2,
      urgency: 1.2,
      score: 2.6,
      job: 'mark #${o.number}',
    );
  }
}
