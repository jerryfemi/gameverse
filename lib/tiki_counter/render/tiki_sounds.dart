import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/match_event.dart';
import 'package:tiki_core/model/match_state.dart';

/// Turns match events into sounds. Runs after every sim step; the sim
/// itself never knows audio exists.
class TikiSounds {
  void onEvents(MatchState s) {
    for (final e in s.events) {
      switch (e.kind) {
        case MatchEventKind.pass:
          AudioEngine.playTikiKick(s.ball.speed / T.passMaxSpeed);
        case MatchEventKind.shot:
          AudioEngine.playTikiKick(
            0.6 + 0.4 * s.ball.speed / (T.shootSpeedBase + T.shootSpeedPower),
          );
        case MatchEventKind.goal:
          AudioEngine.playTikiNet();
          AudioEngine.playTikiWhistle();
        case MatchEventKind.offside:
        case MatchEventKind.throwIn:
        case MatchEventKind.corner:
        case MatchEventKind.goalKick:
        case MatchEventKind.freeKick:
        case MatchEventKind.kickOff:
          AudioEngine.playTikiWhistle();
        case MatchEventKind.halfTime:
        case MatchEventKind.fullTime:
          AudioEngine.playTikiWhistle(long: true);
        // No sound for these (the thud was dropped after the playtest).
        case MatchEventKind.save:
        case MatchEventKind.tackleWon:
        case MatchEventKind.tackleLoose:
        case MatchEventKind.interception:
        case MatchEventKind.tackleMiss:
          break;
      }
    }
  }
}
