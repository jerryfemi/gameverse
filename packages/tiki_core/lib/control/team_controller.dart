import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';

/// Something that drives a team's controlled disc by filling
/// `team.intent` every tick: a human ([HumanController]), a bot
/// ([BotController]) or, later, the network.
abstract interface class TeamController {
  void fill(MatchState s, TeamState team, double dt);
}
