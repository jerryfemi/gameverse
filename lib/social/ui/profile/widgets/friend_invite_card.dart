import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';

/// Card widget for pending incoming friend requests in [FriendsPage].
class FriendInviteCard extends StatelessWidget {
  final FriendInvite invite;
  final String myUid;

  const FriendInviteCard({
    super.key,
    required this.invite,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Row(
        children: [
          CrownAvatar(
            avatar: invite.senderAvatar,
            size: 44.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.senderName,
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
                  'Sent you a friend request',
                  style: UiFont.style(
                    size: 12.0,
                    weight: 500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          // Decline button (×)
          Container(
            width: 34.0,
            height: 34.0,
            decoration: const BoxDecoration(
              color: Color(0xFF1E2638),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 16.0, color: Color(0xFF94A3B8)),
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.lightImpact();
                FriendsService.instance
                    .declineFriendInvite(myUid, invite.senderUid);
              },
            ),
          ),
          const SizedBox(width: 8.0),
          // Accept button (mint)
          SizedBox(
            height: 34.0,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                FriendsService.instance.acceptFriendInvite(myUid, invite);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFCC),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
              child: Text(
                'Accept',
                style: UiFont.style(
                  size: 12.5,
                  weight: 900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
