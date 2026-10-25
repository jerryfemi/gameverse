import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/friend_profile.dart';
import '../../common/crown_avatar.dart';
import '../../common/section_label.dart';
import '../../in_game/h2h_card.dart';

/// Horizontal friends row in [ProfileSheet] displaying 52px avatars, presence dots,
/// display names, and "See all" navigation shortcut.
class ProfileFriendsRow extends StatelessWidget {
  final List<FriendProfile> friends;
  final String myUid;
  final String? myAvatar;
  final VoidCallback onSeeAll;

  const ProfileFriendsRow({
    super.key,
    required this.friends,
    required this.myUid,
    this.myAvatar,
    required this.onSeeAll,
  });

  void _openFriendH2H(BuildContext context, FriendProfile friend) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: H2HCard.full(
            myUid: myUid,
            opponentUid: friend.uid,
            opponentName: friend.displayName,
            opponentAvatar: friend.avatarEmoji,
            myAvatar: myAvatar,
            onCollapse: () => Navigator.of(sheetCtx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;

    return Column(
      children: [
        Row(
          children: [
            SectionLabel(text: 'FRIENDS · ${friends.length}'),
            const Spacer(),
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6.0, vertical: 2.0),
                child: Text(
                  'See all',
                  style: UiFont.style(
                    size: 12.5,
                    weight: 700,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        if (friends.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    color: Color(0xFF64748B), size: 20.0),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'No friends yet · Tap Add friend to invite players',
                    style: UiFont.style(
                      size: 12.0,
                      weight: 500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 86.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: friends.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12.0),
              itemBuilder: (ctx, i) {
                final friend = friends[i];
                final isOnline = friend.lastActiveTimestamp > 0 &&
                    (now - friend.lastActiveTimestamp < 5 * 60 * 1000);

                return InkWell(
                  onTap: () => _openFriendH2H(context, friend),
                  borderRadius: BorderRadius.circular(14.0),
                  child: SizedBox(
                    width: 58.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CrownAvatar(
                          avatar: friend.avatarEmoji,
                          size: 52.0,
                          isOnline: isOnline,
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          friend.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: UiFont.style(
                            size: 11.5,
                            weight: 700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
