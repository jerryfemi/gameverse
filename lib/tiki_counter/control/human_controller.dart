import 'package:b_ball/tiki_counter/control/human_input.dart';
import 'package:b_ball/tiki_counter/control/team_controller.dart';
import 'package:b_ball/tiki_counter/model/intent.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';

/// Copies the touch controls into the team's intent.
class HumanController implements TeamController {
  final HumanInput input;

  HumanController(this.input);

  @override
  void fill(MatchState s, TeamState team, double dt) {
    final i = team.intent;
    i.moveX = input.stickX;
    i.moveY = input.stickY;
    i.dash = input.dashHeld;
    i.secondMan = input.secondManHeld;

    final action = input.takeAction();
    if (action != ActionKind.none) {
      i.action = action;
      i.aimX = input.queuedAimX;
      i.aimY = input.queuedAimY;
      i.power = input.queuedPower;
    }
    final sw = input.takeSwitch();
    if (sw != SwitchKind.none) i.switchTo = sw;
  }
}
