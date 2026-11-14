import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Take the structure job the team handed out (`StructureAssigner`): stay
/// back as rest defence, or hold the far touchline. Scores just under a
/// support spot, so a timed run or a pattern can still take over.
class KeepStructure implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.keepStructure;

  @override
  Candidate? propose(DiscContext c) {
    if (!c.v.weHaveBall) return null;
    final job = c.a.structure[c.d.id];
    if (job == null) return null;
    final dx = job.x - c.d.pos.x;
    final dy = job.y - c.d.pos.y;
    final far = dx * dx + dy * dy > 16.0;
    return Candidate(
      kind: kind,
      x: job.x,
      y: job.y,
      urgency: far ? 1.1 : 0.8,
      score: 2.7,
      job: job.job,
    );
  }
}
