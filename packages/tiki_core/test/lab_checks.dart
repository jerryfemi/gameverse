import 'package:tiki_core/control/bot_controller.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/drills/drill.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/preview/pattern_preview.dart';
import 'package:tiki_core/preview/plan_preview.dart';
import 'package:tiki_core/runner/match_runner.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';

import 'harness.dart';

void labChecks() {
  check('every pattern demo finds its players and a pass to play', () {
    for (final mode in GameMode.values) {
      for (final p in PatternPreview.all) {
        final scene = PatternPreview.build(mode: mode, pattern: p);
        final movers = scene.discs.where((d) => d.moves).length;
        expectThat(movers >= 1, '${mode.label} ${p.label}: someone runs');
        expectThat(scene.ballPath.isNotEmpty, '${mode.label} ${p.label}: a pass');
        expectThat(PatternPreview.info(p).blurb.isNotEmpty, '${p.label}: text');
      }
    }
  });

  check('game plan boards have a caption and a pass when you have it', () {
    final scene = PlanPreview.build(
      mode: GameMode.sevenASide,
      formation: Formations.sevenA231,
      plan: Presets.tikiTaka,
      moment: PreviewMoment.attacking,
    );
    expectThat(scene.caption.startsWith('You have the ball'), scene.caption);
    expectThat(scene.ballPath.isNotEmpty, 'the ball plays a pass');
  });

  check('a scenario can put the ball anywhere', () {
    final scene = PlanPreview.build(
      mode: GameMode.fiveASide,
      formation: Formations.defaultFor(GameMode.fiveASide),
      plan: Presets.balanced,
      moment: PreviewMoment.defending,
      ballX: -12.0,
      ballY: 6.0,
    );
    expectThat((scene.ballX + 12.0).abs() < 2.5, 'ball x ${scene.ballX}');
  });

  check('every drill ends (pass or fail) within its time', () {
    for (final drill in Drills.all) {
      final runner = MatchRunner.create(
        mode: drill.mode,
        home: BotController(rng: Rng(11)),
        away: BotController(rng: Rng(12)),
        awayPlan: drill.opponentPlan,
        seed: 13,
      );
      final start = Drills.start(runner.state, drill);
      var t = 0.0;
      var outcome = DrillOutcome.running;
      while (outcome == DrillOutcome.running && t < drill.timeLimit + 1.0) {
        runner.step(T.fixedDt);
        t += T.fixedDt;
        outcome = drill.judge(runner.state, t, start);
      }
      expectThat(outcome != DrillOutcome.running, '${drill.title} ended');
    }
  });
}
