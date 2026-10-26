import 'package:flutter/material.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/section_label.dart';
import 'package:b_ball/social/ui/profile/widgets/matches_empty_state.dart';
import 'package:b_ball/social/ui/tiles/active_match_tile.dart';

/// Grouped list of active matches in [MatchesPage], categorized by:
/// 1. YOUR TURN
/// 2. WAITING ON THEM
/// 3. INVITES
class MatchesActiveList extends StatelessWidget {
  final List<CloudMatch> activeMatches;
  final String myUid;
  final VoidCallback onPlayAFriend;

  const MatchesActiveList({
    super.key,
    required this.activeMatches,
    required this.myUid,
    required this.onPlayAFriend,
  });

  @override
  Widget build(BuildContext context) {
    if (activeMatches.isEmpty) {
      return MatchesEmptyState(
        message: 'No active matches right now.',
        ctaLabel: 'Play a friend',
        onCta: onPlayAFriend,
      );
    }

    final yourTurn = activeMatches
        .where((m) =>
            m.status != MatchStatus.waitingForOpponent &&
            m.player2 != null &&
            m.isMyTurn(myUid))
        .toList();

    final waitingOnThem = activeMatches
        .where((m) =>
            m.status != MatchStatus.waitingForOpponent &&
            m.player2 != null &&
            !m.isMyTurn(myUid))
        .toList();

    final invites = activeMatches
        .where((m) =>
            m.status == MatchStatus.waitingForOpponent || m.player2 == null)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        if (yourTurn.isNotEmpty) ...[
          const SectionLabel(text: 'YOUR TURN'),
          for (final m in yourTurn) ActiveMatchTile(match: m, myUid: myUid),
          const SizedBox(height: 12.0),
        ],
        if (waitingOnThem.isNotEmpty) ...[
          const SectionLabel(text: 'WAITING ON THEM'),
          for (final m in waitingOnThem) ActiveMatchTile(match: m, myUid: myUid),
          const SizedBox(height: 12.0),
        ],
        if (invites.isNotEmpty) ...[
          const SectionLabel(text: 'INVITES'),
          for (final m in invites) ActiveMatchTile(match: m, myUid: myUid),
        ],
      ],
    );
  }
}
