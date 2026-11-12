import 'dart:math' as math;

import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/match_state.dart';

/// Discs can't overlap: any two that touch are pushed apart equally.
///
/// The ball passes between discs; picking it up is a rule
/// (see `rules/possession.dart`), not a collision.
class Collisions {
  /// A couple of passes settles crowds of three or more discs.
  static const int iterations = 2;

  void resolve(MatchState s) {
    final minDist = T.discRadius * 2.0;
    final minDist2 = minDist * minDist;
    final list = s.discs;
    for (var it = 0; it < iterations; it++) {
      for (var i = 0; i < list.length; i++) {
        final a = list[i];
        for (var j = i + 1; j < list.length; j++) {
          final b = list[j];
          final dx = b.pos.x - a.pos.x;
          final dy = b.pos.y - a.pos.y;
          final d2 = dx * dx + dy * dy;
          if (d2 >= minDist2) continue;
          final d = math.sqrt(d2);
          // Exactly on top of each other: nudge along x.
          final nx = d > 1e-6 ? dx / d : 1.0;
          final ny = d > 1e-6 ? dy / d : 0.0;
          final push = (minDist - d) * 0.5;
          a.pos.x -= nx * push;
          a.pos.y -= ny * push;
          b.pos.x += nx * push;
          b.pos.y += ny * push;
        }
      }
    }
  }
}
