import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';

/// The four phases of play, from one team's point of view.
enum Phase {
  attacking,

  /// Just won the ball (first few seconds).
  attackTransition,

  defending,

  /// Just lost the ball (first few seconds).
  defenceTransition,
}

/// Remembers who had the ball and since when, to tell a transition from a
/// settled phase.
class PhaseTracker {
  final Side side;
  Side? _lastOwner;
  double _since = 99.0;

  PhaseTracker(this.side);

  /// Seconds since possession last changed hands.
  double get since => _since;

  Phase update(MatchState s, double dt) {
    _since += dt;
    final now = s.possessionSide;
    if (now != null && now != _lastOwner) {
      _lastOwner = now;
      _since = 0.0;
    }
    final ours = _lastOwner == side;
    final fresh = _since < T.transitionSeconds;
    if (ours) return fresh ? Phase.attackTransition : Phase.attacking;
    return fresh ? Phase.defenceTransition : Phase.defending;
  }
}
