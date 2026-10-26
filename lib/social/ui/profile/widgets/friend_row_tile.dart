import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';

/// Single interactive friend list row displaying status and H2H record line.
class FriendRowTile extends HookConsumerWidget {
  final FriendProfile friend;
  final String myUid;
  final VoidCallback onTap;
  final VoidCallback onChallenge;

  const FriendRowTile({
    super.key,
    required this.friend,
    required this.myUid,
    required this.onTap,
    required this.onChallenge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final isOnline = friend.lastActiveTimestamp > 0 &&
        (now - friend.lastActiveTimestamp < 5 * 60 * 1000);

    final h2h = ref.watch(headToHeadProvider(friend.uid));

    // Status description
    final String statusStr;
    if (isOnline) {
      statusStr = friend.activeMatchId != null && friend.activeMatchId!.isNotEmpty
          ? 'Online · in a match'
          : 'Online';
    } else if (friend.lastActiveTimestamp > 0) {
      final diff = now - friend.lastActiveTimestamp;
      final days = diff ~/ (24 * 3600 * 1000);
      statusStr = days > 0 ? 'Last played $days days ago' : 'Played earlier today';
    } else {
      statusStr = 'Never played';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Row(
          children: [
            CrownAvatar(
              avatar: friend.avatarEmoji,
              size: 44.0,
              isOnline: isOnline,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiFont.style(
                      size: 15.0,
                      weight: 800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    statusStr,
                    style: UiFont.style(
                      size: 11.5,
                      weight: 500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  // H2H Record Line e.g. "You lead 7 – 4"
                  RichText(
                    text: TextSpan(
                      style: UiFont.style(size: 12.0, weight: 700),
                      children: [
                        TextSpan(
                          text: h2h.myWins > h2h.theirWins
                              ? 'You lead '
                              : (h2h.theirWins > h2h.myWins
                                  ? 'They lead '
                                  : 'Level '),
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        TextSpan(
                          text: '${h2h.myWins}',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(
                          text: ' – ',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        TextSpan(
                          text: '${h2h.theirWins}',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            // Challenge button
            SizedBox(
              height: 32.0,
              child: OutlinedButton(
                onPressed: onChallenge,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2638),
                  side: const BorderSide(color: Color(0xFF2A344A)),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                child: Text(
                  'Challenge',
                  style: UiFont.style(
                    size: 12.0,
                    weight: 800,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
