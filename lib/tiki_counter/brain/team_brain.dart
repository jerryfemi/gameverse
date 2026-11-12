import 'package:b_ball/tiki_counter/brain/ball_prediction.dart';
import 'package:b_ball/tiki_counter/brain/home_spots.dart';
import 'package:b_ball/tiki_counter/core/geometry.dart';
import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/side.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';

/// Decides a target for every disc the controller isn't steering.
///
/// **Placeholder brain for milestones 0–3.** It knows just enough to make a
/// match playable: receive passes, chase loose balls, keeper stays in goal,
/// 2ND MAN joins the press, everyone else holds a home spot.
/// Milestone 5 replaces the job list with scored behaviours
/// (see `claude/tactics-architecture.md` §4).
class TeamBrain {
  final Side side;
  double _timer = 0.0;

  TeamBrain(this.side);

  void update(MatchState s, double dt) {
    _timer -= dt;
    if (_timer > 0.0) return;
    _timer = T.brainInterval;
    _think(s);
  }

  void _think(MatchState s) {
    final team = s.team(side);
    final b = s.ball;
    final attacking = s.possessionSide == side;
    final receiving = b.isLoose && b.lastTouchSide == side;
    final chaser = _chaser(s, team, receiving);
    final second = team.secondManHeld ? _secondMan(s, team) : -1;

    for (final d in team.discs) {
      if (d.id == team.cursorId) {
        d.job = 'controlled';
      } else if (receiving && d.id == b.intendedReceiverId) {
        BallPrediction.meetPoint(b, d, d.target);
        d.urgency = 1.4;
        d.job = 'receive pass';
      } else if (d.isKeeper) {
        _keeper(s, d);
      } else if (d.id == second) {
        d.target.setFrom(s.owner!.pos);
        d.urgency = 1.4;
        d.job = '2nd man press';
      } else if (d.id == chaser) {
        BallPrediction.meetPoint(b, d, d.target);
        d.urgency = 1.4;
        d.job = 'chase loose ball';
      } else {
        HomeSpots.place(s, team, d, attacking);
      }
    }
  }

  /// Nearest outfield disc (not the controlled one) to a loose ball nobody
  /// is meant to receive.
  int _chaser(MatchState s, TeamState team, bool receiving) {
    final b = s.ball;
    if (!b.isLoose || s.isFrozen) return -1;
    if (receiving && b.intendedReceiverId >= 0) return -1;
    var best = -1;
    var bestD = 12.0;
    for (final d in team.discs) {
      if (d.isKeeper || d.id == team.cursorId) continue;
      final dist = d.pos.distTo(b.pos);
      if (dist < bestD) {
        bestD = dist;
        best = d.id;
      }
    }
    return best;
  }

  int _secondMan(MatchState s, TeamState team) {
    final carrier = s.owner;
    if (carrier == null || carrier.side == side) return -1;
    var best = -1;
    var bestD = double.infinity;
    for (final d in team.discs) {
      if (d.isKeeper || d.id == team.cursorId) continue;
      final dist = d.pos.distTo(carrier.pos);
      if (dist < bestD) {
        bestD = dist;
        best = d.id;
      }
    }
    return best;
  }

  void _keeper(MatchState s, Disc d) {
    final m = s.mode;
    final dir = side.attackDir;
    final b = s.ball;
    // Claim a slow loose ball in our box.
    final ballDepth = b.pos.x * dir;
    final inBox = ballDepth < -(m.halfLength - m.boxDepth) &&
        b.pos.y.abs() < m.boxWidth / 2.0;
    if (b.isLoose && inBox && b.speed < 6.0) {
      d.target.setFrom(b.pos);
      d.urgency = 1.3;
      d.job = 'keeper claims';
      return;
    }
    final gx = -dir * (m.halfLength - 0.8);
    final gy = clampD(b.pos.y * 0.4, -m.goalWidth * 0.4, m.goalWidth * 0.4);
    d.target.set(gx, gy);
    d.urgency = 1.0;
    d.job = 'keeper';
  }
}
