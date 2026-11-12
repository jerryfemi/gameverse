import 'dart:math' as math;

import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/control/team_controller.dart';
import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';
import 'package:tiki_core/sim/rules/receivers.dart';

/// Plays the bot team's controlled disc by pressing the same "buttons" a
/// human would. Simple rules for now (milestone 3):
/// - with the ball: shoot in range, pass under pressure or after holding
///   too long, otherwise carry toward goal;
/// - without it: close down the ball and tackle when close.
class BotController implements TeamController {
  final Rng rng;
  final BotLevel level;

  double _thinkTimer = 0.0;
  double _holdTime = 0.0;
  int _holder = -1;

  BotController({required this.rng, this.level = BotLevel.normal});

  @override
  void fill(MatchState s, TeamState team, double dt) {
    final i = team.intent;
    final c = s.discs[team.cursorId];
    if (s.ball.ownerId == c.id) {
      if (_holder != c.id) {
        _holder = c.id;
        _holdTime = 0.0;
      }
      _holdTime += dt;
    } else {
      _holder = -1;
    }

    _thinkTimer -= dt;
    if (_thinkTimer > 0.0) return;
    _thinkTimer = level.thinkInterval;

    i.dash = false;
    i.secondMan = false;
    if (s.isFrozen) {
      i.moveX = 0.0;
      i.moveY = 0.0;
      return;
    }
    if (s.ball.ownerId == c.id) {
      _withBall(s, team, c, i);
    } else {
      _withoutBall(s, team, c, i);
    }
  }

  void _withBall(MatchState s, TeamState team, Disc c, Intent i) {
    final sp = s.setPiece;
    if (sp != null && sp.takerId == c.id) {
      i.moveX = 0.0;
      i.moveY = 0.0;
      if (sp.timer > level.setPieceDelay) _passToBest(s, c, i);
      return;
    }

    final dir = team.side.attackDir;
    final gx = dir * s.mode.halfLength;
    final toGoal = math.sqrt(
      (gx - c.pos.x) * (gx - c.pos.x) + c.pos.y * c.pos.y,
    );
    if (toGoal < s.mode.shootRange && rng.chance(level.shootChance)) {
      i.action = ActionKind.shoot;
      i.aimX = dir;
      i.aimY = -signD(c.pos.y) * rng.range(0.3, 0.8);
      i.power = rng.range(0.5, 0.95);
      return;
    }

    final pressure = Receivers.nearestOpponentDist(
      s.team(team.side.other),
      c.pos,
    );
    if (pressure < 2.2 || _holdTime > level.holdMax) {
      if (_passToBest(s, c, i)) return;
    }

    // Carry toward goal, drifting to the middle.
    var mx = gx - c.pos.x;
    var my = -c.pos.y * 0.6;
    final ml = math.sqrt(mx * mx + my * my);
    if (ml > 1e-6) {
      mx /= ml;
      my /= ml;
    }
    i.moveX = mx * 0.9;
    i.moveY = my * 0.9;
  }

  bool _passToBest(MatchState s, Disc c, Intent i) {
    final r = Receivers.bestOpen(s, c);
    if (r == null) return false;
    final ahead = (r.pos.x - c.pos.x) * c.side.attackDir;
    i.action = ahead > 6.0 && rng.chance(0.35)
        ? ActionKind.through
        : ActionKind.pass;
    i.aimX = r.pos.x - c.pos.x;
    i.aimY = r.pos.y - c.pos.y;
    i.power = rng.range(0.3, 0.6);
    i.moveX = 0.0;
    i.moveY = 0.0;
    return true;
  }

  void _withoutBall(MatchState s, TeamState team, Disc c, Intent i) {
    final carrier = s.owner;
    double tx;
    double ty;
    if (carrier != null && carrier.side != team.side) {
      // Goal side of the carrier.
      tx = carrier.pos.x - team.side.attackDir * 1.0;
      ty = carrier.pos.y;
      final close = carrier.pos.distTo(c.pos) < T.tackleRange * 0.95;
      if (close && rng.chance(level.tacklePerSecond * level.thinkInterval)) {
        i.action = ActionKind.tackle;
      }
    } else {
      tx = s.ball.pos.x + s.ball.vel.x * 0.3;
      ty = s.ball.pos.y + s.ball.vel.y * 0.3;
    }
    final dx = tx - c.pos.x;
    final dy = ty - c.pos.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.3) {
      i.moveX = 0.0;
      i.moveY = 0.0;
      return;
    }
    final amount = math.min(1.0, dist / 2.0);
    i.moveX = dx / dist * amount;
    i.moveY = dy / dist * amount;
    i.dash = dist > 4.0;
  }
}
