import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/common/app_avatar.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/social/ui/profile/profile_sheet.dart';
import 'package:b_ball/tiki_counter/menu/setup/gameverse_link.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';

/// Your GameVerse picture, top-right of the hub. Tap = the same profile
/// sheet every GameVerse game opens. Without Firebase (bare dev run) it
/// shows the default picture and does nothing.
class TikiProfileButton extends ConsumerWidget {
  final double size;

  const TikiProfileButton({super.key, this.size = 44});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = GameVerseLink.user != null;
    final user = linked ? ref.watch(currentUserProfileProvider).value : null;
    return Semantics(
      button: true,
      label: 'Your profile',
      child: AppAvatar(
        avatar: user?.avatar ?? AppAvatar.defaultAvatar,
        size: size,
        borderColor: TikiPalette.cyan,
        borderWidth: 2,
        onTap: linked ? () => _open(context) : null,
      ),
    );
  }

  void _open(BuildContext context) {
    ProfileSheet.show(
      context,
      // Completed and active matches open the shared match screen.
      onOpenMatch: (m) => GoRouter.maybeOf(context)?.go('/match/${m.id}'),
      // Play a friend and How to play come with Tiki 1v1 and the tour.
    );
  }
}
