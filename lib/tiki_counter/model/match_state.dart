import 'package:b_ball/tiki_counter/model/ball.dart';
import 'package:b_ball/tiki_counter/model/disc.dart';
import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/model/match_event.dart';
import 'package:b_ball/tiki_counter/model/set_piece.dart';
import 'package:b_ball/tiki_counter/model/side.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';

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
