import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/runner/match_runner.dart';

import 'harness.dart';
import 'helpers.dart';

void passingChecks() {
  check('a short pass from the kick-off reaches the teammate', () {
    final runner = MatchRunner.create(
      mode: GameMode.fiveASide,
      home: IdleController(),
      away: IdleController(),
      seed: 3,
    );
    final s = runner.state;
    final taker = s.discs[s.home.cursorId];
    expectEqual(s.ball.ownerId, taker.id, 'kick-off taker has the ball');

    // Midfielder 7 m back and to the side, away from every opponent.
    final mate = s.home.discs[3];
    mate.pos.set(-6.0, 3.0);
    mate.prev.setFrom(mate.pos);
    final i = s.home.intent;
    i.action = ActionKind.pass;
    i.aimX = mate.pos.x - taker.pos.x;
    i.aimY = mate.pos.y - taker.pos.y;
    i.power = 0.3;

    runFor(runner, 3.0);
    expectEqual(s.home.stats.passesTried, 1, 'passes tried');
    expectEqual(s.home.stats.passesCompleted, 1, 'passes completed');
    expectEqual(s.ball.ownerId, mate.id, 'ball owner');
  });

  check('SHOOT counts as a shot, not a pass', () {
    final runner = MatchRunner.create(
      mode: GameMode.fiveASide,
      home: IdleController(),
      away: IdleController(),
      seed: 4,
    );
    final i = runner.state.home.intent;
    i.action = ActionKind.shoot;
    i.aimX = 1.0;
    i.aimY = 0.0;
    i.power = 1.0;
    runFor(runner, 0.1);
    expectEqual(runner.state.home.stats.shots, 1, 'shots');
    expectEqual(runner.state.home.stats.passesTried, 0, 'passes');
  });
}
