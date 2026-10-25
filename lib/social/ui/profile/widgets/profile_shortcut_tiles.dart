import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../archery/archery_game_screen.dart' show ArcheryChallenge;
import '../../../../game/ui/inbox/join_match_dialog.dart';
import '../../../../game/ui/social/add_friend_dialog.dart';
import '../../../../models/friend_profile.dart';

/// 3 shortcut action tiles in [ProfileSheet]: Play a friend, Join with code, and Add friend.
class ProfileShortcutTiles extends StatelessWidget {
  final List<FriendProfile> friends;
  final VoidCallback? onPlayFriend;
  final VoidCallback onClose;

  const ProfileShortcutTiles({
    super.key,
    required this.friends,
    this.onPlayFriend,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Play a friend (Amber)
        Expanded(
          child: _buildTile(
            icon: Icons.sports_esports_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0x26F59E0B),
            label: 'Play a friend',
            onTap: () {
              HapticFeedback.lightImpact();
              if (onPlayFriend != null) {
                onClose();
                onPlayFriend!();
              } else {
                ArcheryChallenge.start(context, showGamePicker: true);
              }
            },
          ),
        ),
        const SizedBox(width: 8.0),

        // 2. Join with code (Mint)
        Expanded(
          child: _buildTile(
            icon: Icons.tag_rounded,
            iconColor: const Color(0xFF00FFCC),
            iconBg: const Color(0x2600FFCC),
            label: 'Join with code',
            onTap: () {
              HapticFeedback.lightImpact();
              JoinMatchDialog.show(context).then((joined) {
                if (joined != null && context.mounted) {
                  onClose();
                  GoRouter.maybeOf(context)?.go('/match/${joined.id}');
                }
              });
            },
          ),
        ),
        const SizedBox(width: 8.0),

        // 3. Add friend (Cyan)
        Expanded(
          child: _buildTile(
            icon: Icons.person_add_rounded,
            iconColor: const Color(0xFF38BDF8),
            iconBg: const Color(0x2638BDF8),
            label: 'Add friend',
            onTap: () {
              HapticFeedback.lightImpact();
              final existingUids = friends.map((f) => f.uid).toSet();
              AddFriendDialog.show(context, existingFriendUids: existingUids);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(18.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20.0),
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiFont.style(
                  size: 11.5,
                  weight: 800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
