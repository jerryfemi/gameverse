import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_full_content.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_peek_content.dart';
import 'package:b_ball/social/ui/in_game/widgets/turn_countdown_pill.dart';

/// Presentation state for the in-game growing H2H panel per Artboards 3 & 4.
enum InGameH2HState {
  /// Collapsed / normal in-game badge.
  closed,

  /// Expanded 272px peek card anchored to the opponent badge (Artboard 3).
  peek,

  /// Full-width expanded H2H history panel (Artboard 4).
  full,
}

/// In-game animated growing card supporting both `peek` and `full` states per Section 9:
/// - Peek mode (Artboard 3): 272px card anchored to badge corner with summary footer.
/// - Full mode (Artboard 4): Full width minus 12px margin, sport filters, game history,
///   and "YOUR THROW" live countdown pill when applicable.
class InGameH2HPanel extends HookConsumerWidget {
  final InGameH2HState state;
  final String myUid;
  final String? myAvatar;
  final String opponentUid;
  final String opponentName;
  final String opponentAvatar;
  final String defaultGame;
  final Widget? footerSummary;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback? onAddFriend;
  final int? turnCountdown;
  final bool isLeft;

  const InGameH2HPanel({
    super.key,
    required this.state,
    required this.myUid,
    this.myAvatar,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.defaultGame = 'all',
    this.footerSummary,
    required this.onExpand,
    required this.onCollapse,
    this.onAddFriend,
    this.turnCountdown,
    this.isLeft = false,
  });

  static const Color _cardBg = Color(0xF70F172A);
  static const Color _cardBorder = Color(0xFF1E2638);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = useState(defaultGame);
    final h2h = ref.watch(headToHeadProvider(opponentUid));
    final isFriend = ref.watch(isFriendProvider(opponentUid));

    void handleAddFriend() {
      HapticFeedback.lightImpact();
      if (onAddFriend != null) {
        onAddFriend!();
      } else {
        final myProfile = AuthService.instance.currentUser;
        if (myProfile != null) {
          ref.read(sentFriendRequestsProvider.notifier).markSent(opponentUid);
          FriendsService.instance.sendFriendInvite(
            targetUid: opponentUid,
            myProfile: myProfile,
          );
        }
      }
    }

    if (state == InGameH2HState.closed) {
      return const SizedBox.shrink();
    }

    final isFull = state == InGameH2HState.full;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxPanelHeight = screenHeight * 0.58;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 180) {
          HapticFeedback.lightImpact();
          onCollapse();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isFull ? CrossAxisAlignment.center : (isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end),
        children: [
          // Live turn status countdown pill floating above panel (Artboard 4)
          if (isFull && turnCountdown != null) ...[
            TurnCountdownPill(secondsRemaining: turnCountdown!),
            const SizedBox(height: 12.0),
          ],

          // Growing card shell
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: isFull ? double.infinity : 272.0,
            constraints: isFull
                ? BoxConstraints(maxHeight: maxPanelHeight)
                : const BoxConstraints(maxWidth: 272.0),
            margin: EdgeInsets.symmetric(horizontal: isFull ? 12.0 : 0.0),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: _cardBorder, width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x7F000000),
                  blurRadius: 24.0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: isFull
                ? H2HFullContent(
                    myUid: myUid,
                    myAvatar: myAvatar,
                    opponentName: opponentName,
                    opponentAvatar: opponentAvatar,
                    h2h: h2h,
                    selectedGame: selectedGame.value,
                    onGameSelected: (g) => selectedGame.value = g,
                    onCollapse: onCollapse,
                  )
                : H2HPeekContent(
                    opponentName: opponentName,
                    opponentAvatar: opponentAvatar,
                    h2h: h2h,
                    isFriend: isFriend,
                    onAddFriend: handleAddFriend,
                    onExpand: onExpand,
                    footer: footerSummary,
                  ),
          ),
        ],
      ),
    );
  }
}
