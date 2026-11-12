import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/control/bot_attack.dart';
import 'package:tiki_core/control/bot_defence.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/control/bot_memory.dart';
import 'package:tiki_core/control/team_controller.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';

/// Plays the bot team's controlled disc by pressing the same "buttons" a
/// human would. It reads the same [TeamView] as the team brain, so it sees
/// its teammates' runs and passes into them. Choices are split into
/// [BotAttack] (with the ball) and [BotDefence] (without it).
class BotController implements TeamController {
  final Rng rng;
  final BotLevel level;

  final BotMemory _mem = BotMemory();
  double _thinkTimer = 0.0;
  int _holder = -1;

  BotController({required this.rng, this.level = BotLevel.normal});

  @override
  void fill(MatchState s, TeamState team, double dt) {
    final i = team.intent;
    final c = s.discs[team.cursorId];
    if (_mem.shotLock > 0.0) _mem.shotLock -= dt;
    if (s.ball.ownerId == c.id) {
      if (_holder != c.id) {
        _holder = c.id;
        _mem.holdTime = 0.0;
      }
      _mem.holdTime += dt;
    } else {
      _holder = -1;
    }

    _thinkTimer -= dt;
    if (_thinkTimer > 0.0) return;
    _thinkTimer = level.thinkInterval;

    i.secondMan = false;
    if (s.isFrozen) {
      i.moveX = 0.0;
      i.moveY = 0.0;
      i.dash = false;
      return;
    }
    // Phase only matters to the brain; the bot just needs the view.
    final v = TeamView.build(s, team.side, Phase.attacking);
    if (s.ball.ownerId == c.id) {
      BotAttack.decide(v, c, i, level, rng, _mem);
    } else {
      BotDefence.decide(v, c, i, level, rng);
    }
  }
}
