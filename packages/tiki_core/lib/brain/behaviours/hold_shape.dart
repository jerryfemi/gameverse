import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/tactics/roles.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Go to my home spot. Always available, low score: what a disc does when
/// nothing better is on.
class HoldShape implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.holdShape;

  @override
  Candidate? propose(DiscContext c) {
    final dist = c.d.pos.distTo(c.home);
    var urgency = dist > 8.0 ? 1.0 : 0.65;
    final droppingBack = c.v.phase == Phase.defenceTransition &&
        c.plan.afterLoss == AfterLoss.dropIntoShape;
    if (droppingBack) urgency = 1.4;
    return Candidate(
      kind: kind,
      x: c.home.x,
      y: c.home.y,
      urgency: urgency,
      score: 1.0,
      job: droppingBack
          ? 'drop into shape'
          : (c.v.weHaveBall ? 'shape (attack)' : 'shape (defend)'),
    );
  }
}
