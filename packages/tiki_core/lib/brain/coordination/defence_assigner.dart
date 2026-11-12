import 'package:tiki_core/brain/coordination/assignments.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Without the ball: who presses, who cuts which lane, who marks whom, who
/// covers. Also picks the loose-ball chaser in any phase.
abstract final class DefenceAssigner {
  static void assign(TeamView v, TeamPlan plan, Assignments a) {
    _chaser(v, a);
    final carrier = v.carrier;
    if (carrier == null || carrier.side == v.team.side) return;

    final counterPress = v.phase == Phase.defenceTransition &&
        plan.afterLoss == AfterLoss.counterPress;
    // Press when the ball is in our press zone. Intensity 0 = only deep in
    // our own half; 1 = anywhere on the pitch.
    final pressFrom = (-0.45 + 1.35 * plan.pressIntensity) * v.halfL;
    final pressNow = counterPress || v.ballX <= pressFrom;

    final ranked = _outfield(v)
      ..sort((p, q) => p.pos
          .dist2To(carrier.pos)
          .compareTo(q.pos.dist2To(carrier.pos)));
    if (pressNow && ranked.isNotEmpty) {
      a.pressers.add(ranked[0].id);
      final extra = counterPress ? 2 : (plan.pressIntensity >= 0.7 ? 1 : 0);
      for (var i = 1; i <= extra && i < ranked.length; i++) {
        a.pressers.add(ranked[i].id);
      }
    }
    // 2ND MAN held: the nearest teammate who isn't the controlled disc joins.
    if (v.team.secondManHeld) {
      for (final d in ranked) {
        if (d.id == v.team.cursorId) continue;
        if (!a.pressers.contains(d.id)) a.pressers.add(d.id);
        break;
      }
    }

    if (plan.marking == Marking.man) {
      _manMark(v, a, carrier);
    } else if (plan.pressIntensity >= 0.3) {
      _cutLanes(v, a, carrier);
    }
    if (plan.lineHeight >= 0.5) _cover(v, a);
  }

  static List<Disc> _outfield(TeamView v) =>
      [for (final d in v.team.discs) if (!d.isKeeper) d];

  static bool _free(Assignments a, Disc d) =>
      !a.pressers.contains(d.id) &&
      !a.laneCuts.containsKey(d.id) &&
      !a.marks.containsKey(d.id) &&
      a.chaser != d.id;

  /// Their two most dangerous options (closest to the carrier and ahead of
  /// it) each get the nearest free disc in the lane.
  static void _cutLanes(TeamView v, Assignments a, Disc carrier) {
    final options = [
      for (final o in v.opp.discs)
        if (!o.isKeeper && o.id != carrier.id) o,
    ]..sort((p, q) => p.pos
        .dist2To(carrier.pos)
        .compareTo(q.pos.dist2To(carrier.pos)));
    var cuts = 0;
    for (final o in options) {
      if (cuts >= 2) break;
      Disc? best;
      var bestD = 15.0;
      final mx = (carrier.pos.x + o.pos.x) / 2.0;
      final my = (carrier.pos.y + o.pos.y) / 2.0;
      for (final d in _outfield(v)) {
        if (!_free(a, d)) continue;
        final dd = (d.pos.x - mx).abs() + (d.pos.y - my).abs();
        if (dd < bestD) {
          bestD = dd;
          best = d;
        }
      }
      if (best != null) {
        a.laneCuts[best.id] = o.id;
        cuts++;
      }
    }
  }

  /// Each opponent (most dangerous first: nearest our goal) gets the
  /// nearest free defender.
  static void _manMark(TeamView v, Assignments a, Disc carrier) {
    final targets = [
      for (final o in v.opp.discs)
        if (!o.isKeeper && o.id != carrier.id) o,
    ]..sort((p, q) => v.teamX(p).compareTo(v.teamX(q)));
    for (final o in targets) {
      Disc? best;
      var bestD = double.infinity;
      for (final d in _outfield(v)) {
        if (!_free(a, d)) continue;
        final dd = d.pos.dist2To(o.pos);
        if (dd < bestD) {
          bestD = dd;
          best = d;
        }
      }
      if (best != null) a.marks[best.id] = o.id;
    }
  }

  /// Deepest free outfield disc stays back as cover behind a high line.
  static void _cover(TeamView v, Assignments a) {
    Disc? best;
    var bestX = double.infinity;
    for (final d in _outfield(v)) {
      if (!_free(a, d)) continue;
      final x = v.teamX(d);
      if (x < bestX) {
        bestX = x;
        best = d;
      }
    }
    if (best != null) a.cover = best.id;
  }

  /// Nearest outfield disc chases a loose ball nobody of ours is meant to
  /// receive.
  static void _chaser(TeamView v, Assignments a) {
    final b = v.s.ball;
    if (!b.isLoose || v.s.isFrozen) return;
    final ourPass = b.lastTouchSide == v.team.side && b.intendedReceiverId >= 0;
    if (ourPass) return;
    var bestD = 14.0;
    for (final d in _outfield(v)) {
      if (d.id == v.team.cursorId) continue;
      final dd = d.pos.distTo(b.pos);
      if (dd < bestD) {
        bestD = dd;
        a.chaser = d.id;
      }
    }
  }
}
