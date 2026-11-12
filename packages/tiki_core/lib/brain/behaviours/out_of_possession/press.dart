import 'dart:math' as math;

import 'package:tiki_core/brain/behaviours/behaviour.dart';
import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Pressing, for the discs the team picked (`DefenceAssigner`):
/// 1st presser closes down goal-side, 2nd blocks the easiest pass,
/// 3rd (counter-press only) squeezes in too.
class Press implements Behaviour {
  @override
  BehaviourKind get kind => BehaviourKind.press;

  @override
  Candidate? propose(DiscContext c) {
    final i = c.a.pressers.indexOf(c.d.id);
    final carrier = c.v.carrier;
    if (i < 0 || carrier == null) return null;
    final v = c.v;
    final fresh = v.phase == Phase.defenceTransition;

    // Direction from the carrier toward our goal.
    var gx = v.worldX(-v.halfL) - carrier.pos.x;
    var gy = -carrier.pos.y;
    final gl = math.sqrt(gx * gx + gy * gy);
    if (gl > 1e-6) {
      gx /= gl;
      gy /= gl;
    }

    if (i == 0) {
      return _go(carrier.pos.x + gx, carrier.pos.y + gy, 4.0,
          fresh ? 'counter-press' : 'press');
    }
    if (i == 1) {
      final r = _easiestPass(c, carrier);
      if (r != null) {
        return _go(
          carrier.pos.x + (r.pos.x - carrier.pos.x) * 0.35,
          carrier.pos.y + (r.pos.y - carrier.pos.y) * 0.35,
          3.6,
          'second presser',
        );
      }
    }
    return _go(carrier.pos.x + gx * 2.0, carrier.pos.y + gy * 2.0, 3.4,
        'counter-press');
  }

  Candidate _go(double x, double y, double score, String job) => Candidate(
    kind: kind,
    x: x,
    y: y,
    urgency: 1.4,
    score: score,
    job: job,
  );

  /// The carrier's nearest teammate with an open lane.
  Disc? _easiestPass(DiscContext c, Disc carrier) {
    Disc? best;
    var bestD = double.infinity;
    for (final o in c.v.opp.discs) {
      if (o.id == carrier.id || o.isKeeper) continue;
      final d = o.pos.distTo(carrier.pos);
      if (d < bestD) {
        bestD = d;
        best = o;
      }
    }
    return best;
  }
}
