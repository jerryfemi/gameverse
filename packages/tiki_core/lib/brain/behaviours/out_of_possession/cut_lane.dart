import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Stand in the passing lane between the carrier and one of their options.
class CutLane implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.cutLane;

  @override
  Candidate? propose(DiscContext c) {
    final target = c.a.laneCuts[c.d.id];
    final carrier = c.v.carrier;
    if (target == null || carrier == null) return null;
    final o = c.v.s.discs[target];
    return Candidate(
      kind: kind,
      x: carrier.pos.x + (o.pos.x - carrier.pos.x) * 0.55,
      y: carrier.pos.y + (o.pos.y - carrier.pos.y) * 0.55,
      urgency: 1.1,
      score: 3.0,
      job: 'cut lane to #${o.number}',
    );
  }
}
