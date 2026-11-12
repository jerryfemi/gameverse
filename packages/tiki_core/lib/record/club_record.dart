import 'package:tiki_core/record/record_entry.dart';

/// Wins, draws and losses for one group (a bot level, a playstyle, …).
class WdL {
  int won = 0;
  int drawn = 0;
  int lost = 0;

  WdL();

  int get played => won + drawn + lost;

  /// 0..100, draws count as half a win. 0 when nothing played.
  int get winRate => played == 0 ? 0 : ((won + drawn * 0.5) * 100 / played).round();

  void add(MatchResult r) {
    switch (r) {
      case MatchResult.win:
        won++;
      case MatchResult.draw:
        drawn++;
      case MatchResult.loss:
        lost++;
    }
  }

  List<int> toJson() => [won, drawn, lost];

  static WdL fromJson(Object? j) {
    final w = WdL();
    if (j is List && j.length == 3) {
      w.won = (j[0] as num).toInt();
      w.drawn = (j[1] as num).toInt();
      w.lost = (j[2] as num).toInt();
    }
    return w;
  }
}

/// Your club's record against the bot: totals, records, splits by bot
/// level / playstyle / formation, and the last few results. Matches you
/// only watched are never added.
class ClubRecord {
  static const int keepRecent = 10;

  final WdL total = WdL();
  int goalsFor = 0;
  int goalsAgainst = 0;
  int cleanSheets = 0;
  int patternRuns = 0;
  int _passAccuracySum = 0;
  int _possessionSum = 0;

  /// Current and longest run without a defeat.
  int unbeatenNow = 0;
  int unbeatenBest = 0;

  /// Biggest winning margin so far (null until the first win).
  RecordEntry? bestWin;

  final Map<String, WdL> byLevel = {};
  final Map<String, WdL> byPlaystyle = {};
  final Map<String, WdL> byFormation = {};

  /// Newest first, at most [keepRecent].
  final List<RecordEntry> recent = [];

  ClubRecord();

  int get averagePassAccuracy =>
      total.played == 0 ? 0 : (_passAccuracySum / total.played).round();
  int get averagePossession =>
      total.played == 0 ? 0 : (_possessionSum / total.played).round();

  void add(RecordEntry e) {
    final r = e.result;
    total.add(r);
    goalsFor += e.goalsFor;
    goalsAgainst += e.goalsAgainst;
    if (e.goalsAgainst == 0) cleanSheets++;
    patternRuns += e.patternRuns;
    _passAccuracySum += e.passAccuracy;
    _possessionSum += e.possession;
    if (r == MatchResult.loss) {
      unbeatenNow = 0;
    } else {
      unbeatenNow++;
      if (unbeatenNow > unbeatenBest) unbeatenBest = unbeatenNow;
    }
    if (r == MatchResult.win) {
      final best = bestWin;
      final margin = e.goalsFor - e.goalsAgainst;
      if (best == null ||
          margin > best.goalsFor - best.goalsAgainst ||
          (margin == best.goalsFor - best.goalsAgainst &&
              e.goalsFor > best.goalsFor)) {
        bestWin = e;
      }
    }
    byLevel.putIfAbsent(e.botLevel, WdL.new).add(r);
    byPlaystyle.putIfAbsent(e.playstyle, WdL.new).add(r);
    byFormation.putIfAbsent('${e.mode} ${e.formation}', WdL.new).add(r);
    recent.insert(0, e);
    if (recent.length > keepRecent) recent.removeLast();
  }

  /// The playstyle with the best win rate after at least [minGames].
  MapEntry<String, WdL>? bestPlaystyle({int minGames = 3}) {
    MapEntry<String, WdL>? best;
    for (final e in byPlaystyle.entries) {
      if (e.value.played < minGames) continue;
      if (best == null || e.value.winRate > best.value.winRate) best = e;
    }
    return best;
  }

  Map<String, Object?> toJson() => {
    'total': total.toJson(),
    'gf': goalsFor,
    'ga': goalsAgainst,
    'clean': cleanSheets,
    'patterns': patternRuns,
    'passSum': _passAccuracySum,
    'possSum': _possessionSum,
    'unbeatenNow': unbeatenNow,
    'unbeatenBest': unbeatenBest,
    'bestWin': bestWin?.toJson(),
    'byLevel': {for (final e in byLevel.entries) e.key: e.value.toJson()},
    'byStyle': {for (final e in byPlaystyle.entries) e.key: e.value.toJson()},
    'byFormation': {for (final e in byFormation.entries) e.key: e.value.toJson()},
    'recent': [for (final e in recent) e.toJson()],
  };

  /// Reads [toJson]; anything missing starts at zero, so old saves load.
  factory ClubRecord.fromJson(Map<String, Object?> j) {
    int i(String k) => j[k] is num ? (j[k]! as num).toInt() : 0;
    void fill(Map<String, WdL> into, Object? m) {
      if (m is! Map) return;
      m.forEach((k, v) => into['$k'] = WdL.fromJson(v));
    }

    final c = ClubRecord();
    final t = WdL.fromJson(j['total']);
    c.total
      ..won = t.won
      ..drawn = t.drawn
      ..lost = t.lost;
    c.goalsFor = i('gf');
    c.goalsAgainst = i('ga');
    c.cleanSheets = i('clean');
    c.patternRuns = i('patterns');
    c._passAccuracySum = i('passSum');
    c._possessionSum = i('possSum');
    c.unbeatenNow = i('unbeatenNow');
    c.unbeatenBest = i('unbeatenBest');
    final bw = j['bestWin'];
    if (bw is Map<String, Object?>) c.bestWin = RecordEntry.fromJson(bw);
    fill(c.byLevel, j['byLevel']);
    fill(c.byPlaystyle, j['byStyle']);
    fill(c.byFormation, j['byFormation']);
    final rec = j['recent'];
    if (rec is List) {
      for (final e in rec) {
        if (e is Map<String, Object?>) c.recent.add(RecordEntry.fromJson(e));
      }
    }
    return c;
  }
}
