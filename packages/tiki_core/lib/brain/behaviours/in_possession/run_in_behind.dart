import 'dart:math' as math;

import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/tactics/roles.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Sprint into the space behind their back line, starting onside.
/// The bot (and a human with THROUGH) can then play the ball into the run.
class RunInBehind implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.runInBehind;

  @override
  Candidate? propose(DiscContext c) {
    final v = c.v;
    final carrier = v.carrier;
    if (!v.weHaveBall || carrier == null || carrier.id == c.d.id) return null;
    final myX = v.teamX(c.d);
    // Already beyond the line: an offside disc gets back via its shape.
    if (v.offsideOn && myX > v.offsideLine + 0.3) return null;
    if (myX < v.ballX - 8.0) return null; // too deep to make the run

    final runX = math.min(v.offsideLine + 6.0, v.halfL - 3.0);
    final wx = v.worldX(runX);
    final wy = v.clampY(c.d.pos.y * 0.6 + c.flank * 2.0, 2.0);
    final space = v.space(wx, wy);
    if (space < 2.0) return null;

    var score = 1.4 + math.min(space, 8.0) * 0.12;
    if (c.plan.attack == AttackStyle.direct) score += 0.6;
    if (c.plan.attack == AttackStyle.possession) score -= 0.5;
    if (v.phase == Phase.attackTransition &&
        c.plan.afterWin == AfterWin.counter) {
      score += 1.2;
    }
    // A carrier under pressure can't pick out the run.
    if (v.space(carrier.pos.x, carrier.pos.y) < 1.5) score -= 0.6;

    return Candidate(
      kind: kind,
      x: wx,
      y: wy,
      urgency: 1.4,
      score: score,
      job: 'run in behind',
      commit: 1.4,
    );
  }
}
