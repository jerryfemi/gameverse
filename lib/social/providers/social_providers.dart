import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/social/models/head_to_head.dart';

/// Client-side Riverpod provider computing Head-to-Head performance records
/// between the authenticated player and a specified [opponentUid].
final headToHeadProvider =
    Provider.autoDispose.family<HeadToHead, String>((ref, opponentUid) {
  final user = ref.watch(currentUserProfileProvider).value;
  final myUid = user?.uid ?? '';
  final allMatches = ref.watch(userMatchesProvider).value ?? const [];

  return HeadToHead.fromMatches(
    myUid: myUid,
    opponentUid: opponentUid,
    allMatches: allMatches,
  );
});

/// Real-time friendship status between the authenticated user and an opponent.
enum FriendshipStatus {
  /// Not friends, and no outgoing request has been dispatched.
  none,

  /// An invite has been dispatched and is pending recipient confirmation.
  pending,

  /// Established friend in the player's active social circle.
  friend,
}

/// Tracks UIDs to which friend requests were dispatched during this app session.
class SentFriendRequestsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void markSent(String uid) {
    if (!state.contains(uid)) {
      state = {...state, uid};
    }
  }
}

final sentFriendRequestsProvider =
    NotifierProvider<SentFriendRequestsNotifier, Set<String>>(
  SentFriendRequestsNotifier.new,
);

/// Tracks session keys where the 2-second "+ Add to friends" intro chip has been shown.
class ShownIntroChipSessionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void markShown(String sessionKey) {
    if (!state.contains(sessionKey)) {
      state = {...state, sessionKey};
    }
  }
}

final shownIntroChipSessionsProvider =
    NotifierProvider<ShownIntroChipSessionsNotifier, Set<String>>(
  ShownIntroChipSessionsNotifier.new,
);

/// Riverpod provider computing [FriendshipStatus] for [opponentUid].
final friendshipStatusProvider =
    Provider.autoDispose.family<FriendshipStatus, String>((ref, opponentUid) {
  if (opponentUid.isEmpty || opponentUid == 'cpu') {
    return FriendshipStatus.none;
  }

  final friends = ref.watch(friendsListProvider).value ?? const [];
  if (friends.any((f) => f.uid == opponentUid)) {
    return FriendshipStatus.friend;
  }

  final incoming = ref.watch(incomingInvitesProvider).value ?? const [];
  if (incoming.any((i) => i.senderUid == opponentUid && i.status == 'pending')) {
    return FriendshipStatus.pending;
  }

  final sent = ref.watch(sentFriendRequestsProvider);
  if (sent.contains(opponentUid)) {
    return FriendshipStatus.pending;
  }

  return FriendshipStatus.none;
});

/// Riverpod provider checking whether [opponentUid] is in the current user's friends list.
final isFriendProvider =
    Provider.autoDispose.family<bool, String>((ref, opponentUid) {
  final status = ref.watch(friendshipStatusProvider(opponentUid));
  return status == FriendshipStatus.friend;
});

