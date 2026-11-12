import 'dart:math' as math;

import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/control/bot_memory.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/sim/rules/receivers.dart';

/// The bot's choices with the ball: shoot, pass (reading its teammates'
/// runs), or carry. It only ever sets the same intent a human would.
abstract final class BotAttack {
  static const double _shotWait = 1.0;

  static void decide(
    TeamView v,
    Disc c,
    Intent i,
    BotLevel level,
    Rng rng,
    BotMemory mem,
  ) {
    final sp = v.s.setPiece;
    if (sp != null && sp.takerId == c.id) {
      _stop(i);
      if (sp.timer > level.setPieceDelay) _pass(v, c, i, level, rng, force: true);
      return;
    }
    if (_shoot(v, c, i, level, rng, mem)) return;
    final pressure = v.space(c.pos.x, c.pos.y);
    final hurry = pressure < 1.8 || mem.holdTime > level.holdMax;
    if (_pass(v, c, i, level, rng, force: hurry)) return;
    _carry(v, c, i, pressure);
  }

  /// Shoots only from a real chance: in the box, or a clear lane within
  /// range. Each chance gets one roll; after a "no" the bot waits
  /// [_shotWait] seconds before weighing a shot again.
  static bool _shoot(
    TeamView v,
    Disc c,
    Intent i,
    BotLevel level,
    Rng rng,
    BotMemory mem,
  ) {
    if (mem.shotLock > 0.0) return false;
    final m = v.s.mode;
    final gx = v.worldX(v.halfL);
    final dx = gx - c.pos.x;
    final dist = math.sqrt(dx * dx + c.pos.y * c.pos.y);
    final inBox = v.teamX(c) > v.halfL - m.boxDepth &&
        c.pos.y.abs() < m.boxWidth / 2;
    final clear = _clearShot(v, c, gx);
    // 7v7 is a bigger pitch: a clear lane allows a little more range.
    final range = m.shootRange * (m.teamSize > 5 && clear ? 1.2 : 1.0);
    if (dist > range) return false;
    final angleOk = c.pos.y.abs() < m.goalWidth * 1.8 || dist < 8.0;
    if (!angleOk) return false;
    final double chance;
    if (inBox && clear) {
      chance = 0.85;
    } else if (clear) {
      chance = level.shootChance * 2.5;
    } else if (inBox) {
      chance = level.shootChance;
    } else {
      return false; // blocked lane from outside the box: not a chance
    }
    if (!rng.chance(chance)) {
      mem.shotLock = _shotWait;
      return false;
    }

    // Aim for the corner away from their keeper.
    var keeperY = 0.0;
    for (final o in v.opp.discs) {
      if (o.isKeeper) keeperY = o.pos.y;
    }
    final side = keeperY >= c.pos.y * 0.2 ? -1.0 : 1.0;
    i.action = ActionKind.shoot;
    i.aimX = v.dir;
    i.aimY = side * rng.range(0.4, 0.9);
    i.power = rng.range(0.55, 0.95);
    _stop(i);
    return true;
  }

  /// No outfield opponent within 1 m of the line to the goal centre (the
  /// keeper doesn't count: beating him is the shot's job).
  static bool _clearShot(TeamView v, Disc c, double gx) {
    for (final o in v.opp.discs) {
      if (o.isKeeper) continue;
      final t = projectOnSegment(o.pos.x, o.pos.y, c.pos.x, c.pos.y, gx, 0.0);
      if (t < 0.05 || t > 0.98) continue;
      final d2 = pointSegmentDist2(o.pos.x, o.pos.y, c.pos.x, c.pos.y, gx, 0.0);
      if (d2 < 1.0) return false;
    }
    return true;
  }

