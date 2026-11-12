import 'package:tiki_core/control/bot_controller.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/runner/match_runner.dart';

import 'harness.dart';

/// Plays a whole bot-vs-bot match with no screen.
MatchRunner playMatch(GameMode mode, int seed) {
  final runner = MatchRunner.create(
    mode: mode,
    home: BotController(rng: Rng(seed + 1)),
    away: BotController(rng: Rng(seed + 2)),
    seed: seed,
  );
  final maxSteps = (T.matchSeconds / T.fixedDt).round() + 600;
  for (var i = 0; i < maxSteps; i++) {
    if (runner.state.phase == MatchPhase.halfTime) runner.startSecondHalf();
    if (runner.state.phase == MatchPhase.fullTime) break;
    runner.step(T.fixedDt);
  }
  return runner;
}

void fullMatchChecks() {
  for (final mode in GameMode.values) {
    check('${mode.label}: bots play a full match without breaking', () {
      final s = playMatch(mode, 42).state;
      expectEqual(s.phase, MatchPhase.fullTime, 'phase');
      for (final d in s.discs) {
        expectThat(d.pos.isFinite, 'disc ${d.id} position is a number');
      }
      expectThat(s.ball.pos.isFinite, 'ball position is a number');
      expectThat(s.home.stats.passesTried > 5, 'home passed the ball');
      expectThat(s.away.stats.passesTried > 5, 'away passed the ball');
      final h = s.home.stats;
      final a = s.away.stats;
      print('        score ${s.home.score}-${s.away.score} · shots '
          '${h.shots}-${a.shots} · passes ${h.passesCompleted}/${h.passesTried}'
          ' vs ${a.passesCompleted}/${a.passesTried} · saves ${h.saves}-${a.saves}');
    });
  }

  check('same seed, same match', () {
    final a = playMatch(GameMode.fiveASide, 9).state;
    final b = playMatch(GameMode.fiveASide, 9).state;
    expectEqual(a.home.score, b.home.score, 'home score');
    expectEqual(a.away.score, b.away.score, 'away score');
    expectEqual(a.ball.pos.x, b.ball.pos.x, 'ball x');
  });
}
