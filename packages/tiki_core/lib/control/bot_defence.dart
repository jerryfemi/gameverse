import 'dart:math' as math;

import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/intent.dart';

/// The bot's controlled disc without the ball: press inside its plan's press
/// zone (goal-side), otherwise screen in front of the carrier; chase loose
/// balls; tackle when close.
abstract final class BotDefence {
  static void decide(
    TeamView v,
    Disc c,
    Intent i,
    BotLevel level,
    Rng rng,
  ) {
    final carrier = v.carrier;
    double tx;
    double ty;
    var dash = false;
    if (carrier != null && !v.weHaveBall) {
      var gx = v.worldX(-v.halfL) - carrier.pos.x;
      var gy = -carrier.pos.y;
      final gl = math.sqrt(gx * gx + gy * gy);
      if (gl > 1e-6) {
        gx /= gl;
        gy /= gl;
      }
      final plan = v.team.plan;
      final pressFrom = (-0.45 + 1.35 * plan.pressIntensity) * v.halfL;
      final press = v.ballX <= pressFrom || carrier.pos.distTo(c.pos) < 6.0;
      final standOff = press ? 1.0 : 6.0;
      tx = carrier.pos.x + gx * standOff;
      ty = carrier.pos.y + gy * standOff;
      dash = press;
      final close = carrier.pos.distTo(c.pos) < T.tackleRange * 0.95;
      if (close && rng.chance(level.tacklePerSecond * level.thinkInterval)) {
        i.action = ActionKind.tackle;
      }
    } else {
      final b = v.s.ball;
      tx = b.pos.x + b.vel.x * 0.3;
      ty = b.pos.y + b.vel.y * 0.3;
      dash = true;
    }
    final dx = tx - c.pos.x;
    final dy = ty - c.pos.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.3) {
      i.moveX = 0.0;
      i.moveY = 0.0;
      i.dash = false;
      return;
    }
    final amount = math.min(1.0, dist / 2.0);
    i.moveX = dx / dist * amount;
    i.moveY = dy / dist * amount;
    i.dash = dash && dist > 3.0;
  }
}
