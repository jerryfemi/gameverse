import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_full_content.dart';
import 'package:b_ball/social/ui/in_game/widgets/h2h_peek_content.dart';

export 'package:b_ball/social/ui/in_game/widgets/h2h_full_content.dart';
export 'package:b_ball/social/ui/in_game/widgets/h2h_peek_content.dart';
export 'package:b_ball/social/ui/in_game/widgets/h2h_primitives.dart';

enum H2HCardMode { peek, full }

/// Reusable Head-to-Head card widget supporting both in-game `peek` and expanded `full` views.
///
/// Built with flutter_hooks + hooks_riverpod:
/// - Peek: Opponent profile + Add button, aggregate score bar, Last-5 outcome dots, expand button.
/// - Full: Stacked avatars, sport filter pills, record panel with lead badge, match history list.
class H2HCard extends HookConsumerWidget {
  final String myUid;
  final String opponentUid;
  final String opponentName;
  final String opponentAvatar;
  final String? myAvatar;
  final H2HCardMode mode;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;
  final VoidCallback? onAddFriend;

  const H2HCard({
    super.key,
    required this.myUid,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.myAvatar,
    this.mode = H2HCardMode.peek,
    this.onExpand,
    this.onCollapse,
    this.onAddFriend,
  });

  const H2HCard.peek({
    super.key,
    required this.myUid,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.myAvatar,
    this.onExpand,
    this.onAddFriend,
  }) : mode = H2HCardMode.peek,
       onCollapse = null;

  const H2HCard.full({
    super.key,
    required this.myUid,
    required this.opponentUid,
    required this.opponentName,
    required this.opponentAvatar,
    this.myAvatar,
    this.onCollapse,
    this.onAddFriend,
  }) : mode = H2HCardMode.full,
       onExpand = null;

  void _handleAddFriend() {
    HapticFeedback.lightImpact();
    if (onAddFriend != null) {
      onAddFriend!();
    } else {
      final myProfile = AuthService.instance.currentUser;
      if (myProfile != null) {
        FriendsService.instance.sendFriendInvite(
          targetUid: opponentUid,
          myProfile: myProfile,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = useState('all');
    final h2h = ref.watch(headToHeadProvider(opponentUid));
    final isFriend = ref.watch(isFriendProvider(opponentUid));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20.0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: mode == H2HCardMode.peek
          ? H2HPeekContent(
              opponentName: opponentName,
              opponentAvatar: opponentAvatar,
              h2h: h2h,
              isFriend: isFriend,
              onAddFriend: _handleAddFriend,
              onExpand: onExpand,
            )
          : H2HFullContent(
              myUid: myUid,
              myAvatar: myAvatar,
              opponentName: opponentName,
              opponentAvatar: opponentAvatar,
              h2h: h2h,
              selectedGame: selectedGame.value,
              onGameSelected: (g) => selectedGame.value = g,
              onCollapse: onCollapse,
            ),
    );
  }
}
