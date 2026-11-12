import 'package:tiki_core/brain/team_brain.dart';
import 'package:tiki_core/control/switch_selector.dart';
import 'package:tiki_core/control/team_controller.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/sim/match_sim.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Runs one whole match tick, in this order:
///
/// 1. **Controllers** fill each team's intent (stick/buttons or bot).
/// 2. **Switch selectors** decide which disc each controller steers.
/// 3. **Team brains** (5 Hz) set targets for everyone else.
/// 4. **Sim** applies it all and moves the world one step.
///
/// Pure Dart: the Flame game calls [step] at 60 Hz, and tests call it in a
/// loop to play whole matches with no screen.
class MatchRunner {
  final MatchState state;
  final MatchSim sim;
  final TeamController homeController;
  final TeamController awayController;
  final SwitchSelector _homeSwitch = SwitchSelector();
  final SwitchSelector _awaySwitch = SwitchSelector();
  final TeamBrain homeBrain = TeamBrain(Side.home);
  final TeamBrain awayBrain = TeamBrain(Side.away);

  MatchRunner._(this.state, this.sim, this.homeController, this.awayController);

  factory MatchRunner.create({
    required GameMode mode,
    required TeamController home,
    required TeamController away,
    Formation? homeFormation,
    Formation? awayFormation,
    TeamPlan homePlan = Presets.balanced,
    TeamPlan awayPlan = Presets.balanced,
    int seed = 1,
  }) {
    final state = MatchSetup.create(
      mode: mode,
      homeFormation: homeFormation ?? Formations.defaultFor(mode),
      awayFormation: awayFormation ?? Formations.defaultFor(mode),
      homePlan: homePlan,
      awayPlan: awayPlan,
    );
    final sim = MatchSim(state, seed: seed);
    return MatchRunner._(state, sim, home, away);
  }

  void step(double dt) {
    if (state.isPlaying) {
      homeController.fill(state, state.home, dt);
      awayController.fill(state, state.away, dt);
      _homeSwitch.update(state, state.home, dt);
      _awaySwitch.update(state, state.away, dt);
      homeBrain.update(state, dt);
      awayBrain.update(state, dt);
    }
    sim.step(dt);
  }

  void startSecondHalf() => sim.startSecondHalf();
}
