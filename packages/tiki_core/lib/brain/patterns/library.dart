import 'dart:math' as math;

import 'package:tiki_core/brain/patterns/pattern.dart';
import 'package:tiki_core/brain/patterns/picks.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// The built-in combinations. New ones (from the tactics-board clips) are
/// added here the same way: trigger + parts (pick + move).
abstract final class PatternLibrary {
  /// UP-BACK-THROUGH: the striker is marked tight, so he comes short to
  /// offer a wall pass, which drags his marker out; a runner goes into the
  /// space behind.
  static final Pattern upBackThrough = Pattern(
    id: 'up_back_through',
    label: 'up-back-through',
    trigger: (v, carrier) {
      final cx = v.teamX(carrier);
      if (cx < -0.35 * v.halfL || cx > 0.45 * v.halfL) return false;
      final striker = Picks.targetUpFront(v, carrier, const {});
      return striker != null && v.space(striker.pos.x, striker.pos.y) < 3.0;
    },
    parts: [
      PatternPart(
        'dropper',
        pick: Picks.targetUpFront,
        move: (v, carrier, me) => (
          x: v.worldX(v.teamX(carrier) + 5.0),
          y: v.clampY(carrier.pos.y + (me.pos.y - carrier.pos.y) * 0.3),
        ),
      ),
      PatternPart(
        'runner',
        pick: Picks.bestRunner,
        move: (v, carrier, me) => (
          x: v.worldX(math.min(v.offsideLine + 7.0, v.halfL - 3.0)),
          y: v.clampY(me.pos.y * 0.5, 2.0),
        ),
      ),
    ],
  );

  /// OVERLAP: carrier is wide; the full back (or wide mid) behind him runs
  /// round the outside while a teammate offers the inside pass.
  static final Pattern overlap = Pattern(
    id: 'overlap',
    label: 'overlap',
    trigger: (v, carrier) =>
        carrier.pos.y.abs() > v.halfW * 0.35 &&
        v.teamX(carrier) > -0.2 * v.halfL &&
        Picks.overlapper(v, carrier, const {}) != null,
    parts: [
      PatternPart(
        'overlapper',
        pick: Picks.overlapper,
        move: (v, carrier, me) => (
          x: v.worldX(math.min(v.teamX(carrier) + 8.0, v.halfL - 3.0)),
          y: _side(carrier) * v.halfW * 0.88,
        ),
      ),
      PatternPart(
        'inside option',
        pick: Picks.nearest,
        move: (v, carrier, me) => (
          x: v.worldX(math.min(v.teamX(carrier) + 5.0, v.halfL - 4.0)),
          y: _side(carrier) * v.halfW * 0.25,
        ),
      ),
    ],
    duration: 3.0,
    cooldown: 6.0,
    styles: {AttackStyle.possession, AttackStyle.wide, AttackStyle.overload},
  );

  /// THIRD-MAN RUN: from deep, a teammate ahead comes short as a wall; a
  /// third player runs beyond him to receive the lay-off pass forward.
  static final Pattern thirdMan = Pattern(
    id: 'third_man',
    label: 'third-man run',
    trigger: (v, carrier) =>
        v.teamX(carrier) < 0.1 * v.halfL &&
        Picks.wallAhead(v, carrier, const {}) != null,
    parts: [
      PatternPart(
        'wall',
        pick: Picks.wallAhead,
        move: (v, carrier, me) => (
          x: me.pos.x + (carrier.pos.x - me.pos.x) * 0.25,
          y: me.pos.y,
        ),
      ),
      PatternPart(
        'third man',
        pick: Picks.nearest,
        move: (v, carrier, me) => (
          x: v.worldX(math.min(v.teamX(carrier) + 18.0, v.halfL - 4.0)),
          y: v.clampY(carrier.pos.y * 0.3 + (me.pos.y > 0 ? 4.0 : -4.0)),
        ),
      ),
    ],
    styles: {AttackStyle.possession, AttackStyle.overload},
  );

  static final List<Pattern> all = [upBackThrough, overlap, thirdMan];

  static double _side(Disc carrier) => carrier.pos.y >= 0 ? 1.0 : -1.0;
}
