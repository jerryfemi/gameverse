import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/social/ui/common/section_label.dart';
import 'package:b_ball/social/ui/tiles/active_match_tile.dart';
import 'package:b_ball/social/ui/profile/friends_page.dart';
import 'package:b_ball/social/ui/profile/matches_page.dart';
import 'package:b_ball/social/ui/profile/widgets/profile_friends_row.dart';
import 'package:b_ball/social/ui/profile/widgets/profile_google_sync_card.dart';
import 'package:b_ball/social/ui/profile/widgets/profile_header.dart';
import 'package:b_ball/social/ui/profile/widgets/profile_menu_rows.dart';
import 'package:b_ball/social/ui/profile/widgets/profile_shortcut_tiles.dart';
import 'package:b_ball/social/ui/profile/widgets/profile_stat_tiles.dart';
import 'package:b_ball/social/ui/profile/widgets/sound_settings_modal.dart';

/// Full-screen modern Profile Sheet adhering to Artboard 9 of GameVerse design.
///
/// Replaces the legacy side ProfileDrawer with a bottom-up modal sheet:
/// - Grabber handle and close button.
/// - Inner navigation (Matches, Friends) driven by a nested [Navigator].
/// - Modular widget hierarchy in `widgets/`.
class ProfileSheet extends HookConsumerWidget {
  final ValueChanged<CloudMatch>? onOpenMatch;
  final VoidCallback? onOpenMatches;
  final VoidCallback? onPlayFriend;
  final VoidCallback? onHowToPlay;

  const ProfileSheet({
    super.key,
    this.onOpenMatch,
    this.onOpenMatches,
    this.onPlayFriend,
    this.onHowToPlay,
  });

  /// Displays the [ProfileSheet] bottom modal sheet.
  static Future<void> show(
    BuildContext context, {
    ValueChanged<CloudMatch>? onOpenMatch,
    VoidCallback? onOpenMatches,
    VoidCallback? onPlayFriend,
    VoidCallback? onHowToPlay,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => ProfileSheet(
        onOpenMatch: onOpenMatch,
        onOpenMatches: onOpenMatches,
        onPlayFriend: onPlayFriend,
        onHowToPlay: onHowToPlay,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2638), width: 1.0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (nestedContext) => _ProfileMainView(
              onOpenMatch: onOpenMatch,
              onOpenMatches: onOpenMatches,
              onPlayFriend: onPlayFriend,
              onHowToPlay: onHowToPlay,
              onCloseRoot: () => Navigator.of(context).pop(),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// MAIN PROFILE VIEW (Artboard 9)
// =============================================================================
class _ProfileMainView extends HookConsumerWidget {
  final ValueChanged<CloudMatch>? onOpenMatch;
  final VoidCallback? onOpenMatches;
  final VoidCallback? onPlayFriend;
  final VoidCallback? onHowToPlay;
  final VoidCallback onCloseRoot;

  const _ProfileMainView({
    required this.onCloseRoot,
    this.onOpenMatch,
    this.onOpenMatches,
    this.onPlayFriend,
    this.onHowToPlay,
  });

  int _computeBestStreak(List<CloudMatch> completedMatches, String myUid) {
    if (completedMatches.isEmpty || myUid.isEmpty) return 0;
    final sorted = List<CloudMatch>.from(completedMatches)
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    int maxStreak = 0;
    int currentStreak = 0;
    for (final m in sorted) {
      if (m.winnerUid == myUid) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    return maxStreak;
  }

  void _navigateToMatches(BuildContext context, {int initialTabIndex = 0}) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchesPage(
          initialTabIndex: initialTabIndex,
          onClose: onCloseRoot,
        ),
      ),
    );
  }

  void _navigateToFriends(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FriendsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final myUid = AuthService.instance.currentUser?.uid ?? '';
    final friends = ref.watch(friendsListProvider).value ?? const <FriendProfile>[];
    final matches = ref.watch(userMatchesProvider).value ?? const <CloudMatch>[];

    // Compute stats
    final completedMatches = matches.where((m) => m.isFinished).toList();
    final activeMatches = matches.where((m) => !m.isFinished).toList();
    final wins = completedMatches.where((m) => m.winnerUid == myUid).length;
    final winRate = completedMatches.isNotEmpty
        ? ((wins / completedMatches.length) * 100).round()
        : 0;
    final bestStreak = _computeBestStreak(completedMatches, myUid);

    // Waiting on you matches (your turn & opponent joined)
    final waitingMatches = matches
        .where(
          (m) =>
              !m.isFinished &&
              m.isMyTurn(myUid) &&
              m.player2 != null &&
              m.status != MatchStatus.waitingForOpponent,
        )
        .toList();

    return Column(
      children: [
        // Top drag handle
        Center(
          child: Container(
            width: 38.0,
            height: 4.0,
            margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
        ),

        // Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 32.0),
            children: [
              // 1. Header (64px Avatar + Name + Edit Profile + Close)
              ProfileHeader(profile: profile, onClose: onCloseRoot),
              const SizedBox(height: 18.0),

              // 2. Three Stat Tiles (Wins, Win Rate, Best Streak)
              ProfileStatTiles(wins: wins, winRate: winRate, bestStreak: bestStreak),
              const SizedBox(height: 14.0),

              // 2b. Google Account Linking & Progress Sync Card
              ProfileGoogleSyncCard(profile: profile),
              const SizedBox(height: 18.0),

              // 3. WAITING ON YOU Section (if any matches require action)
              if (waitingMatches.isNotEmpty) ...[
                Row(
                  children: [
                    SectionLabel(text: 'WAITING ON YOU · ${waitingMatches.length}'),
                    const Spacer(),
                    InkWell(
                      onTap: () => _navigateToMatches(context, initialTabIndex: 0),
                      borderRadius: BorderRadius.circular(8.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        child: Text(
                          'All matches',
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
                const SizedBox(height: 6.0),
                ActiveMatchTile(
                  match: waitingMatches.first,
                  myUid: myUid,
                  onPlay: () {
                    onCloseRoot();
                    if (onOpenMatch != null) {
                      onOpenMatch!(waitingMatches.first);
                    } else {
                      GoRouter.maybeOf(context)
                          ?.go('/match/${waitingMatches.first.id}');
                    }
                  },
                ),
                const SizedBox(height: 18.0),
              ],

              // 4. Three Shortcut Tiles (Play a friend, Join with code, Add friend)
              ProfileShortcutTiles(
                friends: friends,
                onPlayFriend: onPlayFriend,
                onClose: onCloseRoot,
              ),
              const SizedBox(height: 22.0),

              // 5. FRIENDS · n Row with presence dots
              ProfileFriendsRow(
                friends: friends,
                myUid: myUid,
                myAvatar: profile?.avatarEmoji,
                onSeeAll: () => _navigateToFriends(context),
              ),
              const SizedBox(height: 22.0),

              // 6. Grouped List Rows (Matches, How to play, Sound)
              ProfileMenuRows(
                activeCount: activeMatches.length,
                completedCount: completedMatches.length,
                onOpenMatches: () => _navigateToMatches(context, initialTabIndex: 0),
                onHowToPlay: onHowToPlay,
                onOpenSound: () => SoundSettingsModal.show(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
