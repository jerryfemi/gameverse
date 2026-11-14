import 'dart:math' as math;

import 'package:tiki_core/control/bot_controller.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/runner/match_runner.dart';
import 'package:tiki_core/tactics/presets.dart';

import 'harness.dart';

/// Plays a whole bot-vs-bot match with no screen.
MatchRunner playMatch(GameMode mode, int seed) {
  final runner = MatchRunner.create(
    mode: mode,
    home: BotController(rng: Rng(seed + 1)),
    away: BotController(rng: Rng(seed + 2)),
    homePlan: Presets.tikiTaka,
    awayPlan: Presets.gegenpress,
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
  const seeds = [42, 7, 99];
  for (final mode in GameMode.values) {
    check('${mode.label}: bots play full matches without breaking', () {
      var goals = 0;
      var maxGoals = 0;
      var shots = 0;
      var tried = 0;
      var done = 0;
      for (final seed in seeds) {
        final s = playMatch(mode, seed).state;
        expectEqual(s.phase, MatchPhase.fullTime, 'phase');
        for (final d in s.discs) {
          expectThat(d.pos.isFinite, 'disc ${d.id} position is a number');
        }
        expectThat(s.ball.pos.isFinite, 'ball position is a number');
        final h = s.home.stats;
        final a = s.away.stats;
        expectThat(h.passesTried > 5, 'home passed the ball');
        expectThat(a.passesTried > 5, 'away passed the ball');
        print('        seed $seed: ${s.home.score}-${s.away.score} · shots '
            '${h.shots}-${a.shots} · passes ${h.passesCompleted}/${h.passesTried}'
            ' vs ${a.passesCompleted}/${a.passesTried} · intercepted '
            '${a.interceptions}-${h.interceptions} · tackles ${h.tacklesWon}-'
            '${a.tacklesWon} · saves ${h.saves}-${a.saves} · pattern runs '
            '${h.patternRuns}-${a.patternRuns}');
        final g = s.home.score + s.away.score;
        goals += g;
        maxGoals = math.max(maxGoals, g);
        shots += h.shots + a.shots;
        tried += h.passesTried + a.passesTried;
        done += h.passesCompleted + a.passesCompleted;
      }
      final n = seeds.length;
      final acc = done / math.max(1, tried);
      // Balance targets: printed, not failed, while we tune.
      print('        average: ${(goals / n).toStringAsFixed(1)} goals · '
          '${(shots / n).toStringAsFixed(1)} shots (aim 6+) · pass accuracy '
          '${(acc * 100).round()}% (aim 75%+)'
          '${acc < 0.75 || shots / n < 6 ? '  <- needs tuning' : ''}');
      expectThat(goals / n <= 8, 'a believable score (average ${goals / n} goals)');
      expectThat(maxGoals <= 11, 'no silly scorelines (one had $maxGoals goals)');
    });
  }

  check('ends swap at half-time', () {
    final s = playMatch(GameMode.fiveASide, 5).state;
    expectThat(!s.homeAttacksRight, 'home attacks left in the second half');
  });

  check('same seed, same match', () {
    final a = playMatch(GameMode.fiveASide, 9).state;
    final b = playMatch(GameMode.fiveASide, 9).state;
    expectEqual(a.home.score, b.home.score, 'home score');
    expectEqual(a.away.score, b.away.score, 'away score');
    expectEqual(a.ball.pos.x, b.ball.pos.x, 'ball x');
  });
}
