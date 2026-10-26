import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/inbox/match_inbox_card.dart';
import 'package:b_ball/game/ui/inbox/match_thread_dialog.dart';
import 'package:b_ball/game/ui/inbox/widgets/inbox_leave_dialog.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/providers/app_providers.dart';

/// Live active matches tab feed for the Match Inbox sheet.
///
/// Watches [activeMatchesProvider] so only live and waiting matches are streamed.
/// Displays matches sorted with player turn priority at the top.
class InboxActiveList extends ConsumerWidget {
  final String myUid;
  final ValueChanged<CloudMatch> onPlayMatch;
  final ValueChanged<CloudMatch>? onViewPodium;

  const InboxActiveList({
    super.key,
    required this.myUid,
    required this.onPlayMatch,
    this.onViewPodium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(activeMatchesProvider);

    if (matchesAsync.isLoading && !matchesAsync.hasValue) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF00FFCC),
        ),
      );
    }

    final allMatches = matchesAsync.value ?? const <CloudMatch>[];
    final liveMatches = allMatches.where((m) => !m.isFinished).toList()
      ..sort((a, b) {
        final aTurn = a.isMyTurn(myUid) ? 0 : 1;
        final bTurn = b.isMyTurn(myUid) ? 0 : 1;
        return aTurn.compareTo(bTurn);
      });

    if (liveMatches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: liveMatches.length,
      itemBuilder: (ctx, i) {
        final match = liveMatches[i];
        return MatchInboxCard(
          match: match,
          myUid: myUid,
          onTap: () {
            MatchThreadDialog.show(
              context,
              match: match,
              myUid: myUid,
              onPlayTurn: () {
                Navigator.of(context).pop();
                onPlayMatch(match);
              },
              onViewPodium: () {
                Navigator.of(context).pop();
                onViewPodium?.call(match);
              },
            );
          },
          onPlayTurn: () {
            Navigator.of(context).pop();
            onPlayMatch(match);
          },
          onViewPodium: () {
            Navigator.of(context).pop();
            onViewPodium?.call(match);
          },
          onLeave: () => showInboxLeaveDialog(
            context: context,
            match: match,
            myUid: myUid,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_basketball_outlined,
              size: 40,
              color: Color(0xFF475569),
            ),
            SizedBox(height: 10),
            Text(
              'No live challenges right now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap the people button in a game to play a friend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
