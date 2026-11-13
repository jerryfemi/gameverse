import 'package:tiki_core/control/team_controller.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';
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
    if (s.home.stats.passesCompleted != 1) {
      // Tell us what happened instead of just "got 0".
      final b = s.ball;
      print('        ball at (${b.pos.x.toStringAsFixed(1)}, '
          '${b.pos.y.toStringAsFixed(1)}) speed ${b.speed.toStringAsFixed(1)} '
          'owner ${b.ownerId} lastTouch ${b.lastTouchId} '
          'missed ${b.missedIds} restart ${s.pending?.setPiece.kind}');
      print('        taker ${taker.id} at (${taker.pos.x.toStringAsFixed(1)}, '
          '${taker.pos.y.toStringAsFixed(1)}) · mate ${mate.id} at '
          '(${mate.pos.x.toStringAsFixed(1)}, ${mate.pos.y.toStringAsFixed(1)}) '
          'job "${mate.job}" · cursor ${s.home.cursorId}');
    }
    expectEqual(s.home.stats.passesTried, 1, 'passes tried');
    expectEqual(s.home.stats.passesCompleted, 1, 'passes completed');
    expectEqual(s.ball.ownerId, mate.id, 'ball owner');
  });

  check('a pass reaches a receiver even if you keep steering him away', () {
    final pusher = _StickAway();
    final runner = MatchRunner.create(
      mode: GameMode.fiveASide,
      home: pusher,
      away: IdleController(),
      seed: 5,
    );
    final s = runner.state;
    final taker = s.discs[s.home.cursorId];
    final mate = s.home.discs[3];
    mate.pos.set(-7.0, 2.0);
    mate.prev.setFrom(mate.pos);
    mate.vel.set(0.0, 3.0); // already running sideways
    pusher.aimAt(mate.pos.x - taker.pos.x, mate.pos.y - taker.pos.y);

    runFor(runner, 3.5);
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

/// Passes once, then holds the stick hard "down" the whole time — like a
/// thumb still on the stick after the pass.
class _StickAway implements TeamController {
  double _ax = 1.0;
  double _ay = 0.0;
  bool _passed = false;

  void aimAt(double x, double y) {
    _ax = x;
    _ay = y;
  }

  @override
  void fill(MatchState s, TeamState team, double dt) {
    final i = team.intent;
    i.moveX = 0.0;
    i.moveY = 1.0;
    if (!_passed) {
      _passed = true;
      i.action = ActionKind.pass;
      i.aimX = _ax;
      i.aimY = _ay;
      i.power = 0.3;
    }
  }
}
