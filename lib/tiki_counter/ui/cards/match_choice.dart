import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// What the start card hands to the screen.
class MatchChoice {
  final GameMode mode;

  /// True = bot vs bot (you just watch).
  final bool watch;
  final Formation homeFormation;
  final TeamPlan homePlan;

  /// Null = pick one at random.
  final TeamPlan? awayPlan;
  final BotLevel botLevel;

  const MatchChoice({
    required this.mode,
    required this.watch,
    required this.homeFormation,
    required this.homePlan,
    required this.awayPlan,
    required this.botLevel,
  });
}
