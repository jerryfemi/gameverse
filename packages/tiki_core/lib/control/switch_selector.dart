import 'dart:math' as math;

import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';

/// Picks which disc the controller steers (the "cursor").
///
/// In order:
/// 1. Our team has the ball → the carrier.
/// 2. Our pass is travelling → the intended receiver.
/// 3. A SWITCH tap/swipe → the candidate, or the teammate in that direction.
///    Assisted switching then waits [T.manualSwitchLock] seconds.
/// 4. Otherwise (defending) → the disc that can reach the ball soonest,
///    with a bonus for being goal-side, and hysteresis so it doesn't flicker.
class SwitchSelector {
  double _timer = 0.0;

  void update(MatchState s, TeamState team, double dt) {
    if (team.manualSwitchLock > 0.0) {
      team.manualSwitchLock = math.max(0.0, team.manualSwitchLock - dt);
    }
    final b = s.ball;
    final owner = s.owner;

    if (owner != null && owner.side == team.side) {
      _follow(team, owner.id);
      return;
    }
    final r = b.intendedReceiverId;
    if (owner == null &&
        b.lastTouchSide == team.side &&
        r >= 0 &&
        s.discs[r].side == team.side) {
      _follow(team, r);
      return;
    }

    final request = team.intent.switchTo;
    if (request != SwitchKind.none) {
      team.intent.switchTo = SwitchKind.none;
      _manual(s, team, request);
    }

    _timer -= dt;
    if (_timer > 0.0) return;
    _timer = T.switchInterval;
    _assisted(s, team);
  }

  void _follow(TeamState team, int id) {
    team.cursorId = id;
    team.nextCandidateId = -1;
    team.intent.switchTo = SwitchKind.none;
  }

  /// Seconds for [d] to reach the ball (lower = better placed).
  double _score(MatchState s, TeamState team, Disc d) {
    if (d.isKeeper) return double.infinity;
    final b = s.ball;
    final px = b.pos.x + b.vel.x * 0.3;
    final py = b.pos.y + b.vel.y * 0.3;
    final dx = px - d.pos.x;
    final dy = py - d.pos.y;
    var t = math.sqrt(dx * dx + dy * dy) / T.runSpeed;
    final dir = team.side.attackDir;
    if (d.pos.x * dir < px * dir) t -= T.goalSideBonus;
    return t;
  }

  void _assisted(MatchState s, TeamState team) {
    var best = -1;
    var second = -1;
    var bestScore = double.infinity;
    var secondScore = double.infinity;
    for (final d in team.discs) {
      final sc = _score(s, team, d);
      if (sc < bestScore) {
        second = best;
        secondScore = bestScore;
        best = d.id;
        bestScore = sc;
      } else if (sc < secondScore) {
        second = d.id;
        secondScore = sc;
      }
    }
    if (best < 0) return;
    final current = s.discs[team.cursorId];
    if (team.manualSwitchLock <= 0.0 && best != current.id) {
      final currentScore = _score(s, team, current);
      if (bestScore + T.switchHysteresis < currentScore) team.cursorId = best;
    }
    team.nextCandidateId = best != team.cursorId ? best : second;
  }

  void _manual(MatchState s, TeamState team, SwitchKind kind) {
    final from = s.discs[team.cursorId];
    int pick;
    if (kind == SwitchKind.candidate) {
      pick = team.nextCandidateId;
    } else {
      pick = _inDirection(team, from, kind);
    }
    if (pick < 0 || pick == team.cursorId) return;
    team.cursorId = pick;
    team.manualSwitchLock = T.manualSwitchLock;
  }

  /// Teammate roughly up/down/left/right of the current disc
  /// (screen directions: up = −y).
  int _inDirection(TeamState team, Disc from, SwitchKind kind) {
    final (dx, dy) = switch (kind) {
      SwitchKind.up => (0.0, -1.0),
      SwitchKind.down => (0.0, 1.0),
      SwitchKind.left => (-1.0, 0.0),
      _ => (1.0, 0.0),
    };
    const maxAngle = 70.0 * degToRad;
    var best = -1;
    var bestScore = double.infinity;
    for (final d in team.discs) {
      if (d.id == from.id || d.isKeeper) continue;
      final vx = d.pos.x - from.pos.x;
      final vy = d.pos.y - from.pos.y;
      final ang = angleBetween(dx, dy, vx, vy);
      if (ang > maxAngle) continue;
      final score = ang + math.sqrt(vx * vx + vy * vy) * 0.03;
      if (score < bestScore) {
        bestScore = score;
        best = d.id;
      }
    }
    return best;
  }
}
