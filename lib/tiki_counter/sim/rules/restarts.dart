import 'dart:math' as math;

import 'package:b_ball/tiki_counter/core/geometry.dart';
import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/core/vec2.dart';
import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/intent.dart';
import 'package:b_ball/tiki_counter/model/match_event.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/set_piece.dart';
import 'package:b_ball/tiki_counter/model/side.dart';
import 'package:b_ball/tiki_counter/sim/match_setup.dart';
import 'package:b_ball/tiki_counter/sim/rules/ball_control.dart';
import 'package:b_ball/tiki_counter/sim/rules/passing.dart';
import 'package:b_ball/tiki_counter/sim/rules/receivers.dart';

/// Goals, throw-ins, corners, goal kicks, free kicks and kick-offs.
///
/// Flow: the ball goes out → [schedule] freezes play for a moment →
/// [tickPending] starts the restart → the nearest disc stands on the spot
/// with the ball ([holdSetPiece] keeps it there) → it plays the ball and
/// open play resumes.
class Restarts {
  final Passing passing;

  Restarts(this.passing);

  // ── Ball out of play ──────────────────────────────────────────────────
  void checkOutOfPlay(MatchState s) {
    if (s.pending != null) return; // already stopped (e.g. offside)
    final b = s.ball;
    final m = s.mode;
    final hl = m.halfLength;
    final hw = m.halfWidth;

    if (b.pos.y.abs() > hw + T.ballRadius) {
      final team = (b.lastTouchSide ?? Side.home).other;
      final x = clampD(b.pos.x, -hl + 0.5, hl - 0.5);
      schedule(s, RestartKind.throwIn, team, x, signD(b.pos.y) * hw);
      return;
    }
    if (b.pos.x.abs() <= hl + T.ballRadius) return;

    final end = signD(b.pos.x);
    final defender = end > 0 ? Side.away : Side.home;
    final attacker = defender.other;
    if (b.pos.y.abs() < m.goalWidth / 2.0 && b.z < m.goalHeight) {
      _goal(s, attacker, end);
    } else if (b.lastTouchSide == defender) {
      schedule(s, RestartKind.corner, attacker, end * hl, signD(b.pos.y) * hw);
    } else {
      schedule(s, RestartKind.goalKick, defender, end * (hl - 2.0), 0.0);
    }
  }

  void _goal(MatchState s, Side scorer, double end) {
    final b = s.ball;
    s.team(scorer).score++;
    if (b.lastKick == ActionKind.shoot && b.lastTouchSide == scorer) {
      s.team(scorer).stats.shotsOnTarget++;
    }
    s.emit(MatchEventKind.goal, scorer, b.lastTouchId);
    // Leave the ball resting in the net during the celebration.
    b.pos.x = end * (s.mode.halfLength + 0.6);
    b.vel.setZero();
    b.vz = 0.0;
    b.z = 0.0;
    b.ownerId = -1;
    final kick = SetPiece(
      kind: RestartKind.kickOff,
      team: scorer.other,
      spot: Vec2(),
    );
    s.pending = PendingRestart(kick, T.goalCelebration, resetShape: true);
  }

  /// Stops play and queues a restart.
  void schedule(MatchState s, RestartKind kind, Side team, double x, double y) {
    final b = s.ball;
    b.ownerId = -1;
    b.vel.setZero();
    b.vz = 0.0;
    b.z = 0.0;
    b.offsideIds.clear();
    s.setPiece = null;
    final sp = SetPiece(kind: kind, team: team, spot: Vec2(x, y));
    s.pending = PendingRestart(sp, T.restartDelay);
    s.emit(_eventFor(kind), team);
  }

  MatchEventKind _eventFor(RestartKind k) => switch (k) {
    RestartKind.throwIn => MatchEventKind.throwIn,
    RestartKind.corner => MatchEventKind.corner,
    RestartKind.goalKick => MatchEventKind.goalKick,
    RestartKind.freeKick => MatchEventKind.freeKick,
    RestartKind.kickOff => MatchEventKind.kickOff,
  };

