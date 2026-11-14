import 'dart:math' as math;

import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/set_piece.dart';

/// Where players may stand while a restart is being taken:
/// - opponents keep [T.setPieceClearance] from the ball (at a kick-off:
///   outside the centre circle);
/// - at a kick-off, everyone but the taker stays in their own half.
///
/// The rules use it on positions (`Restarts.holdSetPiece`), and the team
/// brain on targets, so players walk to a legal spot instead of being
/// pushed back every frame.
abstract final class SetPieceZone {
  /// Moves [p] (a position or a target of [d]) to the nearest legal spot.
  static void keepOut(MatchState s, Disc d, Vec2 p) {
    final sp = s.setPiece;
    if (sp == null || d.id == sp.takerId) return;
    final dir = s.dir(d.side);
    final kickOff = sp.kind == RestartKind.kickOff;
    if (kickOff && p.x * dir > -0.3) p.x = -0.3 * dir;
    if (d.side == sp.team) return;

    final r = kickOff ? s.mode.centreCircle + 0.3 : T.setPieceClearance;
    final dx = p.x - sp.spot.x;
    final dy = p.y - sp.spot.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist >= r) return;
    if (dist < 1e-6) {
      p.x = sp.spot.x - dir * r; // straight back toward own goal
      return;
    }
    p.x = sp.spot.x + dx / dist * r;
    p.y = sp.spot.y + dy / dist * r;
  }
}
