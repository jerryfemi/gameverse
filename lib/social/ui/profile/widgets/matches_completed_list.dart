import 'package:flutter/material.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/profile/widgets/matches_empty_state.dart';
import 'package:b_ball/social/ui/tiles/completed_match_tile.dart';

/// Chronological list of completed matches in [MatchesPage].
class MatchesCompletedList extends StatelessWidget {
  final List<CloudMatch> completedMatches;
  final String myUid;
  final VoidCallback onPlayAFriend;

  const MatchesCompletedList({
    super.key,
    required this.completedMatches,
    required this.myUid,
    required this.onPlayAFriend,
  });

  @override
  Widget build(BuildContext context) {
    if (completedMatches.isEmpty) {
      return MatchesEmptyState(
        message: 'No completed matches yet.',
        ctaLabel: 'Play a friend',
        onCta: onPlayAFriend,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: completedMatches.length,
      itemBuilder: (ctx, i) {
        final match = completedMatches[i];
        return CompletedMatchTile(
          match: match,
          myUid: myUid,
        );
      },
    );
  }
}
