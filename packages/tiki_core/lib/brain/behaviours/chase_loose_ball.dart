import 'package:tiki_core/brain/ball_prediction.dart';
import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Get to a loose ball first (one disc, picked by the team).
class ChaseLooseBall implements Behaviour {
  final Vec2 _meet = Vec2();

  @override
  BehaviourKind get kind => BehaviourKind.chaseLooseBall;

  @override
  Candidate? propose(DiscContext c) {
    if (c.a.chaser != c.d.id) return null;
    BallPrediction.meetPoint(c.v.s.ball, c.d, _meet);
    return Candidate(
      kind: kind,
      x: _meet.x,
      y: _meet.y,
      urgency: 1.4,
      score: 4.0,
      job: 'chase loose ball',
    );
  }
}
