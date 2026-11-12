import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/match_event.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/side.dart';

/// 7-minute match, half-time at 3:30. The clock keeps running through
/// restarts (no stoppage time).
class Clock {
  void tick(MatchState s, double dt) {
    if (!s.isPlaying) return;
    s.clock += dt;
    const half = T.matchSeconds / 2.0;
    if (s.phase == MatchPhase.firstHalf && s.clock >= half) {
      s.clock = half;
      s.phase = MatchPhase.halfTime;
      s.emit(MatchEventKind.halfTime, Side.home);
    } else if (s.phase == MatchPhase.secondHalf && s.clock >= T.matchSeconds) {
      s.clock = T.matchSeconds;
      s.phase = MatchPhase.fullTime;
      s.emit(MatchEventKind.fullTime, Side.home);
    }
  }
}
