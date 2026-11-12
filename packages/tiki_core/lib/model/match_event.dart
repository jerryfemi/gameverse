import 'package:tiki_core/model/side.dart';

enum MatchEventKind {
  pass,
  shot,
  goal,
  interception,
  save,
  tackleWon,
  tackleLoose,
  tackleMiss,
  offside,
  throwIn,
  corner,
  goalKick,
  freeKick,
  kickOff,
  halfTime,
  fullTime,
}

/// Something that happened this tick. The UI and (later) audio read these;
/// the sim clears the list at the start of every step.
class MatchEvent {
  final MatchEventKind kind;
  final Side side;
  final int discId;

  const MatchEvent(this.kind, this.side, [this.discId = -1]);

  @override
  String toString() => '${kind.name}(${side.name}, $discId)';
}
