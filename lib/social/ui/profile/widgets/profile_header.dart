import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../game/ui/common/edit_profile_dialog.dart';
import '../../../../services/auth_service.dart';
import '../../common/crown_avatar.dart';

/// Top header for [ProfileSheet] displaying 64px avatar, user display name,
/// "Edit name and avatar" trigger, and sheet close button.
class ProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onClose;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CrownAvatar(
          avatar: profile?.avatarEmoji ?? '👤',
          size: 64.0,
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.displayName ?? 'Player',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiFont.style(
                  size: 22.0,
                  weight: 900,
                  color: Colors.white,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3.0),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  EditProfileDialog.show(context, profile: profile);
                },
                borderRadius: BorderRadius.circular(6.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    'Edit name and avatar',
                    style: UiFont.style(
                      size: 13.0,
                      weight: 700,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 36.0,
          height: 36.0,
          decoration: const BoxDecoration(
            color: Color(0xFF1E2638),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            tooltip: 'Close',
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF94A3B8),
              size: 18.0,
            ),
            padding: EdgeInsets.zero,
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}
