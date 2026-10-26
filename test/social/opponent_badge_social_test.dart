import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/in_game/opponent_badge_social.dart';
import 'package:b_ball/social/ui/in_game/widgets/add_friend_button.dart';
import 'package:b_ball/social/ui/in_game/widgets/add_friend_floating_chip.dart';

void main() {
  group('FriendshipStatus & Providers', () {
    test('computes FriendshipStatus.none when opponent is empty or cpu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(friendshipStatusProvider('')),
        equals(FriendshipStatus.none),
      );
      expect(
        container.read(friendshipStatusProvider('cpu')),
        equals(FriendshipStatus.none),
      );
    });

    test('computes FriendshipStatus.pending after markSent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(friendshipStatusProvider('opponent_123')),
        equals(FriendshipStatus.none),
      );

      container
          .read(sentFriendRequestsProvider.notifier)
          .markSent('opponent_123');

      expect(
        container.read(friendshipStatusProvider('opponent_123')),
        equals(FriendshipStatus.pending),
      );
    });
  });

  group('AddFriendButton Widget', () {
    testWidgets('renders add icon when not pending and check when pending',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddFriendButton(
              isPending: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.byType(AddFriendButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddFriendButton(
              isPending: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('AddFriendFloatingChip Widget', () {
    testWidgets('renders countdown intro state with Add to friends',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddFriendFloatingChip(
              state: FloatingChipState.introCountdown,
              opponentName: 'Boogyman',
              onTap: () => tapped = true,
              onRetry: () {},
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add to friends'), findsOneWidget);
      await tester.tap(find.text('Add to friends'));
      expect(tapped, isTrue);
    });

    testWidgets('renders request sent confirmation state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddFriendFloatingChip(
              state: FloatingChipState.requestSent,
              opponentName: 'Boogyman',
              onTap: () {},
              onRetry: () {},
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Request sent to Boogyman'), findsOneWidget);
    });

    testWidgets('renders error retry state and triggers retry', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddFriendFloatingChip(
              state: FloatingChipState.errorRetry,
              opponentName: 'Boogyman',
              onTap: () {},
              onRetry: () => retried = true,
              onDismissed: () {},
            ),
          ),
        ),
      );

      expect(find.text("Couldn't send · Tap to retry"), findsOneWidget);
      await tester.tap(find.text("Couldn't send · Tap to retry"));
      expect(retried, isTrue);
    });
  });

  group('OpponentBadgeSocial Widget', () {
    testWidgets('hides add friend button when opponent is a bot',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OpponentBadgeSocial(
                opponentUid: 'cpu',
                opponentName: 'Bot',
                isBot: true,
                child: SizedBox(
                  key: ValueKey('bot_avatar'),
                  width: 36,
                  height: 36,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('bot_avatar')), findsOneWidget);
      expect(find.byType(AddFriendButton), findsNothing);
    });

    testWidgets('renders add friend button for non-friend human opponent',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OpponentBadgeSocial(
                opponentUid: 'user_player_99',
                opponentName: 'Boogyman',
                isBot: false,
                child: SizedBox(
                  key: ValueKey('human_avatar'),
                  width: 36,
                  height: 36,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('human_avatar')), findsOneWidget);
      expect(find.byType(AddFriendButton), findsOneWidget);
    });
  });
}
