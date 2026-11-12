import 'package:flutter_test/flutter_test.dart';

import 'package:b_ball/tiki_counter/control/bot_controller.dart';
import 'package:b_ball/tiki_counter/core/rng.dart';
import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/runner/match_runner.dart';

/// Plays a whole bot-vs-bot match with no screen.
MatchRunner _playMatch(GameMode mode, int seed) {
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

void main() {
  for (final mode in GameMode.values) {
    test('${mode.label}: bots play a full match without breaking', () {
      final runner = _playMatch(mode, 42);
      final s = runner.state;
      expect(s.phase, MatchPhase.fullTime);
      for (final d in s.discs) {
        expect(d.pos.isFinite, isTrue, reason: 'disc ${d.id} position');
      }
      expect(s.ball.pos.isFinite, isTrue);
      expect(s.home.stats.passesTried, greaterThan(5));
      expect(s.away.stats.passesTried, greaterThan(5));
    });
  }

  test('same seed, same match', () {
    final a = _playMatch(GameMode.fiveASide, 9).state;
    final b = _playMatch(GameMode.fiveASide, 9).state;
    expect(a.home.score, b.home.score);
    expect(a.away.score, b.away.score);
    expect(a.ball.pos.x, b.ball.pos.x);
    expect(a.home.stats.passesTried, b.home.stats.passesTried);
  });
}
