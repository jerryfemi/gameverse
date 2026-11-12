import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Come short toward the carrier to get the ball to feet — most useful when
/// tightly marked (pulls the marker out, opens space behind).
class DropToReceive implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.dropToReceive;

  @override
  Candidate? propose(DiscContext c) {
    final v = c.v;
    final carrier = v.carrier;
    if (!v.weHaveBall || carrier == null || carrier.id == c.d.id) return null;
    final carrierX = v.teamX(carrier);
    if (v.teamX(c.d) < carrierX + 4.0) return null; // already level or deeper

    final wx = v.worldX(carrierX + 6.0);
    final wy = v.clampY(carrier.pos.y + (c.d.pos.y - carrier.pos.y) * 0.4);
    if (!v.laneOpen(carrier.pos.x, carrier.pos.y, wx, wy)) return null;

    final marked = v.space(c.d.pos.x, c.d.pos.y) < 2.5;
    var score = 1.3;
    if (marked) score += 0.8;
    if (c.plan.attack == AttackStyle.possession) score += 0.5;
    return Candidate(
      kind: kind,
      x: wx,
      y: wy,
      urgency: 1.2,
      score: score,
      job: 'drop to receive',
      commit: 1.0,
    );
  }
}