  /// Scores every teammate as a pass option; plays the best one if it's
  /// good enough (or if [force]).
  static bool _pass(
    TeamView v,
    Disc c,
    Intent i,
    BotLevel level,
    Rng rng, {
    required bool force,
  }) {
    Disc? best;
    Disc? second;
    var bestScore = -double.infinity;
    var secondScore = -double.infinity;
    var bestThrough = false;
    var secondThrough = false;
    for (final m in v.team.discs) {
      if (m.id == c.id) continue;
      final dist = m.pos.distTo(c.pos);
      if (dist < 3.0 || dist > 30.0) continue;
      final through = _isRunning(m);
      var score = math.min(v.space(m.pos.x, m.pos.y), 6.0) * 0.5 +
          (v.teamX(m) - v.teamX(c)) * 0.12;
      if (Receivers.laneBlocked(c.pos, m.pos, v.opp)) score -= 6.0;
      // Long balls are riskier; short ones are nearly free.
      if (dist > 14.0) score -= (dist - 14.0) * 0.15;
      // A receiver with an opponent on him is a risky target.
      if (v.space(m.pos.x, m.pos.y) < 1.8) score -= 2.0;
      if (m.isKeeper) score -= 2.0;
      if (v.offsideOn && !through && v.teamX(m) > v.offsideLine) score -= 5.0;
      if (through) score += 1.5;
      if (_isOffering(m)) score += 0.6;
      if (score > bestScore) {
        second = best;
        secondScore = bestScore;
        secondThrough = bestThrough;
        best = m;
        bestScore = score;
        bestThrough = through;
      } else if (score > secondScore) {
        second = m;
        secondScore = score;
        secondThrough = through;
      }
    }
    if (best == null) return false;
    var pick = best;
    var through = bestThrough;
    if (second != null && secondScore > 0.0 && rng.chance(level.decisionNoise)) {
      pick = second;
      through = secondThrough;
    }
    final great = bestScore > 4.0;
    if (!force && !great) return false;
    // Forced but every option is bad: keep the ball (carry/shield) unless
    // it is about to be taken.
    if (force && bestScore < -2.0 && v.space(c.pos.x, c.pos.y) > 1.4) {
      return false;
    }

    var ax = pick.pos.x - c.pos.x;
    var ay = pick.pos.y - c.pos.y;
    final noise = rng.bell() * level.aimNoiseDeg * degToRad;
    final cs = math.cos(noise);
    final sn = math.sin(noise);
    final rx = ax * cs - ay * sn;
    ay = ax * sn + ay * cs;
    ax = rx;
    i.action = through ? ActionKind.through : ActionKind.pass;
    i.aimX = ax;
    i.aimY = ay;
    i.power = rng.range(0.3, 0.6);
    _stop(i);
    return true;
  }

  static bool _isRunning(Disc m) =>
      m.job == 'run in behind' ||
      m.job == 'overlap' ||
      m.job.endsWith(': runner') ||
      m.job.endsWith(': overlapper') ||
      m.job.endsWith(': third man');

  static bool _isOffering(Disc m) =>
      m.job == 'support' ||
      m.job == 'drop to receive' ||
      m.job.endsWith(': dropper') ||
      m.job.endsWith(': wall') ||
      m.job.endsWith(': inside option');

  /// Carry toward goal, bending away from the nearest opponent.
  static void _carry(TeamView v, Disc c, Intent i, double pressure) {
    var mx = v.worldX(v.halfL) - c.pos.x;
    var my = -c.pos.y * 0.6;
    var ml = math.sqrt(mx * mx + my * my);
    if (ml > 1e-6) {
      mx /= ml;
      my /= ml;
    }
    Disc? near;
    var nearD = 4.0;
    for (final o in v.opp.discs) {
      final d = o.pos.distTo(c.pos);
      if (d < nearD) {
        nearD = d;
        near = o;
      }
    }
    if (near != null) {
      final ox = c.pos.x - near.pos.x;
      final oy = c.pos.y - near.pos.y;
      final w = (4.0 - nearD) / 4.0;
      mx += ox / nearD * w;
      my += oy / nearD * w;
      ml = math.sqrt(mx * mx + my * my);
      if (ml > 1e-6) {
        mx /= ml;
        my /= ml;
      }
    }
    i.moveX = mx * 0.9;
    i.moveY = my * 0.9;
    // Dash only into real space (heavy touches are risky).
    i.dash = pressure > 6.0;
  }

  static void _stop(Intent i) {
    i.moveX = 0.0;
    i.moveY = 0.0;
    i.dash = false;
  }
}
