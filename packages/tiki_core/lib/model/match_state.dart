import 'package:tiki_core/model/ball.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/match_event.dart';
import 'package:tiki_core/model/set_piece.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/model/team_state.dart';

enum MatchPhase { firstHalf, halfTime, secondHalf, fullTime }

/// The whole truth of a match. The sim changes it; everything else reads it.
class MatchState {
  final GameMode mode;
  final TeamState home;
  final TeamState away;

  /// All discs, indexed by `Disc.id` (home first, then away).
  final List<Disc> discs;

  final Ball ball = Ball();

  MatchPhase phase = MatchPhase.firstHalf;

  /// Ends swap at half-time: true in the first half.
  bool homeAttacksRight = true;

  /// Seconds played (0 → 420).
  double clock = 0.0;

  /// Restart in progress (taker on the spot), or null in open play.
  SetPiece? setPiece;

  /// Restart about to begin, or null.
  PendingRestart? pending;

  /// Things that happened during the last step.
  final List<MatchEvent> events = <MatchEvent>[];

  MatchState({
    required this.mode,
    required this.home,
    required this.away,
    required this.discs,
  });

  TeamState team(Side side) => side == Side.home ? home : away;

  /// +1 if [side] attacks toward +x (right) in this half, −1 if toward −x.
  /// Multiply an x by this to get "how far forward" it is for that team.
  double dir(Side side) =>
      (side == Side.home) == homeAttacksRight ? 1.0 : -1.0;

  Disc? get owner => ball.ownerId >= 0 ? discs[ball.ownerId] : null;

  /// The side in possession: the carrier's team, or whoever touched it last
  /// while it travels. Null before the first touch.
  Side? get possessionSide {
    final o = owner;
    if (o != null) return o.side;
    return ball.lastTouchSide;
  }

  bool get isPlaying =>
      phase == MatchPhase.firstHalf || phase == MatchPhase.secondHalf;

  /// Play is stopped while a restart is pending.
  bool get isFrozen => pending != null;

  void emit(MatchEventKind kind, Side side, [int discId = -1]) {
    events.add(MatchEvent(kind, side, discId));
  }
}
