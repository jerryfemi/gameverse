import 'dart:math' as math;

import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/roles.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Sprint into the space behind their back line — timed to the passer.
///
/// A run only goes when the carrier can actually play it: he has the ball
/// under control, is facing forward and isn't being closed down. Until
/// then the runner waits on the last line ("wait to run"), so the run
/// starts as the pass becomes possible instead of arriving too early,
/// stalling, or drifting offside. Once a run starts it is committed to.
class RunInBehind implements Behaviour {
  /// The carrier needs the ball this long before he can pick out a run.
  static const double _settle = 0.2;

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

    if (!_passerReady(v, carrier)) {
      // Hold on the last line, onside, ready to go.
      final waitX = math.min(v.offsideLine - 1.0, v.halfL - 4.0);
      if (myX > waitX + 1.0) return null; // already past it: shape brings him back
      return Candidate(
        kind: kind,
        x: v.worldX(waitX),
        y: wy,
        urgency: 0.9,
        score: score - 0.6,
        job: 'wait to run',
      );
    }
    return Candidate(
      kind: kind,
      x: wx,
      y: wy,
      urgency: 1.5,
      score: score + 0.3,
      job: 'run in behind',
      commit: 1.4,
    );
  }

  /// Ball under control, not facing his own goal, and no one right on him.
  static bool _passerReady(TeamView v, Disc carrier) {
    if (v.s.ball.touchClock < _settle) return false;
    if (carrier.facing.x * v.dir < -0.2) return false;
    return v.space(carrier.pos.x, carrier.pos.y) >= 1.5;
  }
}
