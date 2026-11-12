import 'dart:math' as math;

import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/sim/rules/receivers.dart';

/// "Passes can miss, but only occasionally."
///
/// Every kick gets a small random angle. It grows with the kind of kick
/// (a lob is harder than a pass), with an opponent close by, and on rare
/// bad touches.
abstract final class AimError {
  /// Random angle in radians to rotate the kick by.
  static double angle(MatchState s, Disc kicker, ActionKind kind, Rng rng) {
    var base = switch (kind) {
      ActionKind.through => T.errThroughDeg,
      ActionKind.lob => T.errLobDeg,
      ActionKind.shoot => T.errShootDeg,
      _ => T.errPassDeg,
    };
    final near = Receivers.nearestOpponentDist(
      s.team(kicker.side.other),
      kicker.pos,
    );
    if (near < T.pressureRadius) {
      base *= 1.0 + (T.pressureRadius - near) / T.pressureRadius;
    }
    if (rng.chance(T.bigMissChance)) base *= T.bigMissFactor;
    return rng.bell() * base * degToRad;
  }

  /// Multiplier for kick speed (about ±5 %).
  static double speedFactor(Rng rng) =>
      math.max(0.5, 1.0 + rng.bell() * T.speedErrorFraction);
}
