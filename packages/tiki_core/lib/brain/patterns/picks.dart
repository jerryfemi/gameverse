import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/position.dart';

/// Reusable "who plays this part" helpers for patterns.
abstract final class Picks {
  static Position positionOf(TeamView v, Disc d) =>
      v.team.formation.spots[d.slot].position;

  /// Free outfield discs (not the carrier, not taken, not the keeper).
  static Iterable<Disc> free(TeamView v, Disc carrier, Set<int> taken) =>
      v.team.discs.where(
        (d) => !d.isKeeper && d.id != carrier.id && !taken.contains(d.id),
      );

  /// The most advanced striker / attacking mid, 6–20 m ahead of the ball.
  static Disc? targetUpFront(TeamView v, Disc carrier, Set<int> taken) {
    Disc? best;
    var bestX = -double.infinity;
    final cx = v.teamX(carrier);
    for (final d in free(v, carrier, taken)) {
      final p = positionOf(v, d);
      if (p != Position.striker && p != Position.attackingMid) continue;
      final ahead = v.teamX(d) - cx;
      if (ahead < 6.0 || ahead > 20.0) continue;
      if (v.teamX(d) > bestX) {
        bestX = v.teamX(d);
        best = d;
      }
    }
    return best;
  }

  /// Onside disc ahead of the ball with the most space behind their line.
  static Disc? bestRunner(TeamView v, Disc carrier, Set<int> taken) {
    Disc? best;
    var bestScore = 0.0;
    for (final d in free(v, carrier, taken)) {
      final x = v.teamX(d);
      if (x < v.teamX(carrier) - 2.0) continue;
      if (v.offsideOn && x > v.offsideLine) continue;
      final score = v.space(v.worldX(v.offsideLine + 5.0), d.pos.y);
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }

  /// Wide defender / wide mid behind the carrier on the carrier's flank.
  static Disc? overlapper(TeamView v, Disc carrier, Set<int> taken) {
    Disc? best;
    var bestD = 15.0;
    for (final d in free(v, carrier, taken)) {
      final p = positionOf(v, d);
      if (!p.isWide && p != Position.centreBack) continue;
      if ((d.pos.y > 0) != (carrier.pos.y > 0)) continue;
      final behind = v.teamX(carrier) - v.teamX(d);
      if (behind < 3.0 || behind > 15.0) continue;
      final dist = d.pos.distTo(carrier.pos);
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best;
  }

  /// Nearest free disc ahead of the carrier (a wall to bounce off).
  static Disc? wallAhead(TeamView v, Disc carrier, Set<int> taken) {
    Disc? best;
    var bestD = double.infinity;
    for (final d in free(v, carrier, taken)) {
      final ahead = v.teamX(d) - v.teamX(carrier);
      if (ahead < 6.0 || ahead > 16.0) continue;
      if (!v.laneOpen(carrier.pos.x, carrier.pos.y, d.pos.x, d.pos.y)) {
        continue;
      }
      final dist = d.pos.distTo(carrier.pos);
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best;
  }

  /// Nearest free disc to the carrier, any position.
  static Disc? nearest(TeamView v, Disc carrier, Set<int> taken) {
    Disc? best;
    var bestD = double.infinity;
    for (final d in free(v, carrier, taken)) {
      final dist = d.pos.distTo(carrier.pos);
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best;
  }
}
