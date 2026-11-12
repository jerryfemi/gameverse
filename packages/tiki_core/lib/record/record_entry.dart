import 'package:tiki_core/model/match_state.dart';

enum MatchResult { win, draw, loss }

/// One finished match vs the bot, as the club record keeps it. Plain data
/// so it can be saved as JSON (on the device now, Firestore later).
class RecordEntry {
  /// When the match ended (milliseconds since 1970, UTC).
  final int playedAt;
  final String mode;
  final String botLevel;
  final String playstyle;
  final String formation;
  final String opponentName;
  final String opponentCode;
  final int goalsFor;
  final int goalsAgainst;

  /// 0..100.
  final int possession;
  final int passAccuracy;
  final int shots;
  final int patternRuns;

  const RecordEntry({
    required this.playedAt,
    required this.mode,
    required this.botLevel,
    required this.playstyle,
    required this.formation,
    required this.opponentName,
    required this.opponentCode,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.possession,
    required this.passAccuracy,
    required this.shots,
    required this.patternRuns,
  });

  MatchResult get result => goalsFor > goalsAgainst
      ? MatchResult.win
      : (goalsFor < goalsAgainst ? MatchResult.loss : MatchResult.draw);

  /// Reads a finished match. Home is always "you".
  factory RecordEntry.fromMatch(
    MatchState s, {
    required String botLevel,
    required int playedAt,
  }) {
    final h = s.home.stats;
    final a = s.away.stats;
    final total = h.possessionSeconds + a.possessionSeconds;
    return RecordEntry(
      playedAt: playedAt,
      mode: s.mode.label,
      botLevel: botLevel,
      playstyle: s.home.plan.name,
      formation: s.home.formation.name,
      opponentName: s.away.name,
      opponentCode: s.away.code,
      goalsFor: s.home.score,
      goalsAgainst: s.away.score,
      possession: total <= 0 ? 50 : (h.possessionSeconds * 100 / total).round(),
      passAccuracy: h.passAccuracy(),
      shots: h.shots,
      patternRuns: h.patternRuns,
    );
  }

  Map<String, Object> toJson() => {
    'at': playedAt,
    'mode': mode,
    'level': botLevel,
    'style': playstyle,
    'formation': formation,
    'oppName': opponentName,
    'oppCode': opponentCode,
    'gf': goalsFor,
    'ga': goalsAgainst,
    'poss': possession,
    'pass': passAccuracy,
    'shots': shots,
    'patterns': patternRuns,
  };

  factory RecordEntry.fromJson(Map<String, Object?> j) {
    int i(String k) => j[k] is num ? (j[k]! as num).toInt() : 0;
    String t(String k) => j[k] is String ? j[k]! as String : '';
    return RecordEntry(
      playedAt: i('at'),
      mode: t('mode'),
      botLevel: t('level'),
      playstyle: t('style'),
      formation: t('formation'),
      opponentName: t('oppName'),
      opponentCode: t('oppCode'),
      goalsFor: i('gf'),
      goalsAgainst: i('ga'),
      possession: i('poss'),
      passAccuracy: i('pass'),
      shots: i('shots'),
      patternRuns: i('patterns'),
    );
  }
}
