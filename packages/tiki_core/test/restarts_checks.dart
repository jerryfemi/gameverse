import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/set_piece.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/sim/match_sim.dart';
import 'package:tiki_core/tactics/formations.dart';

import 'harness.dart';

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
}
