import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/social/models/head_to_head.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/ui/in_game/in_game_h2h_overlay.dart';
import 'package:b_ball/social/ui/in_game/in_game_h2h_panel.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_full_content.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_peek_content.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_primitives.dart';
import 'package:b_ball/social/ui/in_game/widgets/turn_countdown_pill.dart';

void main() {
  const mockMe = PlayerSummary(
    uid: 'me_1',
    name: 'You',
    avatar: '🏀',
    headline: '301 pts',
    unit: 'pts',
    rawScore: 301,
  );

  const mockOpp = PlayerSummary(
    uid: 'opp_1',
    name: 'Boogyman',
    avatar: '🎯',
    headline: '205 pts',
    unit: 'pts',
    rawScore: 205,
  );

  group('H2H Primitives', () {
    testWidgets('H2HSplitBar renders two colored containers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: H2HSplitBar(myRatio: 0.7),
          ),
        ),
      );

      expect(find.byType(H2HSplitBar), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('H2HOutcomeDot renders W, L, D variants', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                H2HOutcomeDot(didWin: true),
                H2HOutcomeDot(didWin: false),
                H2HOutcomeDot(didWin: null),
              ],
            ),
          ),
        ),
      );

      expect(find.text('W'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });
  });

  group('TurnCountdownPill Widget', () {
    testWidgets('renders YOUR THROW label and seconds remaining',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TurnCountdownPill(secondsRemaining: 15),
          ),
        ),
      );

      expect(find.text('YOUR THROW'), findsOneWidget);
      expect(find.text('15s'), findsOneWidget);
    });
  });

  group('H2HPeekContent Widget', () {
    final mockH2H = HeadToHead(
      myUid: 'me_1',
      opponentUid: 'opp_1',
      myWins: 4,
      theirWins: 2,
      draws: 0,
      byGame: const {
        'darts': GameH2H(myWins: 4, theirWins: 2),
      },
      lastFive: const [true, false, true, true, false],
      currentStreak: 1,
      leadSummary: 'You lead · won last 1',
      recordLine: 'You lead 4 – 2',
      matches: const [],
    );

    testWidgets('renders opponent info, record, and handles add/expand taps',
        (tester) async {
      bool addTapped = false;
      bool expandTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: H2HPeekContent(
              opponentName: 'Boogyman',
              opponentAvatar: '🎯',
              h2h: mockH2H,
              isFriend: false,
              onAddFriend: () => addTapped = true,
              onExpand: () => expandTapped = true,
              footer: const Text('CUSTOM_FOOTER'),
            ),
          ),
        ),
      );

      expect(find.text('Boogyman'), findsOneWidget);
      expect(find.text('Not in your friends yet'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('See all our matches'), findsOneWidget);
      expect(find.text('CUSTOM_FOOTER'), findsOneWidget);

      await tester.tap(find.text('Add'));
      expect(addTapped, isTrue);

      await tester.tap(find.text('See all our matches'));
      expect(expandTapped, isTrue);
    });
  });

  group('H2HFullContent & Match Rows', () {
    final mockMatches = [
      const MatchSummary(
        matchId: 'm1',
        game: 'darts',
        finishedAt: 1700000000000,
        me: mockMe,
        opponent: mockOpp,
        didIWin: true,
        byForfeit: false,
        verdictLine: 'Won 301 in 9 darts',
        heroHeadline: 'VICTORY',
      ),
      const MatchSummary(
        matchId: 'm2',
        game: 'archery',
        finishedAt: 1700000000000,
        me: mockMe,
        opponent: mockOpp,
        didIWin: false,
        byForfeit: false,
        verdictLine: 'Lost 2-6 sets',
        heroHeadline: 'DEFEAT',
      ),
    ];

    final mockH2H = HeadToHead(
      myUid: 'me_1',
      opponentUid: 'opp_1',
      myWins: 5,
      theirWins: 3,
      draws: 0,
      matches: mockMatches,
      lastFive: const [true, false],
      currentStreak: 1,
      leadSummary: 'You lead',
      recordLine: 'You lead 5 – 3',
      byGame: const {
        'darts': GameH2H(myWins: 3, theirWins: 1),
        'archery': GameH2H(myWins: 2, theirWins: 2),
      },
    );

    testWidgets('renders stacked avatars, pills, and match history',
        (tester) async {
      String selectedFilter = 'all';
      bool collapseTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return H2HFullContent(
                    myUid: 'me_1',
                    myAvatar: '🏀',
                    opponentName: 'Boogyman',
                    opponentAvatar: '🎯',
                    h2h: mockH2H,
                    selectedGame: selectedFilter,
                    onGameSelected: (g) => setState(() => selectedFilter = g),
                    onCollapse: () => collapseTapped = true,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('You vs Boogyman'), findsOneWidget);
      expect(find.text('All 8'), findsOneWidget);
      expect(find.text('Darts 4'), findsOneWidget);
      expect(find.text('Archery 4'), findsOneWidget);
      expect(find.text('Won 301 in 9 darts'), findsOneWidget);
      expect(find.text('Lost 2-6 sets'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      expect(collapseTapped, isTrue);
    });
  });

  group('InGameH2HPanel & InGameH2HOverlay Widgets', () {
    testWidgets('closed state returns nothing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InGameH2HPanel(
                state: InGameH2HState.closed,
                myUid: 'me_1',
                opponentUid: 'opp_1',
                opponentName: 'Boogyman',
                opponentAvatar: '🎯',
                onExpand: () {},
                onCollapse: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Boogyman'), findsNothing);
    });

    testWidgets('peek state displays peek card with footer', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InGameH2HPanel(
                state: InGameH2HState.peek,
                myUid: 'me_1',
                opponentUid: 'opp_1',
                opponentName: 'Boogyman',
                opponentAvatar: '🎯',
                onExpand: () {},
                onCollapse: () {},
                footerSummary: const Text('FOOTER_TEXT'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Boogyman'), findsOneWidget);
      expect(find.text('FOOTER_TEXT'), findsOneWidget);
    });

    testWidgets('InGameH2HOverlay touch barrier triggers close and lifecycle',
        (tester) async {
      bool closed = false;
      bool enginePaused = false;
      bool engineResumed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InGameH2HOverlay(
                state: InGameH2HState.peek,
                myUid: 'me_1',
                opponentUid: 'opp_1',
                opponentName: 'Boogyman',
                opponentAvatar: '🎯',
                onExpand: () {},
                onCollapse: () {},
                onClose: () => closed = true,
                onPauseEngine: () => enginePaused = true,
                onResumeEngine: () => engineResumed = true,
                isOnline: false,
              ),
            ),
          ),
        ),
      );

      expect(enginePaused, isTrue);

      // Tap outside card (top-left corner of overlay barrier)
      await tester.tapAt(const Offset(10, 10));
      expect(closed, isTrue);

      // Transition to closed triggers onResumeEngine
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InGameH2HOverlay(
                state: InGameH2HState.closed,
                myUid: 'me_1',
                opponentUid: 'opp_1',
                opponentName: 'Boogyman',
                opponentAvatar: '🎯',
                onExpand: () {},
                onCollapse: () {},
                onClose: () {},
                onPauseEngine: () {},
                onResumeEngine: () => engineResumed = true,
                isOnline: false,
              ),
            ),
          ),
        ),
      );

      expect(engineResumed, isTrue);
    });
  });
}
