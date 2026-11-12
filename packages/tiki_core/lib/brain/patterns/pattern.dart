import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// "When this happens, these players do these moves together."
///
/// A pattern is data built from three small kinds of function:
/// - a **trigger** that says when it may start,
/// - for each **part**, a **pick** (who plays it) and a **move** (where
///   they go, relative to the ball, carrier or their line — never fixed
///   coordinates, so it works anywhere on the pitch).
///
/// Parts go to whoever fits best right now, not to fixed shirt numbers.
typedef PatternTrigger = bool Function(TeamView v, Disc carrier);
typedef PartPick = Disc? Function(TeamView v, Disc carrier, Set<int> taken);
typedef PartMove = ({double x, double y})? Function(
  TeamView v,
  Disc carrier,
  Disc me,
);

class PatternPart {
  final String name;
  final PartPick pick;
  final PartMove move;

  const PatternPart(this.name, {required this.pick, required this.move});
}

class Pattern {
  final String id;
  final String label;
  final PatternTrigger trigger;
  final List<PatternPart> parts;

  /// Seconds before it ends on its own.
  final double duration;

  /// Seconds before the same pattern may start again.
  final double cooldown;

  /// Attack styles that use it (empty = all).
  final Set<AttackStyle> styles;

  const Pattern({
    required this.id,
    required this.label,
    required this.trigger,
    required this.parts,
    this.duration = 3.5,
    this.cooldown = 7.0,
    this.styles = const {},
  });

  bool allowedFor(TeamPlan plan) => styles.isEmpty || styles.contains(plan.attack);
}

/// Candidates from a running pattern score this high, so the parts follow
/// the script over their normal jobs.
const double patternScore = 5.0;

Candidate patternCandidate(
  Pattern p,
  PatternPart part,
  double x,
  double y,
) => Candidate(
  kind: null,
  x: x,
  y: y,
  urgency: 1.4,
  score: patternScore,
  job: '${p.label}: ${part.name}',
);
