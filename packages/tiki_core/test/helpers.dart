import 'package:tiki_core/control/team_controller.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';
import 'package:tiki_core/runner/match_runner.dart';

/// A controller that leaves the intent alone, so a check can set it by hand.
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
