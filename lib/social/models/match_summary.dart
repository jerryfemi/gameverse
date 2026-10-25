import '../../../archery/state/archery_rules.dart';
import '../../../darts/state/darts_rules.dart';
import '../../../models/cloud_match.dart';

/// Single player score recap inside [MatchSummary].
class PlayerSummary {
  final String uid;
  final String name;
  final String avatar;
  final String headline;
  final String unit;
  final int rawScore;

  const PlayerSummary({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.headline,
    required this.unit,
    required this.rawScore,
  });
}

/// Game-agnostic summary of a finished [CloudMatch] tailored for display
/// in completed match cards and the results sheet.
class MatchSummary {
  final String matchId;
  final String game;
  final int finishedAt;
  final PlayerSummary me;
  final PlayerSummary opponent;
  final bool? didIWin; // true = win, false = loss, null = draw
  final bool byForfeit;
  final String verdictLine;
  final String heroHeadline;

  const MatchSummary({
    required this.matchId,
    required this.game,
    required this.finishedAt,
    required this.me,
    required this.opponent,
    required this.didIWin,
    required this.byForfeit,
    required this.verdictLine,
    required this.heroHeadline,
  });

  /// Factory constructing a [MatchSummary] from a canonical [CloudMatch] and viewer's [myUid].
  factory MatchSummary.fromMatch(CloudMatch match, String myUid) {
    final myPlayer = match.myPlayer(myUid);
    final oppPlayer = match.opponentPlayer(myUid);

    final String myName = myPlayer?.displayName ?? 'You';
    final String myAvatar = myPlayer?.avatarEmoji ?? '👤';
    final String oppName = oppPlayer?.displayName ?? 'Opponent';
    final String oppAvatar = oppPlayer?.avatarEmoji ?? '⏳';

    final outcome = match.outcome;
    final bool? didIWin;
    if (outcome == MatchOutcome.player1Won) {
      didIWin = match.player1.uid == myUid;
    } else if (outcome == MatchOutcome.player2Won) {
      didIWin = match.player2?.uid == myUid;
    } else if (outcome == MatchOutcome.tie) {
      didIWin = null;
    } else {
      didIWin = null;
    }

    final bool byForfeit = match.status == MatchStatus.forfeited ||
        match.forfeitedByUid != null && match.forfeitedByUid!.isNotEmpty;

    final myScores = myPlayer?.roundScores ?? const <int>[];
    final oppScores = oppPlayer?.roundScores ?? const <int>[];

    String myHeadline = '';
    String myUnit = '';
    String theirHeadline = '';
    String theirUnit = '';
    int myRawScore = 0;
    int oppRawScore = 0;
    String verdict = '';

    if (match.isDarts) {
      final myRemaining = DartsRules.remaining(myScores);
      final oppRemaining = DartsRules.remaining(oppScores);
      myRawScore = myRemaining;
      oppRawScore = oppRemaining;

      final myCheckout = myRemaining == 0;
      final oppCheckout = oppRemaining == 0;

      // 1. Headline & Unit (CRITICAL: never produce a bare "0")
      if (myCheckout) {
        myHeadline = 'Checked out';
        myUnit = '0 points left';
      } else {
        myHeadline = '$myRemaining left';
        myUnit = 'points left';
      }

      if (oppCheckout) {
        theirHeadline = 'Checked out';
        theirUnit = '0 points left';
      } else {
        theirHeadline = '$oppRemaining left';
        theirUnit = 'points left';
      }

      // 2. Verdict Sentence
      if (byForfeit) {
        if (match.forfeitedByUid == myUid) {
          verdict = 'You left the match';
        } else {
          verdict = '$oppName left the match';
        }
      } else if (didIWin == true) {
        if (myCheckout) {
          final checkoutRound = myScores.length;
          verdict = 'You checked out in round $checkoutRound';
        } else {
          verdict = 'You won on round cap · $myRemaining to $oppRemaining left';
        }
      } else if (didIWin == false) {
        if (oppCheckout) {
          if (myRemaining > 0) {
            verdict = '$oppName checked out · you had $myRemaining left';
          } else {
            final checkoutRound = oppScores.length;
            verdict = '$oppName checked out in round $checkoutRound';
          }
        } else {
          verdict = '$oppName won on round cap';
        }
      } else {
        verdict = 'Match tied at $myRemaining points left';
      }
    } else if (match.isArchery) {
      final isP1Me = match.player1.uid == myUid;
      final p1Scores = match.player1.roundScores;
      final p2Scores = match.player2?.roundScores ?? const <int>[];
      final sp = ArcheryRules.setPoints(p1Scores, p2Scores);

      final mySets = isP1Me ? sp.you : sp.them;
      final oppSets = isP1Me ? sp.them : sp.you;
      myRawScore = mySets;
      oppRawScore = oppSets;

      myHeadline = '$mySets sets';
      myUnit = 'set points';
      theirHeadline = '$oppSets sets';
      theirUnit = 'set points';

      if (byForfeit) {
        if (match.forfeitedByUid == myUid) {
          verdict = 'You left the match';
        } else {
          verdict = '$oppName left the match';
        }
      } else if (didIWin == true) {
        if (mySets >= ArcheryRules.pointsToWin) {
          verdict = 'You reached 6 set points';
        } else {
          final diff = mySets - oppSets;
          verdict = 'You won by $diff ${diff == 1 ? "set point" : "set points"}';
        }
      } else if (didIWin == false) {
        if (oppSets >= ArcheryRules.pointsToWin) {
          verdict = '$oppName reached 6 set points';
        } else {
          final diff = oppSets - mySets;
          verdict = '$oppName won by $diff ${diff == 1 ? "set point" : "set points"}';
        }
      } else {
        verdict = 'Tied at $mySets set points';
      }
    } else {
      // Default to Hoops / Basketball
      final myTotal = myPlayer?.totalScore ?? 0;
      final oppTotal = oppPlayer?.totalScore ?? 0;
      myRawScore = myTotal;
      oppRawScore = oppTotal;

      myHeadline = '$myTotal pts';
      theirHeadline = '$oppTotal pts';

      final roundsCount = match.totalRounds > 0
          ? match.totalRounds
          : (myScores.isNotEmpty ? myScores.length : 1);
      final roundsText = '$roundsCount ${roundsCount == 1 ? "round" : "rounds"}';
      myUnit = roundsText;
      theirUnit = roundsText;

      if (byForfeit) {
        if (match.forfeitedByUid == myUid) {
          verdict = 'You left the match';
        } else {
          verdict = '$oppName left the match';
        }
      } else if (didIWin == true) {
        final diff = myTotal - oppTotal;
        verdict = 'You won by $diff ${diff == 1 ? "point" : "points"}';
      } else if (didIWin == false) {
        final diff = oppTotal - myTotal;
        verdict = '$oppName won by $diff ${diff == 1 ? "point" : "points"}';
      } else {
        verdict = 'Tied at $myTotal points';
      }
    }

    final finishedAt = match.updatedAt > 0 ? match.updatedAt : match.createdAt;
    final heroHeadline = didIWin == true
        ? 'YOU WON'
        : (didIWin == false ? 'YOU LOST' : 'DRAW');

    return MatchSummary(
      matchId: match.id,
      game: match.game,
      finishedAt: finishedAt,
      me: PlayerSummary(
        uid: myUid,
        name: myName,
        avatar: myAvatar,
        headline: myHeadline,
        unit: myUnit,
        rawScore: myRawScore,
      ),
      opponent: PlayerSummary(
        uid: oppPlayer?.uid ?? '',
        name: oppName,
        avatar: oppAvatar,
        headline: theirHeadline,
        unit: theirUnit,
        rawScore: oppRawScore,
      ),
      didIWin: didIWin,
      byForfeit: byForfeit,
      verdictLine: verdict,
      heroHeadline: heroHeadline,
    );
  }
}
