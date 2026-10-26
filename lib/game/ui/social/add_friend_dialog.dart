import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/services/friends_service.dart';
import 'package:b_ball/game/ui/common/inline_feedback.dart';
import 'package:b_ball/game/ui/social/widgets/add_friend_recent_card.dart';
import 'package:b_ball/game/ui/social/widgets/add_friend_tag_card.dart';

/// Modal dialog matching Design Template 13:
/// - User Gamer Tag card with copy action
/// - Clean search input field
/// - "PLAYED RECENTLY" list with "+ ADD" / "✓ SENT" pills
/// - FittedBox responsive scaling (< 220 lines)
class AddFriendDialog extends HookWidget {
  final Set<String> existingFriendUids;
  final ValueChanged<FriendProfile>? onFriendAdded;

  const AddFriendDialog({
    super.key,
    required this.existingFriendUids,
    this.onFriendAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required Set<String> existingFriendUids,
    ValueChanged<FriendProfile>? onFriendAdded,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => AddFriendDialog(
        existingFriendUids: existingFriendUids,
        onFriendAdded: onFriendAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final debounceTimer = useRef<Timer?>(null);
    final results = useState<List<FriendProfile>>([]);
    final isSearching = useState<bool>(false);
    final invitedUids = useState<Set<String>>({});
    final inviteError = useState<({String message, FriendProfile? retryFor})?>(null);
    final tagCopied = useFlashFlag();

    final friendUids = useMemoized(
      () => Set<String>.from(existingFriendUids),
      [existingFriendUids],
    );

    final myUser = AuthService.instance.currentUser;
    final myUid = myUser?.uid ?? '';
    final myName = myUser?.displayName ?? 'Player#0000';

    final recentOpponents = useMemoized(() {
      final matches = FirestoreMatchService.instance.getCachedUserMatches(myUid);
      final list = <({FriendProfile profile, String subtitle})>[];
      final seenUids = <String>{myUid, ...existingFriendUids};

      for (final m in matches) {
        final opp = m.opponentPlayer(myUid);
        if (opp == null || opp.uid.isEmpty || seenUids.contains(opp.uid)) continue;
        seenUids.add(opp.uid);

        final gameName = m.game == 'archery'
            ? 'Archery'
            : (m.game == 'darts' ? 'Darts' : 'Hoops');
        final isWin = m.isFinished && m.winnerUid == myUid;
        final isLoss = m.isFinished && m.winnerUid != null && m.winnerUid != myUid;
        final outcome = isWin ? 'you won' : (isLoss ? 'they won' : 'played');

        list.add((
          profile: FriendProfile(
            uid: opp.uid,
            displayName: opp.displayName,
            avatarEmoji: opp.avatarEmoji,
            addedAt: m.updatedAt,
          ),
          subtitle: '$gameName · $outcome',
        ));
        if (list.length >= 5) break;
      }
      return list;
    }, [myUid, existingFriendUids]);

    useEffect(() {
      return () => debounceTimer.value?.cancel();
    }, const []);

    void onSearchChanged(String val) {
      debounceTimer.value?.cancel();
      final query = val.trim();
      if (query.length < 2) {
        results.value = [];
        isSearching.value = false;
        return;
      }

      isSearching.value = true;
      debounceTimer.value = Timer(const Duration(milliseconds: 350), () async {
        final res = await FriendsService.instance.searchUsers(query, myUid);
        if (context.mounted) {
          results.value = res;
          isSearching.value = false;
        }
      });
    }

    Future<void> handleSendInvite(FriendProfile friend) async {
      HapticFeedback.mediumImpact();
      inviteError.value = null;
      final myProfile = AuthService.instance.currentUser;
      if (myProfile == null) return;
      invitedUids.value = {...invitedUids.value, friend.uid};
      try {
        await FriendsService.instance.sendFriendInvite(
          targetUid: friend.uid,
          myProfile: myProfile,
        );
        onFriendAdded?.call(friend);
      } catch (e) {
        invitedUids.value = {...invitedUids.value}..remove(friend.uid);
        if (context.mounted) {
          inviteError.value = (
            message: InlineErrorPanel.friendlyMessage(
              e,
              fallback: 'Couldn\'t send invite. Check connection.',
            ),
            retryFor: friend,
          );
        }
      }
    }

    void copyMyTag() {
      if (myUser == null) return;
      Clipboard.setData(ClipboardData(text: myUser.displayName));
      HapticFeedback.lightImpact();
      tagCopied.flash();
    }

    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      elevation: 0,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360.0, maxHeight: maxH),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1424),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xCC000000), blurRadius: 36.0, offset: Offset(0, 14)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add friend',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 3.0),
                              Text(
                                'Friends can challenge you straight from the lobby',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(18.0),
                          child: Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.close_rounded, size: 18.0, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Your Tag Card
                    AddFriendTagCard(
                      displayName: myName,
                      isCopied: tagCopied.isOn,
                      onCopy: copyMyTag,
                    ),
                    const SizedBox(height: 12.0),

                    // Search Input
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF090E1A),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFF1E2638)),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Name or tag, e.g. Dunker#6646',
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13.0),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 19.0),
                          suffixIcon: isSearching.value
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 14.0,
                                    height: 14.0,
                                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Color(0xFF00FFCC)),
                                  ),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          border: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            borderSide: const BorderSide(color: Color(0xFF00FFCC), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Inline Error
                    if (inviteError.value != null) ...[
                      InlineErrorPanel(
                        title: 'INVITE NOT SENT',
                        message: inviteError.value!.message,
                        onRetry: inviteError.value!.retryFor == null
                            ? null
                            : () => handleSendInvite(inviteError.value!.retryFor!),
                        onDismiss: () => inviteError.value = null,
                      ),
                      const SizedBox(height: 10.0),
                    ],

                    // Search Results or Played Recently
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (searchController.text.trim().length >= 2) ...[
                              _buildHeader('SEARCH RESULTS'),
                              const SizedBox(height: 6.0),
                              if (results.value.isEmpty && !isSearching.value)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(
                                    child: Text(
                                      'No players found',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                                    ),
                                  ),
                                )
                              else
                                AddFriendRecentCard(
                                  items: results.value.map((p) => (profile: p, subtitle: p.displayName)).toList(),
                                  invitedUids: invitedUids.value,
                                  friendUids: friendUids,
                                  onAdd: handleSendInvite,
                                ),
                            ] else ...[
                              _buildHeader('PLAYED RECENTLY'),
                              const SizedBox(height: 6.0),
                              if (recentOpponents.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(color: const Color(0xFF1E2638)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'No recent 1v1 rivals yet.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12.0),
                                  ),
                                )
                              else
                                AddFriendRecentCard(
                                  items: recentOpponents,
                                  invitedUids: invitedUids.value,
                                  friendUids: friendUids,
                                  onAdd: handleSendInvite,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Footer text
                    const Text(
                      'Not here? Type their name or tag above, or send them your tag.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11.0, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }
}
