import 'dart:math' as math;

import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/tactics/roles.dart';

/// The last man: sits behind the line in the middle to sweep up balls
/// played in behind a high line.
class Cover implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.cover;

  @override
  Candidate? propose(DiscContext c) {
    if (c.a.cover != c.d.id) return null;
    final v = c.v;
    final homeX = c.home.x * v.dir; // home spot in team x
    final tx = math.min(homeX - 2.0, v.ballX - 8.0);
    return Candidate(
      kind: kind,
      x: v.worldX(math.max(tx, -v.halfL + 3.0)),
      y: v.ballY * 0.4,
      urgency: 1.0,
      score: 2.2,
      job: 'cover',
    );
  }
}
