import 'package:tiki_core/brain/ball_prediction.dart';
import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/behaviours/chase_loose_ball.dart';
import 'package:tiki_core/brain/behaviours/hold_shape.dart';
import 'package:tiki_core/brain/behaviours/in_possession/cut_inside.dart';
import 'package:tiki_core/brain/behaviours/in_possession/drop_to_receive.dart';
import 'package:tiki_core/brain/behaviours/in_possession/hold_width.dart';
import 'package:tiki_core/brain/behaviours/in_possession/keep_structure.dart';
import 'package:tiki_core/brain/behaviours/in_possession/overlap.dart';
import 'package:tiki_core/brain/behaviours/in_possession/run_in_behind.dart';
import 'package:tiki_core/brain/behaviours/in_possession/support.dart';
import 'package:tiki_core/brain/behaviours/out_of_possession/cover.dart';
import 'package:tiki_core/brain/behaviours/out_of_possession/cut_lane.dart';
import 'package:tiki_core/brain/behaviours/out_of_possession/mark_man.dart';
import 'package:tiki_core/brain/behaviours/out_of_possession/press.dart';
import 'package:tiki_core/brain/behaviours/out_of_possession/track_runner.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/coordination/assignments.dart';
import 'package:tiki_core/brain/coordination/defence_assigner.dart';
import 'package:tiki_core/brain/coordination/structure_assigner.dart';
import 'package:tiki_core/brain/coordination/support_assigner.dart';
import 'package:tiki_core/brain/home_spots.dart';
import 'package:tiki_core/brain/job_picker.dart';
import 'package:tiki_core/brain/keeper.dart';
import 'package:tiki_core/brain/patterns/pattern_director.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/sim/rules/set_piece_zone.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Decides a target for every disc the controller isn't steering, five
/// times a second. One tick, in order:
///
/// 1. **Perceive** — build a [TeamView] (ball, lines, space) once.
/// 2. **Phase** — attacking / just won it / defending / just lost it.
/// 3. **Coordinate** — team-level jobs: structure with the ball (rest
///    defence, far-side width), support spots, pressers, lane cutters,
///    markers, cover, loose-ball chaser.
/// 4. **Patterns** — start or continue a combination.
/// 5. **Each disc** — home spot, then every behaviour its role allows
///    proposes a candidate; the job picker takes the best.
///
/// While a restart is being set up, every target is kept where the rules
/// allow (`SetPieceZone`); after a goal everyone jogs back to kick-off
/// spots instead of thinking.
class TeamBrain {
  final Side side;
  final PhaseTracker _phase;
  final PatternDirector patterns = PatternDirector();
  double _timer = 0.0;
  Phase phase = Phase.defending;

  final Vec2 _home = Vec2();
  final List<Candidate> _candidates = [];
  final List<Behaviour> _behaviours = [
    HoldShape(),
    KeepStructure(),
    Support(),
    RunInBehind(),
    HoldWidth(),
    DropToReceive(),
    CutInside(),
    Overlap(),
    Press(),
    CutLane(),
    MarkMan(),
    Cover(),
    TrackRunner(),
    ChaseLooseBall(),
  ];

  TeamBrain(this.side) : _phase = PhaseTracker(side);

  void update(MatchState s, double dt) {
    phase = _phase.update(s, dt);
    _timer -= dt;
    if (_timer > 0.0) return;
    _timer = T.brainInterval;
    _think(s);
  }

  void _think(MatchState s) {
    final team = s.team(side);
    final pending = s.pending;
    if (pending != null && pending.resetShape) {
      _walkBack(s, pending.setPiece.team);
      return;
    }
    final plan = team.plan;
    final v = TeamView.build(s, side, phase);
    final a = Assignments();
    StructureAssigner.assign(v, plan, a);
    SupportAssigner.assign(v, plan, a);
    DefenceAssigner.assign(v, plan, a);
    patterns.update(v, T.brainInterval);

    final b = s.ball;
    final receiving = b.isLoose && b.lastTouchSide == side;
    for (final d in team.discs) {
      // While play is stopped nobody is steered, so the brain moves the
      // controlled disc too.
      if (d.id == team.cursorId && !s.isFrozen) {
        d.job = 'controlled';
        continue;
      }
      if (d.isKeeper) {
        Keeper.place(v, d, plan.lineHeight);
        continue;
      }
      if (receiving && d.id == b.intendedReceiverId) {
        BallPrediction.meetPoint(b, d, d.target);
        d.urgency = 1.4;
        d.job = 'receive pass';
        continue;
      }
      final spot = team.formation.spots[d.slot];
      final role = Roles.forPosition(spot.position);
      HomeSpots.compute(v, spot, plan, _home);
      final ctx = DiscContext(
        v: v,
        a: a,
        d: d,
        spot: spot,
        role: role,
        plan: plan,
        home: _home,
      );
      _candidates.clear();
      for (final behaviour in _behaviours) {
        if (role.weight(behaviour.kind) <= 0.0) continue;
        final c = behaviour.propose(ctx);
        if (c != null) _candidates.add(c);
      }
      final pc = patterns.candidateFor(d);
      if (pc != null) _candidates.add(pc);
      JobPicker.choose(d, _candidates, role, T.brainInterval);
      SetPieceZone.keepOut(s, d, d.target);
    }
  }

  /// After a goal: everyone (keeper and controlled disc included) jogs to
  /// their kick-off spot.
  void _walkBack(MatchState s, Side kickOffSide) {
    for (final d in s.team(side).discs) {
      MatchSetup.kickOffSpot(s, d, kickOffSide: kickOffSide, out: d.target);
      d.urgency = T.walkBackUrgency;
      d.job = 'back to position';
    }
  }
}
