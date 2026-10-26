import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/inbox/match_inbox_card.dart';
import 'package:b_ball/game/ui/inbox/providers/completed_matches_provider.dart';
import 'package:b_ball/game/ui/inbox/widgets/inbox_leave_dialog.dart';
import 'package:b_ball/models/cloud_match.dart';

/// Lazy-loaded, paginated completed matches list for the Match Inbox sheet.
///
/// Fetches page 1 on-demand when the Completed tab opens.
/// Triggers cursor-based pagination as the user scrolls near the bottom.
class InboxCompletedList extends HookConsumerWidget {
  final String myUid;
  final ValueChanged<CloudMatch>? onViewPodium;

  const InboxCompletedList({
    super.key,
    required this.myUid,
    this.onViewPodium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final completedState = ref.watch(completedMatchesProvider);

    // Initial load on first tab open
    useEffect(() {
      Future.microtask(() {
        ref.read(completedMatchesProvider.notifier).loadInitial();
      });
      return null;
    }, const []);

    // Pagination trigger on scroll near bottom
    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) return;
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          ref.read(completedMatchesProvider.notifier).loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    if (completedState.isLoading && completedState.matches.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF00FFCC),
        ),
      );
    }

    if (completedState.matches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF00FFCC),
      backgroundColor: const Color(0xFF131826),
      onRefresh: () => ref.read(completedMatchesProvider.notifier).refresh(),
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: completedState.matches.length +
            (completedState.isLoadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == completedState.matches.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00FFCC),
                  ),
                ),
              ),
            );
          }

          final match = completedState.matches[i];
          return MatchInboxCard(
            match: match,
            myUid: myUid,
            onTap: () {
              Navigator.of(context).pop();
              onViewPodium?.call(match);
            },
            onPlayTurn: () {
              Navigator.of(context).pop();
              onViewPodium?.call(match);
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
      ),
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
              Icons.emoji_events_outlined,
              size: 40,
              color: Color(0xFF475569),
            ),
            SizedBox(height: 10),
            Text(
              'No completed matches yet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Finished games and winner podiums will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
