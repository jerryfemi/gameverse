import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/set_piece.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/sim/command_applier.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/sim/physics/ball_physics.dart';
import 'package:tiki_core/sim/physics/collisions.dart';
import 'package:tiki_core/sim/physics/disc_motion.dart';
import 'package:tiki_core/sim/rules/clock.dart';
import 'package:tiki_core/sim/rules/passing.dart';
import 'package:tiki_core/sim/rules/possession.dart';
import 'package:tiki_core/sim/rules/restarts.dart';
import 'package:tiki_core/sim/rules/tackle.dart';

/// The rules of the world, one fixed 1/60 s step at a time.
///
/// Read [step] top to bottom: it *is* the order things happen in a tick.
/// Controllers and the team brain have already written intents/targets
/// before this runs (see `runner/match_runner.dart`).
class MatchSim {
  final MatchState s;
  final Rng rng;

  final DiscMotion _motion = DiscMotion();
  final Collisions _collisions = Collisions();
  final BallPhysics _ballPhysics = BallPhysics();
  final Clock _clock = Clock();
  late final Passing passing;
  late final Tackle tackle;
  late final Restarts restarts;
  late final Possession possession;
  late final CommandApplier _applier;

  MatchSim(this.s, {int seed = 1}) : rng = Rng(seed) {
    passing = Passing(rng);
    tackle = Tackle(rng);
    restarts = Restarts(passing);
    possession = Possession(rng, restarts);
    _applier = CommandApplier(passing, tackle);
    _kickOff(Side.home);
  }

  void step(double dt) {
    s.events.clear();
    if (!s.isPlaying) return;
    _savePrev();

    _clock.tick(s, dt);
    if (!s.isPlaying) return; // the half just ended

    if (s.isFrozen) {
      restarts.tickPending(s, dt);
      return;
    }

    _applier.apply(s, s.home); //   1. buttons/bot → controlled discs
    _applier.apply(s, s.away);
    _motion.step(s, dt); //          2. every disc moves
    _collisions.resolve(s); //       3. no overlapping
    possession.carry(s, dt); //      4. ball at the carrier's feet
    restarts.holdSetPiece(s, dt); // 5. taker stays on the spot
    _ballPhysics.step(s.ball, dt); // 6. loose ball rolls / flies
    possession.checkPickups(s); //   7. someone takes a loose ball?
    restarts.checkOutOfPlay(s); //   8. out, goal?
    _countPossession(dt);
  }

  /// Called by the UI when the player leaves the half-time card.
  void startSecondHalf() {
    if (s.phase != MatchPhase.halfTime) return;
    s.phase = MatchPhase.secondHalf;
    _kickOff(Side.away);
  }

  void _kickOff(Side side) {
    s.pending = null;
    MatchSetup.resetShape(s, kickOffSide: side);
    restarts.start(
      s,
      SetPiece(kind: RestartKind.kickOff, team: side, spot: Vec2()),
    );
  }

  void _savePrev() {
    for (final d in s.discs) {
      d.prev.setFrom(d.pos);
    }
    s.ball.prev.setFrom(s.ball.pos);
    s.ball.prevZ = s.ball.z;
  }

  void _countPossession(double dt) {
    final side = s.possessionSide;
    if (side != null) s.team(side).stats.possessionSeconds += dt;
  }
}
