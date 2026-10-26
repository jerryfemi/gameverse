import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/in_game/widgets/add_friend_button.dart';
import 'package:b_ball/social/ui/in_game/widgets/add_friend_floating_chip.dart';

/// Wraps in-game opponent avatar badges with social add-friend interactions per Section 8:
/// - Mint 22px `+` button on avatar's top-outer corner with 44px hit target.
/// - Floating 2.0s countdown chip ("+ Add to friends") shown once per match.
/// - Morphing confirmation chip ("✓ Request sent to `<Name>`").
/// - In-place error state ("Couldn't send · Tap to retry") without SnackBars.
/// - Safe gesture passthrough to prevent blocking Flame gameplay canvas touches.
class OpponentBadgeSocial extends HookConsumerWidget {
  final Widget child;
  final String? opponentUid;
  final String opponentName;
  final String? matchId;
  final bool isBot;
  final bool isLeft;
  final Color badgeBorderColor;
  final VoidCallback? onAvatarTap;
  final bool? forceAbove;

  const OpponentBadgeSocial({
    super.key,
    required this.child,
    required this.opponentUid,
    required this.opponentName,
    this.matchId,
    this.isBot = false,
    this.isLeft = false,
    this.badgeBorderColor = const Color(0xFF0F172A),
    this.onAvatarTap,
    this.forceAbove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = opponentUid;
    final isHumanOpponent = !isBot && uid != null && uid.isNotEmpty && uid != 'cpu';

    // Watch friendship status scoped directly to this opponent
    final status = isHumanOpponent
        ? ref.watch(friendshipStatusProvider(uid))
        : FriendshipStatus.none;

    final chipState = useState<FloatingChipState>(FloatingChipState.hidden);
    final isAboveState = useState<bool>(forceAbove ?? true);
    final keyContext = useMemoized(() => GlobalKey());

    // Evaluate once-per-match intro chip display
    useEffect(() {
      if (!isHumanOpponent || status != FriendshipStatus.none) {
        return null;
      }

      final sessionKey = '${matchId ?? 'session'}:$uid';
      final shownSessions = ref.read(shownIntroChipSessionsProvider);

      if (!shownSessions.contains(sessionKey)) {
        // Record as displayed in this session
        ref.read(shownIntroChipSessionsProvider.notifier).markShown(sessionKey);

        // Schedule display post-frame to measure position relative to screen height
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (forceAbove != null) {
            isAboveState.value = forceAbove!;
          } else {
            final renderBox =
                keyContext.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final globalPos = renderBox.localToGlobal(Offset.zero);
              final screenHeight = MediaQuery.sizeOf(context).height;
              // Bottom half of screen -> float above; Top half -> float below
              isAboveState.value = globalPos.dy > screenHeight / 2;
            }
          }
          chipState.value = FloatingChipState.introCountdown;
        });
      }
      return null;
    }, [isHumanOpponent, uid, matchId, status]);

    if (!isHumanOpponent) {
      if (onAvatarTap != null) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAvatarTap,
          child: child,
        );
      }
      return child;
    }

    final isFriend = status == FriendshipStatus.friend;
    final isPending = status == FriendshipStatus.pending;

    Future<void> sendRequest() async {
      try {
        final myProfile = AuthService.instance.currentUser;
        if (myProfile == null) return;

        ref.read(sentFriendRequestsProvider.notifier).markSent(uid);
        chipState.value = FloatingChipState.requestSent;

        await FriendsService.instance.sendFriendInvite(
          targetUid: uid,
          myProfile: myProfile,
        );
      } catch (e) {
        chipState.value = FloatingChipState.errorRetry;
      }
    }

    void handleAddFriendTap() {
      sendRequest();
    }

    void handleRetryTap() {
      sendRequest();
    }

    void handleChipDismissed() {
      chipState.value = FloatingChipState.hidden;
    }

    return Stack(
      key: keyContext,
      clipBehavior: Clip.none,
      children: [
        // Main avatar / badge child
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAvatarTap,
          child: child,
        ),

        // 22px Mint Micro Button on avatar top-outer corner (shown when not yet friends)
        if (!isFriend)
          Positioned(
            top: -16.0,
            left: isLeft ? null : -16.0,
            right: isLeft ? -16.0 : null,
            child: AddFriendButton(
              isPending: isPending,
              onTap: handleAddFriendTap,
              badgeBorderColor: badgeBorderColor,
            ),
          ),

        // Floating pill chip (above or below avatar)
        if (chipState.value != FloatingChipState.hidden)
          Positioned(
            bottom: isAboveState.value ? 40.0 : null,
            top: isAboveState.value ? null : 40.0,
            left: isLeft ? -8.0 : null,
            right: isLeft ? null : -8.0,
            child: AddFriendFloatingChip(
              state: chipState.value,
              opponentName: opponentName,
              onTap: handleAddFriendTap,
              onRetry: handleRetryTap,
              onDismissed: handleChipDismissed,
              isAbove: isAboveState.value,
            ),
          ),
      ],
    );
  }
}
