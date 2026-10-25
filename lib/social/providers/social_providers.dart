import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/app_providers.dart';
import '../models/head_to_head.dart';

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

/// Riverpod provider checking whether [opponentUid] is in the current user's friends list.
final isFriendProvider =
    Provider.autoDispose.family<bool, String>((ref, opponentUid) {
  final friends = ref.watch(friendsListProvider).value ?? const [];
  return friends.any((f) => f.uid == opponentUid);
});
