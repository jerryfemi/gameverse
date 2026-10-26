import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/game/ui/social/add_friend_dialog.dart';

/// Vertical radio-selector list displaying friends for 1v1 match challenges,
/// matching Design Template 17.
class FriendSelectorRibbon extends ConsumerWidget {
  final UserProfile? profile;
  final FriendProfile? selectedFriend;
  final ValueChanged<FriendProfile?> onFriendSelected;
  final VoidCallback onUseOpenCode;

  const FriendSelectorRibbon({
    super.key,
    required this.profile,
    required this.selectedFriend,
    required this.onFriendSelected,
    required this.onUseOpenCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsListProvider).value ?? const <FriendProfile>[];

    void addFriend() {
      HapticFeedback.selectionClick();
      AddFriendDialog.show(
        context,
        existingFriendUids: {for (final f in friends) f.uid},
      );
    }

    if (friends.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF1E2638)),
        ),
        child: Column(
          children: [
            const Text(
              'No friends added yet.\nAdd friends to challenge them anytime!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12.0,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: addFriend,
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFCC),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, size: 14.0, color: Color(0xFF0A0E1A)),
                        SizedBox(width: 4.0),
                        Text(
                          'ADD FRIEND',
                          style: TextStyle(
                            color: Color(0xFF0A0E1A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final colors = [
      const Color(0xFF10B981), // emerald
      const Color(0xFFA855F7), // purple
      const Color(0xFFF59E0B), // orange
      const Color(0xFF38BDF8), // blue
      const Color(0xFFEC4899), // pink
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180.0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: friends.length,
            separatorBuilder: (_, _) => const Divider(color: Color(0xFF1E2638), height: 1.0),
            itemBuilder: (context, index) {
              final friend = friends[index];
              final isSelected = selectedFriend?.uid == friend.uid;
              final color = colors[index % colors.length];

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onFriendSelected(isSelected ? null : friend);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
                  child: Row(
                    children: [
                      // Avatar with initials & online dot
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38.0,
                            height: 38.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(color: const Color(0xFF0A0E1A), width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _extractInitials(friend.displayName),
                              style: const TextStyle(
                                color: Color(0xFF0A0E1A),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -1.0,
                            bottom: -1.0,
                            child: Container(
                              width: 10.0,
                              height: 10.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981),
                                border: Border.all(color: const Color(0xFF111827), width: 1.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12.0),

                      // Friend Name & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1.5),
                            const Text(
                              'Online · Ready for 1v1',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),

                      // Radio Button Indicator
                      Container(
                        width: 20.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF00FFCC) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00FFCC) : const Color(0xFF475569),
                            width: isSelected ? 2.0 : 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isSelected
                            ? Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0A0E1A),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _extractInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'PL';
    final parts = clean.split(RegExp(r'[\s#_-]+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, min(2, clean.length)).toUpperCase();
  }
}
