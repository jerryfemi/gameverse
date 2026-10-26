import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/game/ui/match/match_setup_dialog.dart';
import 'package:b_ball/game/ui/social/add_friend_dialog.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/social/ui/common/section_label.dart';
import 'package:b_ball/social/ui/in_game/h2h_card.dart';
import 'package:b_ball/social/ui/profile/widgets/friend_invite_card.dart';
import 'package:b_ball/social/ui/profile/widgets/friend_row_tile.dart';
import 'package:b_ball/social/ui/profile/widgets/friends_search_header.dart';

export 'package:b_ball/social/ui/profile/widgets/friend_invite_card.dart';
export 'package:b_ball/social/ui/profile/widgets/friend_row_tile.dart';
export 'package:b_ball/social/ui/profile/widgets/friends_search_header.dart';

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
            FriendsSearchHeader(
              searchController: searchController,
              searchQuery: searchQuery.value,
              onAddFriend: () => _showAddFriendDialog(context, ref),
              onBack: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).maybePop();
              },
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
                          FriendInviteCard(invite: inv, myUid: myUid),
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
          return FriendRowTile(
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
}
