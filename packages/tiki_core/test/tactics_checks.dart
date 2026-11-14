import 'package:tiki_core/brain/home_spots.dart';
import 'package:tiki_core/brain/patterns/pattern_director.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/preview/plan_preview.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/sim/rules/ball_control.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/position.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

import 'harness.dart';

void tacticsChecks() {
  check('every formation has the right size and a keeper first', () {
    for (final mode in GameMode.values) {
      for (final f in Formations.forMode(mode)) {
        expectEqual(f.spots.length, mode.teamSize, '${f.name} size');
        expectEqual(f.spots.first.position, Position.keeper, '${f.name} GK');
        expectThat(f.kickOffSlot > 0 && f.kickOffSlot < f.spots.length,
            '${f.name} kick-off slot');
      }
    }
  });

  check('high line defends higher up than a low block', () {
    final s = MatchSetup.create(
      mode: GameMode.sevenASide,
      homeFormation: Formations.sevenA231,
      awayFormation: Formations.sevenA231,
    );
    // Away has the ball in the middle.
    s.ball.pos.set(0.0, 0.0);
    BallControl.give(s, s.away.discs[4]);
    final v = TeamView.build(s, Side.home, Phase.defending);
    final cb = Formations.sevenA231.spots[1];
    final high = Vec2();
    final low = Vec2();
    HomeSpots.compute(v, cb, Presets.gegenpress, high);
    HomeSpots.compute(v, cb, Presets.lowBlock, low);
    // Home attacks +x, so "higher up" = bigger x.
    expectThat(high.x > low.x + 4.0,
        'high line x ${high.x.toStringAsFixed(1)} vs low ${low.x.toStringAsFixed(1)}');
  });

  check('overlap pattern starts when a wide carrier has a full back behind', () {
    final s = MatchSetup.create(
      mode: GameMode.sevenASide,
      homeFormation: Formations.sevenA321,
      awayFormation: Formations.sevenA321,
      homePlan: Presets.balanced,
    );
    for (final o in s.away.discs) {
      o.pos.set(-24.0, -15.0); // far away
    }
    s.away.discs[0].pos.set(26.0, 0.0);
    final carrier = s.home.discs[5]; // attacking mid
    final fullBack = s.home.discs[3]; // right full back
    carrier.pos.set(10.0, 12.0);
    fullBack.pos.set(2.0, 14.0);
    s.home.discs[6].pos.set(14.0, -5.0); // striker, not far enough ahead
    s.setPiece = null;
    BallControl.give(s, carrier);

    final v = TeamView.build(s, Side.home, Phase.attacking);
    final director = PatternDirector();
    director.update(v, 0.2);
    expectEqual(director.activeLabel, 'overlap', 'active pattern');
    final c = director.candidateFor(fullBack);
    expectThat(c != null, 'full back has an overlap move');
    expectThat(c!.x > carrier.pos.x, 'overlap run goes past the carrier');
  });

  check('game plan previews work for every style and moment', () {
    for (final mode in GameMode.values) {
      for (final plan in Presets.all) {
        for (final m in PreviewMoment.values) {
          final scene = PlanPreview.build(
            mode: mode,
            formation: Formations.defaultFor(mode),
            plan: plan,
            moment: m,
          );
          expectEqual(scene.discs.length, mode.teamSize * 2, 'disc count');
          for (final d in scene.discs) {
            expectThat(d.x.isFinite && d.tx.isFinite, '${plan.name} ${m.label}');
          }
        }
      }
    }
  });

  check('counter-press sends more players at the ball than dropping off', () {
    int chasers(TeamPlan plan) {
      final scene = PlanPreview.build(
        mode: GameMode.sevenASide,
        formation: Formations.sevenA231,
        plan: plan,
        moment: PreviewMoment.losingPossession,
      );
      var n = 0;
      for (final d in scene.discs) {
        if (!d.ours) continue;
        final before = (d.x - scene.ballX).abs() + (d.y - scene.ballY).abs();
        final after = (d.tx - scene.ballX).abs() + (d.ty - scene.ballY).abs();
        if (after < before - 2.0) n++;
      }
      return n;
    }

    final press = chasers(Presets.gegenpress);
    final drop = chasers(Presets.lowBlock);
    expectThat(press > drop, 'gegenpress $press vs low block $drop');
  });

  check('a plan survives saving and loading', () {
    final p = Presets.gegenpress.copyWith(name: 'Custom', width: 0.3);
    final back = TeamPlan.fromJson(p.toJson());
    expectEqual(back.attack, p.attack, 'attack');
    expectEqual(back.width, 0.3, 'width');
    expectEqual(back.name, 'Custom', 'name');
  });

  check('previews: keepers stay in goal and nobody overlaps', () {
    for (final mode in GameMode.values) {
      for (final m in PreviewMoment.values) {
        final scene = PlanPreview.build(
          mode: mode,
          formation: Formations.defaultFor(mode),
          plan: Presets.counterAttack,
          moment: m,
        );
        final hl = mode.halfLength;
        for (final d in scene.discs) {
          if (!d.keeper) continue;
          final goalX = d.ours ? -hl : hl;
          expectThat((d.x - goalX).abs() < 6.0, '${m.label}: keeper near goal');
          expectThat((d.tx - d.x).abs() < 3.0, '${m.label}: keeper stays home');
        }
        for (var i = 0; i < scene.discs.length; i++) {
          for (var j = i + 1; j < scene.discs.length; j++) {
            final a = scene.discs[i];
            final b = scene.discs[j];
            final dx = a.x - b.x;
            final dy = a.y - b.y;
            expectThat(dx * dx + dy * dy > 2.0 * 2.0, '${m.label}: discs overlap');
          }
        }
      }
    }
  });

  check('with the ball in midfield, someone stays back (rest defence)', () {
    for (final mode in GameMode.values) {
      final scene = PlanPreview.build(
        mode: mode,
        formation: Formations.defaultFor(mode),
        plan: Presets.balanced,
        moment: PreviewMoment.attacking,
      );
      final rest = scene.discs.where((d) => d.ours && d.job == 'rest defence');
      expectThat(rest.isNotEmpty, '${mode.label}: a rest defender');
      for (final d in rest) {
        expectThat(d.tx < scene.ballX, '${mode.label}: rest defence behind the ball');
      }
    }
  });
}
