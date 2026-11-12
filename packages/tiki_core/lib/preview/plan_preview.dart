import 'package:tiki_core/brain/home_spots.dart';
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
        HomeSpots.compute(v, team.formation.spots[d.slot], team.plan, out);
        spots[d] = out;
      }
    }
    spots.forEach((d, p) {
      d.pos.setFrom(p);
      d.prev.setFrom(p);
    });
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
