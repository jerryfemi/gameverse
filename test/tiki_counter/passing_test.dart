import 'package:flutter_test/flutter_test.dart';

import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/model/intent.dart';
import 'package:b_ball/tiki_counter/runner/match_runner.dart';

import 'helpers.dart';

void main() {
  test('a short pass from the kick-off reaches the teammate', () {
    final runner = MatchRunner.create(
      mode: GameMode.fiveASide,
      home: IdleController(),
      away: IdleController(),
      seed: 3,
    );
    final s = runner.state;
    final taker = s.discs[s.home.cursorId];
    expect(s.ball.ownerId, taker.id);

    // Put the midfielder (slot 3) 7 m back and to the side, away from
    // every opponent, and aim at him.
    final mate = s.home.discs[3];
    mate.pos.set(-6.0, 3.0);
    mate.prev.setFrom(mate.pos);
    final i = s.home.intent;
    i.action = ActionKind.pass;
    i.aimX = mate.pos.x - taker.pos.x;
    i.aimY = mate.pos.y - taker.pos.y;
    i.power = 0.3;

    runFor(runner, 3.0);
    expect(s.home.stats.passesTried, 1);
    expect(s.home.stats.passesCompleted, 1);
    expect(s.ball.ownerId, mate.id);
  });

  test('SHOOT counts as a shot, not a pass', () {
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
    expect(runner.state.home.stats.shots, 1);
    expect(runner.state.home.stats.passesTried, 0);
  });
}
