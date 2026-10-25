import 'dart:math' as math;

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../archery/archery_game_screen.dart' show ArcheryChallenge;
import '../../../game/audio/audio_engine.dart';
import '../../../game/match/match_config.dart';
import '../../../game/ui/common/edit_profile_dialog.dart';
import '../../../game/ui/game_rules_dialog.dart';
import '../../../game/ui/inbox/join_match_dialog.dart';
import '../../../game/ui/match/match_setup_dialog.dart';
import '../../../game/ui/social/add_friend_dialog.dart';
import '../../../models/cloud_match.dart';
import '../../../models/friend_profile.dart';
import '../../../providers/app_providers.dart';
import '../../../services/auth_service.dart';
import '../../providers/social_providers.dart';
import '../common/crown_avatar.dart';
import '../common/section_label.dart';
import '../in_game/h2h_card.dart';
import '../tiles/active_match_tile.dart';
import 'friends_page.dart';
import 'matches_page.dart';

/// Full-screen modern Profile Sheet adhering to Artboard 9 of GameVerse design.
///
/// Replaces the legacy side [ProfileDrawer] with a bottom-up modal sheet:
/// - Grabber handle and close button.
/// - Inner navigation (Matches, Friends) driven by a nested [Navigator].
/// - 64px avatar, name, and "Edit name and avatar" link.
/// - 3 stat tiles: Wins, Win rate, Best streak computed from match history.
/// - WAITING ON YOU section featuring active [ActiveMatchTile] cards.
/// - 3 shortcut tiles: Play a friend, Join with code, Add friend.
/// - FRIENDS row with avatars, presence dots, and a "See all" shortcut.
/// - Grouped list rows: Matches, How to play, Sound settings.
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
      if (m.isWinner(myUid)) {
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

  void _openSoundSettings(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => const _SoundSettingsModal(),
    );
  }

  void _openFriendH2H(
    BuildContext context,
    FriendProfile friend,
    String myUid,
    String? myAvatar,
  ) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final myUid = AuthService.instance.currentUser?.uid ?? '';
    final friends = ref.watch(friendsListProvider).value ?? const <FriendProfile>[];
    final matches = ref.watch(userMatchesProvider).value ?? const <CloudMatch>[];

    // Compute stats
    final completedMatches = matches.where((m) => m.isFinished).toList();
    final activeMatches = matches.where((m) => !m.isFinished).toList();
    final wins = completedMatches.where((m) => m.isWinner(myUid)).length;
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
              _buildHeader(context, profile),
              const SizedBox(height: 18.0),

              // 2. Three Stat Tiles (Wins, Win Rate, Best Streak)
              _buildStatTiles(wins: wins, winRate: winRate, bestStreak: bestStreak),
              const SizedBox(height: 20.0),

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
              _buildShortcutTiles(
                context: context,
                ref: ref,
                friends: friends,
              ),
              const SizedBox(height: 22.0),

              // 5. FRIENDS · n Row
              Row(
                children: [
                  SectionLabel(text: 'FRIENDS · ${friends.length}'),
                  const Spacer(),
                  InkWell(
                    onTap: () => _navigateToFriends(context),
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
              _buildFriendsHorizontalRow(
                context: context,
                friends: friends,
                myUid: myUid,
                myAvatar: profile?.avatarEmoji,
              ),
              const SizedBox(height: 22.0),

              // 6. Grouped List Rows (Matches, How to play, Sound)
              _buildGroupedListRows(
                context: context,
                activeCount: activeMatches.length,
                completedCount: completedMatches.length,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header (64px Avatar + Name + Edit Profile + Close Button)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, UserProfile? profile) {
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
            onPressed: onCloseRoot,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Three Stat Tiles (Wins, Win Rate, Best Streak)
  // ---------------------------------------------------------------------------
  Widget _buildStatTiles({
    required int wins,
    required int winRate,
    required int bestStreak,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(value: '$wins', label: 'WINS'),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildStatTile(value: '$winRate%', label: 'WIN RATE'),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildStatTile(value: '$bestStreak', label: 'BEST STREAK'),
        ),
      ],
    );
  }

  Widget _buildStatTile({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: UiFont.style(
              size: 22.0,
              weight: 900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3.0),
          Text(
            label,
            style: UiFont.style(
              size: 10.5,
              weight: 800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Three Shortcut Tiles (Play a friend, Join with code, Add friend)
  // ---------------------------------------------------------------------------
  Widget _buildShortcutTiles({
    required BuildContext context,
    required WidgetRef ref,
    required List<FriendProfile> friends,
  }) {
    return Row(
      children: [
        // 1. Play a friend (Amber)
        Expanded(
          child: _buildShortcutTile(
            icon: Icons.sports_esports_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0x26F59E0B),
            label: 'Play a friend',
            onTap: () {
              HapticFeedback.lightImpact();
              if (onPlayFriend != null) {
                onCloseRoot();
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
          child: _buildShortcutTile(
            icon: Icons.tag_rounded,
            iconColor: const Color(0xFF00FFCC),
            iconBg: const Color(0x2600FFCC),
            label: 'Join with code',
            onTap: () {
              HapticFeedback.lightImpact();
              JoinMatchDialog.show(context).then((joined) {
                if (joined != null && context.mounted) {
                  onCloseRoot();
                  GoRouter.maybeOf(context)?.go('/match/${joined.id}');
                }
              });
            },
          ),
        ),
        const SizedBox(width: 8.0),

        // 3. Add friend (Cyan)
        Expanded(
          child: _buildShortcutTile(
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

  Widget _buildShortcutTile({
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

  // ---------------------------------------------------------------------------
  // 5. FRIENDS · n Horizontal Row
  // ---------------------------------------------------------------------------
  Widget _buildFriendsHorizontalRow({
    required BuildContext context,
    required List<FriendProfile> friends,
    required String myUid,
    required String? myAvatar,
  }) {
    if (friends.isEmpty) {
      return Container(
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
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    return SizedBox(
      height: 86.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: friends.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12.0),
        itemBuilder: (ctx, i) {
          final friend = friends[i];
          final isOnline = friend.lastActiveTimestamp > 0 &&
              (now - friend.lastActiveTimestamp < 5 * 60 * 1000);

          return InkWell(
            onTap: () => _openFriendH2H(context, friend, myUid, myAvatar),
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
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Grouped List Rows (Matches, How to play, Sound)
  // ---------------------------------------------------------------------------
  Widget _buildGroupedListRows({
    required BuildContext context,
    required int activeCount,
    required int completedCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Column(
        children: [
          // Matches row
          _buildRowItem(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFF00FFCC),
            iconBg: const Color(0xFF0D3B36),
            title: 'Matches',
            subtitle: '$activeCount active · $completedCount completed',
            onTap: () => _navigateToMatches(context, initialTabIndex: 0),
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),

          // How to play row
          _buildRowItem(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF38BDF8),
            iconBg: const Color(0xFF0C2E42),
            title: 'How to play',
            subtitle: 'Hoops, Archery, Darts',
            onTap: () {
              if (onHowToPlay != null) {
                onCloseRoot();
                onHowToPlay!();
              } else {
                showGameRulesDialog(context);
              }
            },
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),

          // Sound row
          _buildRowItem(
            icon: Icons.volume_up_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFF382408),
            title: 'Sound',
            subtitle: 'Music, effects, ambience',
            onTap: () => _openSoundSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, color: iconColor, size: 20.0),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UiFont.style(
                        size: 15.0,
                        weight: 800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: UiFont.style(
                        size: 12.0,
                        weight: 500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
                size: 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SOUND SETTINGS MODAL
// =============================================================================
class _SoundSettingsModal extends HookWidget {
  const _SoundSettingsModal();

  @override
  Widget build(BuildContext context) {
    final musicVol = useState(AudioEngine.musicVolume);
    final sfxVol = useState(AudioEngine.sfxVolume);
    final isMuted = useState(AudioEngine.isMuted);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 24.0,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sound Settings',
                  style: UiFont.style(
                    size: 18.0,
                    weight: 900,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF94A3B8), size: 20.0),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Master Mute Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Mute All Audio',
                style: UiFont.style(
                  size: 14.5,
                  weight: 700,
                  color: Colors.white,
                ),
              ),
              value: isMuted.value,
              activeColor: const Color(0xFFEF4444),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                isMuted.value = val;
                AudioEngine.isMuted = val;
              },
            ),
            const Divider(color: Color(0xFF1E2638), height: 16.0),

            // Music Volume
            Text(
              'Music Volume (${(musicVol.value * 100).round()}%)',
              style: UiFont.style(
                size: 13.0,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Slider(
              value: musicVol.value,
              activeColor: const Color(0xFF00FFCC),
              inactiveColor: const Color(0xFF1E2638),
              onChanged: isMuted.value
                  ? null
                  : (val) {
                      musicVol.value = val;
                      AudioEngine.musicVolume = val;
                    },
            ),
            const SizedBox(height: 8.0),

            // Sound Effects Volume
            Text(
              'Sound Effects (${(sfxVol.value * 100).round()}%)',
              style: UiFont.style(
                size: 13.0,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            Slider(
              value: sfxVol.value,
              activeColor: const Color(0xFF38BDF8),
              inactiveColor: const Color(0xFF1E2638),
              onChanged: isMuted.value
                  ? null
                  : (val) {
                      sfxVol.value = val;
                      AudioEngine.sfxVolume = val;
                    },
            ),
          ],
        ),
      ),
    );
  }
}
