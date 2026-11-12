import 'package:flutter/foundation.dart';

import 'package:b_ball/tiki_counter/model/match_event.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/side.dart';

/// What the Flutter HUD shows. Immutable; compared by value so widgets
/// only rebuild when something visible changed (not 60 times a second).
@immutable
class HudSnapshot {
  final int homeScore;
  final int awayScore;
  final int clockSeconds;
  final MatchPhase phase;

  /// True when the home (player's) team has the ball: shows attack buttons.
  final bool homeAttacking;

  const HudSnapshot({
    required this.homeScore,
    required this.awayScore,
    required this.clockSeconds,
    required this.phase,
    required this.homeAttacking,
  });

  static const HudSnapshot initial = HudSnapshot(
    homeScore: 0,
    awayScore: 0,
    clockSeconds: 0,
    phase: MatchPhase.firstHalf,
    homeAttacking: true,
  );

  @override
  bool operator ==(Object other) =>
      other is HudSnapshot &&
      other.homeScore == homeScore &&
      other.awayScore == awayScore &&
      other.clockSeconds == clockSeconds &&
      other.phase == phase &&
      other.homeAttacking == homeAttacking;

  @override
  int get hashCode =>
      Object.hash(homeScore, awayScore, clockSeconds, phase, homeAttacking);
}

/// A short call-out ("GOAL!", "OFFSIDE"). [serial] changes every time so the
/// banner replays even for the same text twice in a row.
@immutable
class HudBanner {
  final String text;
  final int serial;

  const HudBanner(this.text, this.serial);
}

/// Bridge from the game loop to Flutter widgets.
class HudModel {
  final ValueNotifier<HudSnapshot> snapshot =
      ValueNotifier<HudSnapshot>(HudSnapshot.initial);
  final ValueNotifier<HudBanner?> banner = ValueNotifier<HudBanner?>(null);
  int _serial = 0;

  /// Called every frame; only creates a new snapshot when something changed.
  void refresh(MatchState s) {
    final cur = snapshot.value;
    final clock = s.clock.floor();
    final attacking = s.possessionSide != Side.away;
    if (cur.homeScore == s.home.score &&
        cur.awayScore == s.away.score &&
        cur.clockSeconds == clock &&
        cur.phase == s.phase &&
        cur.homeAttacking == attacking) {
      return;
    }
    snapshot.value = HudSnapshot(
      homeScore: s.home.score,
      awayScore: s.away.score,
      clockSeconds: clock,
      phase: s.phase,
      homeAttacking: attacking,
    );
  }

  void onEvents(List<MatchEvent> events) {
    for (final e in events) {
      final text = _textFor(e.kind);
      if (text != null) banner.value = HudBanner(text, ++_serial);
    }
  }

  String? _textFor(MatchEventKind k) => switch (k) {
    MatchEventKind.goal => 'GOAL!',
    MatchEventKind.offside => 'OFFSIDE',
    MatchEventKind.throwIn => 'THROW-IN',
    MatchEventKind.corner => 'CORNER',
    MatchEventKind.goalKick => 'GOAL KICK',
    MatchEventKind.freeKick => 'FREE KICK',
    MatchEventKind.save => 'SAVE!',
    _ => null,
  };

  void dispose() {
    snapshot.dispose();
    banner.dispose();
  }
}
