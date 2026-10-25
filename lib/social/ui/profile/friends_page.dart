import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/game/ui/match/match_setup_dialog.dart';
import 'package:b_ball/game/ui/social/add_friend_dialog.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';
import 'package:b_ball/social/ui/common/section_label.dart';
import 'package:b_ball/social/ui/in_game/h2h_card.dart';

/// Full friends directory screen adhering to Artboard 11 of GameVerse design.
///
/// Built with flutter_hooks + hooks_riverpod:
/// - Header: Back arrow, "Friends" title, and "+ Add" friend action.
/// - Search bar filtering friends by name or tag.
/// - Pending friend requests card with contextual history and Accept / Decline.
/// - Categorized ONLINE and ALL FRIENDS lists featuring H2H record lines ("You lead 7–4")
///   and 1-tap Challenge triggers.
class FriendsPage extends HookConsumerWidget {
  const FriendsPage({super.key});

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final friends = ref.read(friendsListProvider).value ?? const [];
    final existingUids = friends.map((f) => f.uid).toSet();
    AddFriendDialog.show(context, existingFriendUids: existingUids);
  }

  void _challengeFriend(BuildContext context, FriendProfile friend) {
    HapticFeedback.mediumImpact();
    MatchSetupDialog.show(
      context,
      initialConfig: MatchConfig(
        player2Uid: friend.uid,
        player2Name: friend.displayName,
        player2Avatar: friend.avatarEmoji,
        opponentFriend: friend,
      ),
      showGamePicker: true,
    );
  }

  void _openH2HSheet(BuildContext context, FriendProfile friend, String myUid) {
    HapticFeedback.lightImpact();
    final myProfile = AuthService.instance.currentUser;
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
            myAvatar: myProfile?.avatarEmoji,
            onCollapse: () => Navigator.of(sheetCtx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    useEffect(() {
      void listener() {
        searchQuery.value = searchController.text.trim().toLowerCase();
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    final friendsAsync = ref.watch(friendsListProvider);
    final invitesAsync = ref.watch(incomingInvitesProvider);
    final myUid = AuthService.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).maybePop();
                    },
                  ),
                  const SizedBox(width: 14.0),
                  Text(
                    'Friends',
                    style: UiFont.style(
                      size: 26.0,
                      weight: 900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 36.0,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddFriendDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 16.0),
                      label: Text(
                        'Add',
                        style: UiFont.style(
                          size: 13.0,
                          weight: 800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                height: 44.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
                ),
                child: TextField(
                  controller: searchController,
                  style: UiFont.style(size: 13.5, color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF64748B),
                      size: 20.0,
                    ),
                    suffixIcon: searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 16.0, color: Color(0xFF64748B)),
                            onPressed: () => searchController.clear(),
                          )
                        : null,
                    hintText: 'Search friends or a gamer tag',
                    hintStyle: UiFont.style(
                      size: 13.5,
                      weight: 500,
                      color: const Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6.0),

            // Friends Directory Body
            Expanded(
              child: friendsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FFCC),
                    strokeWidth: 2.5,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Failed to load friends',
                    style: UiFont.style(
                      size: 14.0,
                      weight: 600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
                data: (allFriends) {
                  final invites = invitesAsync.value ?? const [];
                  final query = searchQuery.value;

                  // Apply search filter
                  final filtered = query.isEmpty
                      ? allFriends
                      : allFriends.where((f) {
                          return f.displayName.toLowerCase().contains(query);
                        }).toList();

                  final now = DateTime.now().millisecondsSinceEpoch;
                  final onlineFriends = filtered.where((f) {
                    return f.lastActiveTimestamp > 0 &&
                        (now - f.lastActiveTimestamp < 5 * 60 * 1000);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    children: [
                      // 1. Pending Incoming Invites
                      if (invites.isNotEmpty && query.isEmpty) ...[
                        SectionLabel(text: 'REQUESTS · ${invites.length}'),
                        for (final inv in invites)
                          _buildInviteCard(context, inv, myUid),
                        const SizedBox(height: 14.0),
                      ],

                      // 2. Online Friends Group
                      if (onlineFriends.isNotEmpty) ...[
                        SectionLabel(text: 'ONLINE · ${onlineFriends.length}'),
                        _buildFriendsGroupContainer(
                          context: context,
                          friends: onlineFriends,
                          myUid: myUid,
                        ),
                        const SizedBox(height: 14.0),
                      ],

                      // 3. All Friends Group
                      if (filtered.isNotEmpty) ...[
                        SectionLabel(text: 'ALL FRIENDS · ${filtered.length}'),
                        _buildFriendsGroupContainer(
                          context: context,
                          friends: filtered,
                          myUid: myUid,
                        ),
                      ] else if (query.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0),
                          child: Center(
                            child: Text(
                              'No friends found for "$query"',
                              style: UiFont.style(
                                size: 14.0,
                                weight: 600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ] else if (allFriends.isEmpty && invites.isEmpty) ...[
                        _buildEmptyFriendsState(context, ref),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pending Invite Card (Artboard 11 - top card)
  // ---------------------------------------------------------------------------
  Widget _buildInviteCard(
    BuildContext context,
    FriendInvite invite,
    String myUid,
  ) {
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

  // ---------------------------------------------------------------------------
  // Friends Group Container
  // ---------------------------------------------------------------------------
  Widget _buildFriendsGroupContainer({
    required BuildContext context,
    required List<FriendProfile> friends,
    required String myUid,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: friends.length,
        separatorBuilder: (context, index) =>
            const Divider(color: Color(0xFF1E2638), height: 1.0),
        itemBuilder: (ctx, i) {
          final friend = friends[i];
          return _FriendRow(
            friend: friend,
            myUid: myUid,
            onTap: () => _openH2HSheet(context, friend, myUid),
            onChallenge: () => _challengeFriend(context, friend),
          );
        },
      ),
    );
  }

  Widget _buildEmptyFriendsState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 32.0),
        child: Column(
          children: [
            Text(
              'No friends added yet',
              style: UiFont.style(
                size: 16.0,
                weight: 800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              'Add players or invite rivals by username or code.',
              textAlign: TextAlign.center,
              style: UiFont.style(
                size: 13.0,
                weight: 500,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18.0),
            ElevatedButton.icon(
              onPressed: () => _showAddFriendDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16.0),
              label: Text(
                'Add Friend',
                style: UiFont.style(
                  size: 13.0,
                  weight: 800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 38.0,
      height: 38.0,
      decoration: const BoxDecoration(
        color: Color(0xFF1E2638),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18.0, color: Colors.white),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _FriendRow extends HookConsumerWidget {
  final FriendProfile friend;
  final String myUid;
  final VoidCallback onTap;
  final VoidCallback onChallenge;

  const _FriendRow({
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
