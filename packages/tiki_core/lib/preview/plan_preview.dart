import 'dart:math' as math;

import 'package:tiki_core/brain/home_spots.dart';
import 'package:tiki_core/brain/keeper.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/brain/team_brain.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/sim/rules/ball_control.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// The four moments the game plan screen can show.
enum PreviewMoment {
  attacking('Attacking'),
  defending('Defending'),
  gainingPossession('Gaining possession'),
  losingPossession('Losing possession');

  final String label;
  const PreviewMoment(this.label);
}

/// One disc in a preview: where it stands and where the brain sends it.
class PreviewDisc {
  final int number;
  final bool ours;
  final bool keeper;
  final double x;
  final double y;
  final double tx;
  final double ty;

  /// The job the brain picked ("press", "run in behind", …). Ours only.
  final String job;

  const PreviewDisc({
    required this.number,
    required this.ours,
    required this.keeper,
    required this.x,
    required this.y,
    required this.tx,
    required this.ty,
    required this.job,
  });

  bool get moves => ours && ((tx - x).abs() + (ty - y).abs()) > 1.2;
}

class PreviewScene {
  final GameMode mode;
  final List<PreviewDisc> discs;
  final double ballX;
  final double ballY;

  /// Number of our disc on the ball, or -1.
  final int carrier;

  const PreviewScene(this.mode, this.discs, this.ballX, this.ballY, this.carrier);
}

/// Stages a moment of a match and runs the **real team brain** once, so the
/// game plan screen shows exactly what the plan makes the discs do. We
/// always attack to the right (+x).
abstract final class PlanPreview {
  static PreviewScene build({
    required GameMode mode,
    required Formation formation,
    required TeamPlan plan,
    required PreviewMoment moment,
    Formation? opponent,
  }) {
    final s = MatchSetup.create(
      mode: mode,
      homeFormation: formation,
      awayFormation: opponent ?? Formations.defaultFor(mode),
      homePlan: plan,
    );
    s.setPiece = null;
    final hl = mode.halfLength;
    final hw = mode.halfWidth;

    // Who has the ball now, who had it just before, and where it is.
    final Side owner;
    final Side before;
    final double bx;
    final double by;
    switch (moment) {
      case PreviewMoment.attacking:
        owner = Side.home;
        before = Side.home;
        bx = -0.08 * hl;
        by = 0.12 * hw;
      case PreviewMoment.defending:
        owner = Side.away;
        before = Side.away;
        bx = 0.05 * hl;
        by = -0.2 * hw;
      case PreviewMoment.gainingPossession:
        owner = Side.home;
        before = Side.away;
        bx = 0.08 * hl;
        by = 0.22 * hw;
      case PreviewMoment.losingPossession:
        owner = Side.away;
        before = Side.home;
        bx = 0.3 * hl;
        by = -0.15 * hw;
    }

    // 1. Everyone in the shape they had *before* the moment.
    _shape(s, before, bx, by);

    // 2. The owner's nearest disc takes the ball where it is.
    final carrier = _nearest(s, owner, bx, by);
    carrier.pos.set(bx - 0.9 * s.dir(owner), by);
    carrier.facing.set(s.dir(owner), 0.0);
    BallControl.give(s, carrier);
    _separate(s, carrier);

    // 3. Run our brain on that moment.
    final brain = TeamBrain(Side.home);
    s.home.cursorId = owner == Side.home ? carrier.id : -1;
    for (final d in s.home.discs) {
      d.target.setFrom(d.pos);
    }
    brain.update(s, 0.0); // possession "just changed": transition phase
    final settled = moment == PreviewMoment.attacking ||
        moment == PreviewMoment.defending;
    if (settled) brain.update(s, 5.0); // long after: settled phase

    final out = <PreviewDisc>[
      for (final d in s.discs)
        PreviewDisc(
          number: d.number,
          ours: d.side == Side.home,
          keeper: d.isKeeper,
          x: d.pos.x,
          y: d.pos.y,
          tx: d.side == Side.home && d.id != s.home.cursorId ? d.target.x : d.pos.x,
          ty: d.side == Side.home && d.id != s.home.cursorId ? d.target.y : d.pos.y,
          job: d.side == Side.home ? d.job : '',
        ),
    ];
    final b = s.ball.pos;
    return PreviewScene(
      mode,
      out,
      b.x,
      b.y,
      owner == Side.home ? carrier.number : -1,
    );
  }

  /// Puts both teams on their home spots for a moment where [had] has the
  /// ball at (bx, by).
  static void _shape(MatchState s, Side had, double bx, double by) {
    final holder = _nearest(s, had, bx, by);
    BallControl.give(s, holder);
    s.ball.pos.set(bx, by);
    final spots = <Disc, Vec2>{};
    for (final team in [s.home, s.away]) {
      final weHave = team.side == had;
      final v = TeamView.build(
        s,
        team.side,
        weHave ? Phase.attacking : Phase.defending,
      );
      for (final d in team.discs) {
        final out = Vec2();
        if (d.isKeeper) {
          // Keepers stand in their goal, never on a formation home spot.
          Keeper.place(v, d, team.plan.lineHeight);
          out.setFrom(d.target);
        } else {
          HomeSpots.compute(v, team.formation.spots[d.slot], team.plan, out);
        }
        spots[d] = out;
      }
    }
    spots.forEach((d, p) {
      d.pos.setFrom(p);
      d.prev.setFrom(p);
    });
  }

  /// Pushes overlapping discs apart (the staged shapes don't run the
  /// physics, so two home spots can land on top of each other). Keepers
  /// and the ball carrier stay put; everyone else gives way.
  static void _separate(MatchState s, Disc carrier) {
    const minGap = 2.7; // a little more than two disc widths
    for (var pass = 0; pass < 10; pass++) {
      var moved = false;
      for (var i = 0; i < s.discs.length; i++) {
        for (var j = i + 1; j < s.discs.length; j++) {
          final a = s.discs[i];
          final b = s.discs[j];
          var dx = b.pos.x - a.pos.x;
          var dy = b.pos.y - a.pos.y;
          var d = math.sqrt(dx * dx + dy * dy);
          if (d >= minGap) continue;
          if (d < 1e-3) {
            dx = 0.0;
            dy = 1.0;
            d = 1.0;
          }
          final push = (minGap - d) / d;
          final aFixed = a.isKeeper || identical(a, carrier);
          final bFixed = b.isKeeper || identical(b, carrier);
          if (aFixed && bFixed) continue;
          final share = aFixed || bFixed ? 1.0 : 0.5;
          if (!aFixed) a.pos.set(a.pos.x - dx * push * share, a.pos.y - dy * push * share);
          if (!bFixed) b.pos.set(b.pos.x + dx * push * share, b.pos.y + dy * push * share);
          moved = true;
        }
      }
      if (!moved) break;
    }
    for (final d in s.discs) {
      d.prev.setFrom(d.pos);
    }
  }

  static Disc _nearest(MatchState s, Side side, double x, double y) {
    Disc? best;
    var bestD = double.infinity;
    for (final d in s.team(side).discs) {
      if (d.isKeeper) continue;
      final dx = d.pos.x - x;
      final dy = d.pos.y - y;
      final d2 = dx * dx + dy * dy;
      if (d2 < bestD) {
        bestD = d2;
        best = d;
      }
    }
    return best!;
  }
}
