import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/common/app_avatar.dart';
import 'package:b_ball/game/ui/common/app_colors.dart';
import 'package:b_ball/game/ui/social/friends_hub_sheet.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';

/// Top header bar for the Match Inbox sheet.
///
/// Houses the player profile banner, edit triggers, close button,
/// social friends hub button with live badge, and game selector shortcut.
class InboxHeader extends ConsumerWidget {
  final UserProfile? profile;
  final VoidCallback onEditProfile;
  final VoidCallback onClose;
  final ValueChanged<CloudMatch> onPlayMatch;
  final VoidCallback onCreateMatch;
  final ValueChanged<CloudMatch>? onViewPodium;

  const InboxHeader({
    super.key,
    required this.profile,
    required this.onEditProfile,
    required this.onClose,
    required this.onPlayMatch,
    required this.onCreateMatch,
    this.onViewPodium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsBadgeCount = ref.watch(friendsBadgeCountProvider);

    return Column(
      children: [
        // Profile identity row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              InkWell(
                onTap: profile != null ? onEditProfile : null,
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    AppAvatar(
                      avatar: profile?.avatarEmoji ?? AppAvatar.defaultAvatar,
                      size: 38,
                      borderColor: const Color(0xFF38BDF8),
                      borderWidth: 1.8,
                      showGlow: true,
                      glowColor: const Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile?.displayName ?? 'Baller',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: Color(0xFF38BDF8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'MY PROFILE',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 22,
                ),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Navigation shortcuts (Friends Hub + Games Grid)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await FriendsHubSheet.show(
                            context,
                            onPlayMatch: (m) {
                              Navigator.of(context).pop();
                              onPlayMatch(m);
                            },
                            onCreateMatch: () {
                              Navigator.of(context).pop();
                              onCreateMatch();
                            },
                            onViewPodium: (m) {
                              Navigator.of(context).pop();
                              onViewPodium?.call(m);
                            },
                          );
                        },
                        icon: const Icon(Icons.people_alt_rounded, size: 14),
                        label: const Text(
                          'FRIENDS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF818CF8),
                          side: const BorderSide(
                            color: Color(0xFF6366F1),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (friendsBadgeCount > 0)
                      Positioned(
                        top: -4.0,
                        right: -4.0,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18.0,
                            minHeight: 18.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 1.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: const Color(0xFF0F1420),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentRed.withValues(alpha: 0.6),
                                blurRadius: 6.0,
                                spreadRadius: 1.0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$friendsBadgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2638),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF334155),
                    width: 1.2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/games');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: Color(0xFF00FFCC),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
