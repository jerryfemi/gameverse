import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/coordination/assignments.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/roles.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// What a behaviour knows about the disc it's deciding for.
class DiscContext {
  final TeamView v;
  final Assignments a;
  final Disc d;
  final FormationSpot spot;
  final RolePreset role;
  final TeamPlan plan;

  /// This disc's home spot right now (world metres), from `HomeSpots`.
  final Vec2 home;

  DiscContext({
    required this.v,
    required this.a,
    required this.d,
    required this.spot,
    required this.role,
    required this.plan,
    required this.home,
  });

  /// +1 if this disc's spot is on the bottom half (+y), −1 if top, 0 central.
  double get flank => spot.ay > 0.15 ? 1.0 : (spot.ay < -0.15 ? -1.0 : 0.0);
}

/// One way a disc can move. Each behaviour is a small file with one job:
/// look at the situation and say "go there, this fast, this good" — or
/// return null when it doesn't make sense right now.
///
/// Behaviours never move a disc. The job picker compares all candidates
/// (score × the role's weight for this behaviour) and the best one wins.
abstract class Behaviour {
  BehaviourKind get kind;

  Candidate? propose(DiscContext c);
}
