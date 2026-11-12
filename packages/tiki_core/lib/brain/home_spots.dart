import 'package:tiki_core/core/geometry.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/team_state.dart';

/// Each disc's "home": its formation spot, slid toward the ball.
///
/// This is the base layer that keeps the shape: nobody stands still and
/// nobody swarms. **Simple version for milestones 0–3**; milestone 4 adds
/// line height, compactness and per-formation shapes in/out of possession.
abstract final class HomeSpots {
  static void place(MatchState s, TeamState team, Disc d, bool attacking) {
    final spot = team.formation.spots[d.slot];
    final m = s.mode;
    final dir = team.side.attackDir;

    // Work in team coordinates (+ = toward the goal we attack).
    final ballX = s.ball.pos.x * dir;
    var x = spot.x * m.halfLength * 0.75 +
        ballX * 0.45 +
        (attacking ? 0.12 : -0.08) * m.halfLength;
    x = clampD(x, -m.halfLength * 0.85, m.halfLength * 0.80);

    // Wider with the ball, narrower without it; drift toward the ball side.
    final width = attacking ? 0.85 : 0.65;
    var y = spot.y * m.halfWidth * width + s.ball.pos.y * 0.25;
    y = clampD(y, -m.halfWidth * 0.92, m.halfWidth * 0.92);

    d.target.set(x * dir, y);
    d.urgency = d.pos.distTo(d.target) > 8.0 ? 1.0 : 0.65;
    d.job = attacking ? 'shape (attack)' : 'shape (defend)';
  }
}
