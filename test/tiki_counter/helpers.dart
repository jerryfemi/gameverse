import 'package:b_ball/tiki_counter/control/team_controller.dart';
import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';
import 'package:b_ball/tiki_counter/runner/match_runner.dart';

/// A controller that leaves the intent alone, so a test can set it by hand.
class IdleController implements TeamController {
  @override
  void fill(MatchState s, TeamState team, double dt) {}
}

/// Runs [runner] for [seconds] of match time.
void runFor(MatchRunner runner, double seconds) {
  final steps = (seconds / T.fixedDt).round();
  for (var i = 0; i < steps; i++) {
    runner.step(T.fixedDt);
  }
}
