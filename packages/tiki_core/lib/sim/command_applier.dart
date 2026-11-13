import 'dart:math' as math;

import 'package:tiki_core/brain/ball_prediction.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';
import 'package:tiki_core/sim/rules/passing.dart';
import 'package:tiki_core/sim/rules/tackle.dart';

/// Turns a team's [Intent] into what its controlled disc does this tick:
/// - stick → desired velocity (carry / dash / run / sprint speeds)
/// - PRESS held with no stick → close down the carrier on the goal side
/// - PASS / THROUGH / LOB / SHOOT / TACKLE → the matching rule
///
/// Switching is done earlier by the controller layer (`SwitchSelector`).
class CommandApplier {
  final Passing passing;
  final Tackle tackle;
  final Vec2 _meet = Vec2();

  CommandApplier(this.passing, this.tackle);

  void apply(MatchState s, TeamState team) {
    final intent = team.intent;
    for (final d in team.discs) {
      d.manual = false;
      d.dashing = false;
    }
    final c = s.discs[team.cursorId];
    c.manual = true;
    c.dashing = intent.dash;
    team.secondManHeld = intent.secondMan;
    _move(s, team, c, intent);
    _act(s, c, intent);
    intent.clearOneShots();
  }

  void _move(MatchState s, TeamState team, Disc c, Intent intent) {
    if (_receiving(s, team, c)) {
      _runOntoPass(s, c);
      return;
    }
    final hasBall = s.ball.ownerId == c.id;
    final mx = intent.moveX;
    final my = intent.moveY;
    final m = math.sqrt(mx * mx + my * my);

    if (m > T.stickDeadZone) {
      final amount = math.min(1.0, m);
      final speed = hasBall
          ? (intent.dash ? T.carryDashSpeed : T.carrySpeed)
          : (intent.dash ? T.sprintSpeed : T.runSpeed);
      c.desiredVel.set(mx / m * speed * amount, my / m * speed * amount);
      return;
    }
    if (intent.dash && !hasBall) {
      _press(s, team, c);
      return;
    }
    c.desiredVel.setZero();
  }

  /// Our pass is on its way to [c]: the stick is ignored until he has it,
  /// so you can't steer the receiver away from his own ball.
  bool _receiving(MatchState s, TeamState team, Disc c) {
    final b = s.ball;
    return b.isLoose &&
        !b.dribbleTouch && // a carry touch: the carrier keeps his stick
        b.lastTouchSide == team.side &&
        b.intendedReceiverId == c.id &&
        b.lastKick != ActionKind.shoot;
  }

  /// Run to where the ball's path passes closest, quickly if it's far,
  /// easing off on arrival so he meets it instead of overrunning it.
  void _runOntoPass(MatchState s, Disc c) {
    BallPrediction.meetPoint(s.ball, c, _meet);
    final dx = _meet.x - c.pos.x;
    final dy = _meet.y - c.pos.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.15) {
      c.desiredVel.setZero();
      return;
    }
    final top = dist > 3.0 ? T.sprintSpeed : T.runSpeed;
    final speed = top * math.min(1.0, dist / T.arriveRadius);
    c.desiredVel.set(dx / dist * speed, dy / dist * speed);
  }

  /// PRESS with the stick centred: close down at a controlled speed and
  /// stop about a metre off, between the carrier and our goal.
  void _press(MatchState s, TeamState team, Disc c) {
    final carrier = s.owner;
    double tx;
    double ty;
    if (carrier != null && carrier.side != team.side) {
      final gx = -s.dir(team.side) * s.mode.halfLength;
      var nx = gx - carrier.pos.x;
      var ny = -carrier.pos.y;
      final nl = math.sqrt(nx * nx + ny * ny);
      if (nl > 1e-6) {
        nx /= nl;
        ny /= nl;
      }
      tx = carrier.pos.x + nx * T.pressStandOff;
      ty = carrier.pos.y + ny * T.pressStandOff;
    } else if (carrier == null) {
      tx = s.ball.pos.x;
      ty = s.ball.pos.y;
    } else {
      c.desiredVel.setZero(); // our own team has it
      return;
    }
    final dx = tx - c.pos.x;
    final dy = ty - c.pos.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.1) {
      c.desiredVel.setZero();
      return;
    }
    final speed = T.sprintSpeed *
        T.pressSpeedFactor *
        math.min(1.0, dist / T.arriveRadius);
    c.desiredVel.set(dx / dist * speed, dy / dist * speed);
  }

  void _act(MatchState s, Disc c, Intent intent) {
    switch (intent.action) {
      case ActionKind.pass:
      case ActionKind.through:
      case ActionKind.lob:
      case ActionKind.shoot:
        passing.execute(
          s,
          c,
          intent.action,
          intent.aimX,
          intent.aimY,
          intent.power,
        );
      case ActionKind.tackle:
        if (s.ball.ownerId != c.id) tackle.execute(s, c);
      case ActionKind.none:
        break;
    }
  }
}
