import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_stats.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Everything about one team during a match.
class TeamState {
  final Side side;

  /// Can change at half-time (same number of spots, so discs keep slots).
  Formation formation;

  /// The game plan the brain reads. Can change at half-time.
  TeamPlan plan;

  final List<Disc> discs;

  /// Club name and 3-letter short form (score bar, stats). Set by the app.
  String name = 'Home';
  String code = 'HOM';

  int score = 0;

  /// The disc the controller steers (the "cursor").
  int cursorId;

  /// Best disc to switch to next (drawn as a small grey triangle).
  int nextCandidateId = -1;

  /// Seconds left before assisted switching may take over again.
  double manualSwitchLock = 0.0;

  /// 2ND MAN held this tick.
  bool secondManHeld = false;

  /// Filled by this team's controller every tick.
  final Intent intent = Intent();

  final TeamStats stats = TeamStats();

  TeamState({
    required this.side,
    required this.formation,
    required this.plan,
    required this.discs,
    required this.cursorId,
  });
}
