import 'package:tiki_core/brain/team_brain.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/preview/plan_words.dart';
import 'package:tiki_core/preview/preview_scene.dart';
import 'package:tiki_core/preview/staging.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

export 'package:tiki_core/preview/preview_scene.dart';

/// Stages a moment of a match and runs the **real team brain** once, so the
/// game plan screen shows exactly what the plan makes the discs do. We
/// always attack to the right (+x).
abstract final class PlanPreview {
  /// [ballX]/[ballY] (metres) move the ball somewhere else than the
  /// moment's usual spot — the Lab's scenarios drag it around.
  static PreviewScene build({
    required GameMode mode,
    required Formation formation,
    required TeamPlan plan,
    required PreviewMoment moment,
    Formation? opponent,
    TeamPlan? opponentPlan,
    double? ballX,
    double? ballY,
  }) {
    final s = MatchSetup.create(
      mode: mode,
      homeFormation: formation,
      awayFormation: opponent ?? Formations.defaultFor(mode),
      homePlan: plan,
      awayPlan: opponentPlan ?? Presets.balanced,
    );
    s.setPiece = null;
    final hl = mode.halfLength;
    final hw = mode.halfWidth;

    // Who has the ball now, who had it just before, and where it is.
    final (owner, before, dbx, dby) = switch (moment) {
      PreviewMoment.attacking => (Side.home, Side.home, -0.08 * hl, 0.12 * hw),
      PreviewMoment.defending => (Side.away, Side.away, 0.05 * hl, -0.2 * hw),
      PreviewMoment.gainingPossession =>
        (Side.home, Side.away, 0.08 * hl, 0.22 * hw),
      PreviewMoment.losingPossession =>
        (Side.away, Side.home, 0.3 * hl, -0.15 * hw),
    };
    final bx = ballX ?? dbx;
    final by = ballY ?? dby;

    // 1. Everyone in the shape they had *before* the moment.
    Staging.shape(s, before, bx, by);
    // 2. The owner's nearest disc takes the ball where it is.
    final carrier = Staging.takeBall(s, owner, bx, by);
    s.ball.touchClock = 1.0; // settled on the ball: runs can go

    // 3. Run our brain on that moment.
    final brain = TeamBrain(Side.home);
    s.home.cursorId = owner == Side.home ? carrier.id : -1;
    brain.update(s, 0.0); // possession "just changed": transition phase
    final settled = moment == PreviewMoment.attacking ||
        moment == PreviewMoment.defending;
    if (settled) brain.update(s, 5.0); // long after: settled phase

    final discs = <PreviewDisc>[
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
    final ours = owner == Side.home;
    return PreviewScene(
      mode,
      discs,
      b.x,
      b.y,
      ours ? carrier.number : -1,
      ballPath: ours ? _bestPass(discs, carrier.number, b.x, b.y) : const [],
      caption: PlanWords.caption(moment, b.x, hl, discs),
    );
  }

  /// The pass the ball plays at the end of the loop: to the furthest-
  /// forward teammate who made a run (within 30 m), else the nearest one.
  static List<BallStop> _bestPass(
    List<PreviewDisc> discs,
    int carrier,
    double bx,
    double by,
  ) {
    PreviewDisc? best;
    PreviewDisc? nearest;
    var nearestD = double.infinity;
    for (final d in discs) {
      if (!d.ours || d.keeper || d.number == carrier) continue;
      final dx = d.tx - bx;
      final dy = d.ty - by;
      final dist2 = dx * dx + dy * dy;
      if (dist2 < nearestD) {
        nearestD = dist2;
        nearest = d;
      }
      if (!d.moves || dist2 > 30.0 * 30.0) continue;
      if (best == null || d.tx > best.tx) best = d;
    }
    final to = best ?? nearest;
    return to == null ? const [] : [(x: to.tx, y: to.ty)];
  }
}
