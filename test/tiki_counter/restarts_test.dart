import 'package:flutter_test/flutter_test.dart';

import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/set_piece.dart';
import 'package:b_ball/tiki_counter/model/side.dart';
import 'package:b_ball/tiki_counter/sim/match_setup.dart';
import 'package:b_ball/tiki_counter/sim/match_sim.dart';
import 'package:b_ball/tiki_counter/tactics/formations.dart';

MatchState _openPlay(MatchSim sim) {
  final s = sim.s;
  s.setPiece = null;
  s.ball.ownerId = -1;
  return s;
}

MatchSim _sim() {
  final s = MatchSetup.create(
    mode: GameMode.fiveASide,
    homeFormation: Formations.fiveA211,
    awayFormation: Formations.fiveA211,
  );
  return MatchSim(s, seed: 7);
}

void main() {
  test('ball over the touchline = throw-in to the other team', () {
    final sim = _sim();
    final s = _openPlay(sim);
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(4.0, s.mode.halfWidth + 1.0);
    sim.restarts.checkOutOfPlay(s);
    expect(s.pending, isNotNull);
    expect(s.pending!.setPiece.kind, RestartKind.throwIn);
    expect(s.pending!.setPiece.team, Side.away);
  });

  test('ball between the posts = goal and kick-off to the other team', () {
    final sim = _sim();
    final s = _openPlay(sim);
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(s.mode.halfLength + 0.5, 0.2);
    sim.restarts.checkOutOfPlay(s);
    expect(s.home.score, 1);
    expect(s.pending!.setPiece.kind, RestartKind.kickOff);
    expect(s.pending!.setPiece.team, Side.away);
    expect(s.pending!.resetShape, isTrue);
  });

  test('defender puts it behind = corner; attacker = goal kick', () {
    final sim = _sim();
    final s = _openPlay(sim);
    s.ball.lastTouchSide = Side.away; // away defends +x
    s.ball.pos.set(s.mode.halfLength + 0.5, 6.0);
    sim.restarts.checkOutOfPlay(s);
    expect(s.pending!.setPiece.kind, RestartKind.corner);
    expect(s.pending!.setPiece.team, Side.home);

    final sim2 = _sim();
    final s2 = _openPlay(sim2);
    s2.ball.lastTouchSide = Side.home;
    s2.ball.pos.set(s2.mode.halfLength + 0.5, 6.0);
    sim2.restarts.checkOutOfPlay(s2);
    expect(s2.pending!.setPiece.kind, RestartKind.goalKick);
    expect(s2.pending!.setPiece.team, Side.away);
  });

  test('a restart puts the taker on the spot with the ball', () {
    final sim = _sim();
    final s = _openPlay(sim);
    s.ball.lastTouchSide = Side.home;
    s.ball.pos.set(0.0, -s.mode.halfWidth - 1.0);
    sim.restarts.checkOutOfPlay(s);
    for (var i = 0; i < 60; i++) {
      sim.step(1 / 60);
    }
    expect(s.setPiece, isNotNull);
    final taker = s.discs[s.setPiece!.takerId];
    expect(taker.side, Side.away);
    expect(s.ball.ownerId, taker.id);
  });
}
