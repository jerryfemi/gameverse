import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';

/// Something that drives a team's controlled disc by filling
/// `team.intent` every tick: a human ([HumanController]), a bot
/// ([BotController]) or, later, the network.
abstract interface class TeamController {
  void fill(MatchState s, TeamState team, double dt);
}
