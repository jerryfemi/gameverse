import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Follow an opponent who is sprinting in behind me, staying goal-side.
class TrackRunner implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.trackRunner;

  @override
  Candidate? propose(DiscContext c) {
    final v = c.v;
    if (v.weHaveBall) return null;
    final myX = v.teamX(c.d);
    Disc? runner;
    var best = 7.0;
    for (final o in v.opp.discs) {
      if (o.isKeeper || o.id == v.carrier?.id) continue;
      final towardOurGoal = -o.vel.x * v.dir;
      if (towardOurGoal < 2.5) continue;
      if (v.teamX(o) > myX + 3.0) continue; // still in front of me
      final d = o.pos.distTo(c.d.pos);
      if (d < best) {
        best = d;
        runner = o;
      }
    }
    if (runner == null) return null;
    return Candidate(
      kind: kind,
      x: runner.pos.x + runner.vel.x * 0.4 - v.dir * 0.8,
      y: runner.pos.y + runner.vel.y * 0.4,
      urgency: 1.4,
      score: 2.7,
      job: 'track #${runner.number}',
      commit: 1.0,
    );
  }
}
