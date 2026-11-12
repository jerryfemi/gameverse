import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Offer the carrier a pass from an open spot nearby (spots are handed out
/// by `SupportAssigner`, so two discs never go to the same one).
class Support implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.support;

  @override
  Candidate? propose(DiscContext c) {
    if (!c.v.weHaveBall) return null;
    final spot = c.a.support[c.d.id];
    if (spot == null) return null;
    final dx = spot.x - c.d.pos.x;
    final dy = spot.y - c.d.pos.y;
    final far = dx * dx + dy * dy > 16.0;
    return Candidate(
      kind: kind,
      x: spot.x,
      y: spot.y,
      urgency: far ? 1.2 : 0.8,
      score: 2.8,
      job: 'support',
    );
  }
}