  // ── Waiting, then starting ────────────────────────────────────────────
  void tickPending(MatchState s, double dt) {
    final p = s.pending;
    if (p == null) return;
    p.delay -= dt;
    if (p.delay > 0.0) return;
    s.pending = null;
    if (p.resetShape) MatchSetup.resetShape(s, kickOffSide: p.setPiece.team);
    start(s, p.setPiece);
  }

  /// Puts the taker on the spot with the ball.
  void start(MatchState s, SetPiece sp) {
    final team = s.team(sp.team);
    final taker = _pickTaker(s, sp);
    final out = _behindDir(sp);
    const gap = T.discRadius + T.ballRadius + T.carryGap;
    taker.pos.set(sp.spot.x + out.x * gap, sp.spot.y + out.y * gap);
    taker.prev.setFrom(taker.pos);
    taker.vel.setZero();
    taker.facing.set(-out.x, -out.y);
    sp.takerPos.setFrom(taker.pos);
    sp.takerFacing.setFrom(taker.facing);
    sp.takerId = taker.id;
    sp.timer = 0.0;
    BallControl.give(s, taker);
    s.ball.pos.setFrom(sp.spot);
    s.ball.prev.setFrom(sp.spot);
    s.setPiece = sp;
    team.cursorId = taker.id;
  }

  Disc _pickTaker(MatchState s, SetPiece sp) {
    final team = s.team(sp.team);
    if (sp.kind == RestartKind.kickOff) {
      return team.discs[team.formation.kickOffSlot];
    }
    if (sp.kind == RestartKind.goalKick) {
      return team.discs.firstWhere((d) => d.isKeeper);
    }
    Disc? best;
    var bestD = double.infinity;
    for (final d in team.discs) {
      if (d.isKeeper) continue;
      final dist = d.pos.distTo(sp.spot);
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    return best ?? team.discs.first;
  }

  /// Unit vector from the ball to where the taker stands.
  Vec2 _behindDir(SetPiece sp) {
    final v = switch (sp.kind) {
      RestartKind.throwIn => Vec2(0.0, signD(sp.spot.y)),
      RestartKind.corner => Vec2(signD(sp.spot.x), signD(sp.spot.y)),
      _ => Vec2(-sp.team.attackDir, 0.0),
    };
    v.normalize();
    return v;
  }

  // ── During the restart ────────────────────────────────────────────────
  /// Keeps the taker and ball on the spot and opponents back; takes it
  /// automatically if nobody does. Runs after `Possession.carry`.
  void holdSetPiece(MatchState s, double dt) {
    final sp = s.setPiece;
    if (sp == null) return;
    final b = s.ball;
    if (b.ownerId != sp.takerId) {
      s.setPiece = null;
      return;
    }
    sp.timer += dt;
    final taker = s.discs[sp.takerId];
    taker.pos.setFrom(sp.takerPos);
    taker.vel.setZero();
    taker.facing.setFrom(sp.takerFacing);
    b.pos.setFrom(sp.spot);
    b.vel.setZero();
    _clearOpponents(s, sp);
    if (sp.timer > T.setPieceAutoTake) {
      final target = Receivers.bestOpen(s, taker);
      var ax = taker.facing.x;
      var ay = taker.facing.y;
      if (target != null) {
        ax = target.pos.x - taker.pos.x;
        ay = target.pos.y - taker.pos.y;
      }
      passing.execute(s, taker, ActionKind.pass, ax, ay, 0.5);
    }
  }

  void _clearOpponents(MatchState s, SetPiece sp) {
    const r = T.setPieceClearance;
    for (final o in s.team(sp.team.other).discs) {
      final dx = o.pos.x - sp.spot.x;
      final dy = o.pos.y - sp.spot.y;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d >= r) continue;
      if (d < 1e-6) {
        o.pos.x = sp.spot.x - sp.team.attackDir * r;
        continue;
      }
      o.pos.x = sp.spot.x + dx / d * r;
      o.pos.y = sp.spot.y + dy / d * r;
    }
  }
}
