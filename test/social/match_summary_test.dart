import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatchSummary Tests', () {
    const String myUid = 'user_123';
    const String oppUid = 'user_opp';

    CloudPlayer createPlayer({
      required String uid,
      required String name,
      required List<int> scores,
      List<RoundSummaryStats> summaries = const [],
    }) {
      return CloudPlayer(
        uid: uid,
        displayName: name,
        avatarEmoji: '🏀',
        roundScores: scores,
        roundSummaries: summaries,
      );
    }

    CloudMatch createMatch({
      required String game,
      required CloudPlayer p1,
      required CloudPlayer p2,
      MatchStatus status = MatchStatus.completed,
      String? forfeitedByUid,
    }) {
      return CloudMatch(
        id: 'match_test_1',
        joinCode: 'TEST01',
        game: game,
        status: status,
        createdAt: 1000,
        updatedAt: 2000,
        playerIds: [p1.uid, p2.uid],
        player1: p1,
        player2: p2,
        totalRounds: 5,
        roundDurationSeconds: 30,
        activeTurnPlayerUid: p1.uid,
        currentRound: 5,
        forfeitedByUid: forfeitedByUid,
      );
    }

    group('Darts 301', () {
      test('Win by Checkout produces "Checked out" and never bare "0"', () {
        // 301 total: 60 + 60 + 60 + 60 + 61 = 301 in 5 rounds.
        final p1 = createPlayer(
          uid: myUid,
          name: 'Player',
          scores: [60, 60, 60, 60, 61],
        );
        // Opponent scored 296 total -> 5 remaining
        final p2 = createPlayer(
          uid: oppUid,
          name: 'Boogyman',
          scores: [60, 60, 60, 60, 56],
        );

        final match = createMatch(game: 'darts', p1: p1, p2: p2);
        final summary = MatchSummary.fromMatch(match, myUid);

        expect(summary.didIWin, isTrue);
        expect(summary.byForfeit, isFalse);
        expect(summary.verdictLine, equals('You checked out in round 5'));
        expect(summary.me.headline, equals('Checked out'));
        expect(summary.me.unit, equals('0 points left'));
        expect(summary.opponent.headline, equals('5 left'));
        expect(summary.opponent.unit, equals('points left'));

        // Strict assertion: neither headline can be a bare '0'
        expect(summary.me.headline, isNot(equals('0')));
        expect(summary.opponent.headline, isNot(equals('0')));
      });

      test(
        'Loss by Opponent Checkout displays remaining points and no bare "0"',
        () {
          // User scored 269 total -> 32 left
          final p1 = createPlayer(
            uid: myUid,
            name: 'Player',
            scores: [60, 60, 60, 60, 29],
          );
          // Opponent checked out (301 scored)
          final p2 = createPlayer(
            uid: oppUid,
            name: 'Boogyman',
            scores: [60, 60, 60, 60, 61],
          );

          final match = createMatch(game: 'darts', p1: p1, p2: p2);
          final summary = MatchSummary.fromMatch(match, myUid);

          expect(summary.didIWin, isFalse);
          expect(summary.byForfeit, isFalse);
          expect(
            summary.verdictLine,
            equals('Boogyman checked out · you had 32 left'),
          );
          expect(summary.me.headline, equals('32 left'));
          expect(summary.opponent.headline, equals('Checked out'));
          expect(summary.me.headline, isNot(equals('0')));
          expect(summary.opponent.headline, isNot(equals('0')));
        },
      );

      test('Forfeit in Darts correctly attributes left match', () {
        final p1 = createPlayer(uid: myUid, name: 'Player', scores: [60]);
        final p2 = createPlayer(uid: oppUid, name: 'Boogyman', scores: [40]);

        final match = createMatch(
          game: 'darts',
          p1: p1,
          p2: p2,
          status: MatchStatus.forfeited,
          forfeitedByUid: oppUid,
        );
        final summary = MatchSummary.fromMatch(match, myUid);

        expect(summary.didIWin, isTrue);
        expect(summary.byForfeit, isTrue);
        expect(summary.verdictLine, equals('Boogyman left the match'));
      });
    });

    group('Hoops / Basketball', () {
      test('Win by points displays point difference and total', () {
        final p1 = createPlayer(uid: myUid, name: 'Player', scores: [12, 12]);
        final p2 = createPlayer(uid: oppUid, name: 'Boogyman', scores: [10, 8]);

        final match = createMatch(game: 'basketball', p1: p1, p2: p2);
        final summary = MatchSummary.fromMatch(match, myUid);

        expect(summary.didIWin, isTrue);
        expect(summary.verdictLine, equals('You won by 6 points'));
        expect(summary.me.headline, equals('24 pts'));
        expect(summary.opponent.headline, equals('18 pts'));
      });

      test('Loss in Hoops displays opponent victory', () {
        final p1 = createPlayer(uid: myUid, name: 'Player', scores: [10, 8]);
        final p2 = createPlayer(
          uid: oppUid,
          name: 'Boogyman',
          scores: [12, 12],
        );

        final match = createMatch(game: 'basketball', p1: p1, p2: p2);
        final summary = MatchSummary.fromMatch(match, myUid);

        expect(summary.didIWin, isFalse);
        expect(summary.verdictLine, equals('Boogyman won by 6 points'));
        expect(summary.me.headline, equals('18 pts'));
        expect(summary.opponent.headline, equals('24 pts'));
      });

      test('Forfeit in Hoops by current user', () {
        final p1 = createPlayer(uid: myUid, name: 'Player', scores: [10]);
        final p2 = createPlayer(uid: oppUid, name: 'Boogyman', scores: [12]);

        final match = createMatch(
          game: 'basketball',
          p1: p1,
          p2: p2,
          status: MatchStatus.forfeited,
          forfeitedByUid: myUid,
        );
        final summary = MatchSummary.fromMatch(match, myUid);

        expect(summary.didIWin, isFalse);
        expect(summary.byForfeit, isTrue);
        expect(summary.verdictLine, equals('You left the match'));
      });
    });

    group('Archery', () {
      test('Win by 6 set points', () {
        // Set 1: 29 vs 26 (+2 user -> 2-0)
        // Set 2: 25 vs 29 (+2 opp -> 2-2)
        // Set 3: 29 vs 29 (+1 each -> 3-3)
        // Set 4: 26 vs 28 (+2 opp -> 3-5)
        // Wait, for user win:
        // Set 1: 30 vs 20 (+2 -> 2-0)
        // Set 2: 30 vs 20 (+2 -> 4-0)
        // Set 3: 30 vs 20 (+2 -> 6-0)
        final p1 = createPlayer(
          uid: myUid,
          name: 'Player',
          scores: [30, 30, 30],
        );
        final p2 = createPlayer(
          uid: oppUid,
          name: 'Boogyman',
          scores: [20, 20, 20],
        );

        final match = createMatch(game: 'archery', p1: p1, p2: p2);
        final summary = MatchSummary.fromMatch(match, myUid);

        expect(summary.didIWin, isTrue);
        expect(summary.verdictLine, equals('You reached 6 set points'));
        expect(summary.me.headline, equals('6 sets'));
        expect(summary.opponent.headline, equals('0 sets'));
      });

      test('Loss in Archery when opponent reaches 6 set points', () {
        final p1 = createPlayer(
          uid: myUid,
          name: 'Player',
          scores: [20, 20, 20],
        );
        final p2 = createPlayer(
          uid: oppUid,
          name: 'Boogyman',
          scores: [30, 30, 30],
        );

        final match = createMatch(game: 'archery', p1: p1, p2: p2);
        final summary = MatchSummary.fromMatch(match, myUid);

        expect(summary.didIWin, isFalse);
        expect(summary.verdictLine, equals('Boogyman reached 6 set points'));
        expect(summary.me.headline, equals('0 sets'));
        expect(summary.opponent.headline, equals('6 sets'));
      });
    });
  });
}
