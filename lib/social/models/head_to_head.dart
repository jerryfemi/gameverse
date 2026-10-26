import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/models/match_summary.dart';

/// Single-sport head-to-head breakdown (e.g. Darts, Hoops, Archery).
class GameH2H {
  final int myWins;
  final int theirWins;
  final int draws;

  const GameH2H({
    this.myWins = 0,
    this.theirWins = 0,
    this.draws = 0,
  });

  int get total => myWins + theirWins + draws;
}

/// Comprehensive head-to-head record between the active player and an opponent.
///
/// Implements GameVerse Social Section 6:
/// - Aggregated win/loss/draw totals and single-sport game breakdowns.
/// - Chronological last-5 match outcomes (W / L / D).
/// - Dynamic streak calculation and lead narrative generation.
/// - Full list of [MatchSummary] items for detailed match exploration.
class HeadToHead {
  final String myUid;
  final String opponentUid;
  final int myWins;
  final int theirWins;
  final int draws;
  final Map<String, GameH2H> byGame;
  final List<bool?> lastFive; // true = win, false = loss, null = draw (newest first)
  final int currentStreak; // +n = won last n, -n = lost last n, 0 = tie or no streak
  final String leadSummary;
  final String recordLine;
  final List<MatchSummary> matches; // Chronological (newest first)

  const HeadToHead({
    required this.myUid,
    required this.opponentUid,
    required this.myWins,
    required this.theirWins,
    required this.draws,
    required this.byGame,
    required this.lastFive,
    required this.currentStreak,
    required this.leadSummary,
    required this.recordLine,
    required this.matches,
  });

  int get totalMatches => myWins + theirWins + draws;

  /// Builds a [HeadToHead] profile from a list of finished [CloudMatch] items.
  factory HeadToHead.fromMatches({
    required String myUid,
    required String opponentUid,
    required List<CloudMatch> allMatches,
  }) {
    final relevantMatches = allMatches.where((m) {
      if (!m.isFinished) return false;
      return m.playerIds.contains(myUid) && m.playerIds.contains(opponentUid);
    }).toList()
      ..sort((a, b) {
        final aTime = a.updatedAt > 0 ? a.updatedAt : a.createdAt;
        final bTime = b.updatedAt > 0 ? b.updatedAt : b.createdAt;
        return bTime.compareTo(aTime); // Newest first
      });

    int myWins = 0;
    int theirWins = 0;
    int draws = 0;

    final byGameWins = <String, int>{};
    final byGameLosses = <String, int>{};
    final byGameDraws = <String, int>{};

    final summaries = <MatchSummary>[];
    final lastFive = <bool?>[];

    int currentStreak = 0;
    bool? streakType; // true = win streak, false = loss streak

    for (int i = 0; i < relevantMatches.length; i++) {
      final m = relevantMatches[i];
      final summary = MatchSummary.fromMatch(m, myUid);
      summaries.add(summary);

      final didWin = summary.didIWin;
      final g = m.game.toLowerCase().trim();

      if (didWin == true) {
        myWins++;
        byGameWins[g] = (byGameWins[g] ?? 0) + 1;
      } else if (didWin == false) {
        theirWins++;
        byGameLosses[g] = (byGameLosses[g] ?? 0) + 1;
      } else {
        draws++;
        byGameDraws[g] = (byGameDraws[g] ?? 0) + 1;
      }

      if (lastFive.length < 5) {
        lastFive.add(didWin);
      }

      // Calculate active streak based on consecutive recent matches
      if (streakType == null && didWin != null) {
        streakType = didWin;
        currentStreak = didWin ? 1 : -1;
      } else if (streakType != null) {
        if (didWin == streakType) {
          currentStreak += (streakType ? 1 : -1);
        } else {
          // Streak broken
          streakType = null;
        }
      }
    }

    // Build byGame map
    final allGames = {...byGameWins.keys, ...byGameLosses.keys, ...byGameDraws.keys};
    final byGame = <String, GameH2H>{};
    for (final g in allGames) {
      byGame[g] = GameH2H(
        myWins: byGameWins[g] ?? 0,
        theirWins: byGameLosses[g] ?? 0,
        draws: byGameDraws[g] ?? 0,
      );
    }

    // Lead summary string: e.g. "You lead · won last 2"
    final String leadSummary;
    if (myWins > theirWins) {
      final streakSuffix = currentStreak > 1 ? ' · won last $currentStreak' : '';
      leadSummary = 'You lead$streakSuffix';
    } else if (theirWins > myWins) {
      final streakSuffix = currentStreak < -1 ? ' · won last ${-currentStreak}' : '';
      leadSummary = 'They lead$streakSuffix';
    } else {
      final total = myWins + theirWins + draws;
      leadSummary = total == 0 ? 'No matches yet' : 'Level $myWins–$theirWins';
    }

    // Record line string: e.g. "You lead 7–4" or "Level 2–2"
    final String recordLine;
    if (myWins > theirWins) {
      recordLine = 'You lead $myWins – $theirWins';
    } else if (theirWins > myWins) {
      recordLine = 'They lead $myWins – $theirWins';
    } else {
      recordLine = 'Level $myWins – $theirWins';
    }

    return HeadToHead(
      myUid: myUid,
      opponentUid: opponentUid,
      myWins: myWins,
      theirWins: theirWins,
      draws: draws,
      byGame: byGame,
      lastFive: lastFive,
      currentStreak: currentStreak,
      leadSummary: leadSummary,
      recordLine: recordLine,
      matches: summaries,
    );
  }
}
