import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Hug the touchline to stretch their defence and open the middle.
class HoldWidth implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.holdWidth;

  @override
  Candidate? propose(DiscContext c) {
    if (!c.v.weHaveBall || c.flank == 0.0) return null;
    final y = c.flank * c.v.halfW * (0.72 + 0.2 * c.plan.width);
    var score = 1.2 + c.plan.width * 0.6;
    if (c.plan.attack == AttackStyle.wide) score += 0.6;
    return Candidate(
      kind: kind,
      x: c.home.x,
      y: y,
      urgency: 0.9,
      score: score,
      job: 'hold width',
    );
  }
}
