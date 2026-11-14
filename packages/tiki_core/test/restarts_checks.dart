import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/set_piece.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/runner/match_runner.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/sim/match_sim.dart';
import 'package:tiki_core/tactics/formations.dart';

import 'harness.dart';
import 'helpers.dart';

MatchSim _openPlay() {
  final s = MatchSetup.create(
    mode: GameMode.fiveASide,
    homeFormation: Formations.fiveA211,
    awayFormation: Formations.fiveA211,
  );
  final sim = MatchSim(s, seed: 7);
  s.setPiece = null;
  s.ball.ownerId = -1;
  return sim;
}

void restartsChecks() {
  check('ball over the touchline = throw-in to the other team', () {
    final sim = _openPlay();
    final s = sim.s;
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(4.0, s.mode.halfWidth + 1.0);
    sim.restarts.checkOutOfPlay(s);
    expectEqual(s.pending?.setPiece.kind, RestartKind.throwIn, 'restart');
    expectEqual(s.pending?.setPiece.team, Side.away, 'team');
  });

  check('ball between the posts = goal, kick-off to the other team', () {
    final sim = _openPlay();
    final s = sim.s;
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(s.mode.halfLength + 0.5, 0.2);
    sim.restarts.checkOutOfPlay(s);
    expectEqual(s.home.score, 1, 'home score');
    expectEqual(s.pending?.setPiece.kind, RestartKind.kickOff, 'restart');
    expectEqual(s.pending?.setPiece.team, Side.away, 'team');
  });

  check('defender puts it behind = corner; attacker = goal kick', () {
    final sim = _openPlay();
    final s = sim.s;
    s.ball.lastTouchSide = Side.away; // away defends +x
    s.ball.pos.set(s.mode.halfLength + 0.5, 6.0);
    sim.restarts.checkOutOfPlay(s);
    expectEqual(s.pending?.setPiece.kind, RestartKind.corner, 'restart');

    final sim2 = _openPlay();
    final s2 = sim2.s;
    s2.ball.lastTouchSide = Side.home;
    s2.ball.pos.set(s2.mode.halfLength + 0.5, 6.0);
    sim2.restarts.checkOutOfPlay(s2);
    expectEqual(s2.pending?.setPiece.kind, RestartKind.goalKick, 'restart');
    expectEqual(s2.pending?.setPiece.team, Side.away, 'team');
  });

  check('a restart puts the taker on the spot with the ball', () {
    final sim = _openPlay();
    final s = sim.s;
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(0.0, -s.mode.halfWidth - 1.0);
    sim.restarts.checkOutOfPlay(s);
    for (var i = 0; i < 60; i++) {
      sim.step(1 / 60);
    }
    final sp = s.setPiece;
    expectThat(sp != null, 'set piece in progress');
    final taker = s.discs[sp!.takerId];
    expectEqual(taker.side, Side.away, 'taker team');
    expectEqual(s.ball.ownerId, taker.id, 'taker has the ball');
  });

  check('after a goal everyone jogs back (no teleport), then kick-off', () {
    // A full runner, so the team brains give everyone their targets.
    final runner = MatchRunner.create(
      mode: GameMode.fiveASide,
      home: IdleController(),
      away: IdleController(),
      homeFormation: Formations.fiveA211,
      awayFormation: Formations.fiveA211,
      seed: 7,
    );
    final s = runner.state;
    s.setPiece = null;
    s.ball.ownerId = -1;
    // Home outfielders up in their attacking half, then they score.
    for (final d in s.home.discs) {
      if (!d.isKeeper) d.pos.set(10.0, d.pos.y);
    }
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(s.mode.halfLength + 0.5, 0.2);
    runner.sim.restarts.checkOutOfPlay(s);
    expectThat(s.pending != null, 'goal stops play');

    final mover = s.home.discs[1];
    final spot = Vec2();
    MatchSetup.kickOffSpot(s, mover, kickOffSide: Side.away, out: spot);
    final startGap = mover.pos.distTo(spot);
    var biggestStep = 0.0;
    var t = 0.0;
    while (s.pending != null && t < 10.0) {
      final before = Vec2()..setFrom(mover.pos);
      runner.step(T.fixedDt);
      t += T.fixedDt;
      if (s.pending != null) {
        final step = before.distTo(mover.pos);
        if (step > biggestStep) biggestStep = step;
      }
    }
    final endGap = mover.pos.distTo(spot);
    expectThat(startGap > 3.0, 'setup: player starts ${startGap.toStringAsFixed(1)} m away');
    expectThat(s.pending == null, 'kick-off started (after ${t.toStringAsFixed(1)} s)');
    expectEqual(s.setPiece?.kind, RestartKind.kickOff, 'restart');
    expectThat(biggestStep < 0.5, 'no jumps while walking back (max $biggestStep m)');
    expectThat(endGap < 1.0, 'back on his spot (${endGap.toStringAsFixed(1)} m off)');
  });

  check('the other team can move while a restart is taken', () {
    final sim = _openPlay();
    final s = sim.s;
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(0.0, -s.mode.halfWidth - 1.0);
    sim.restarts.checkOutOfPlay(s);
    for (var i = 0; i < 60; i++) {
      sim.step(1 / 60); // restart begins: away throws in
    }
    expectThat(s.setPiece != null, 'throw-in in progress');
    // Ask a home player to walk 6 m; the rules must let him.
    final d = s.home.discs[2];
    final from = Vec2()..setFrom(d.pos);
    d.target.set(d.pos.x - 6.0, d.pos.y);
    d.urgency = 1.0;
    for (var i = 0; i < 60; i++) {
      d.target.set(from.x - 6.0, from.y);
      sim.step(1 / 60);
    }
    expectThat(from.distTo(d.pos) > 2.0, 'moved ${from.distTo(d.pos).toStringAsFixed(1)} m');
  });
}
