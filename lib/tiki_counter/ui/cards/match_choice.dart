import 'package:b_ball/tiki_counter/menu/setup/opponent_clubs.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// What the kick-off sheet hands to the screen.
class MatchChoice {
  final GameMode mode;

  /// True = bot vs bot (you just watch).
  final bool watch;
  final Formation homeFormation;
  final TeamPlan homePlan;

  /// Null = pick one at random.
  final TeamPlan? awayPlan;
  final BotLevel botLevel;

  /// Your club and the opponent's, for the score bar and stats.
  final String homeName;
  final String homeCode;
  final OpponentClub opponent;

  const MatchChoice({
    required this.mode,
    required this.watch,
    required this.homeFormation,
    required this.homePlan,
    required this.awayPlan,
    required this.botLevel,
    required this.homeName,
    required this.homeCode,
    required this.opponent,
  });
}
