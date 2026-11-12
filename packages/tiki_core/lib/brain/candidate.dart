import 'package:tiki_core/tactics/roles.dart';

/// One possible job for a disc: where to go, how fast, and how good an idea
/// it is right now. Behaviours make these; the job picker chooses one.
class Candidate {
  final BehaviourKind? kind;
  final double x;
  final double y;

  /// 0..1 = fraction of run speed, above 1 = sprint.
  final double urgency;

  /// Higher wins (after the role's weight is applied).
  final double score;

  /// Shown in the debug view, e.g. "run in behind".
  final String job;

  /// Once picked, keep doing it for this long unless something much
  /// better comes up (stops discs flickering between ideas).
  final double commit;

  const Candidate({
    required this.kind,
    required this.x,
    required this.y,
    required this.urgency,
    required this.score,
    required this.job,
    this.commit = 0.0,
  });
}
