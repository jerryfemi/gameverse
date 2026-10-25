import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/game/ui/match/match_setup_dialog.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/social/ui/common/section_label.dart';
import 'package:b_ball/social/ui/tiles/active_match_tile.dart';
import 'package:b_ball/social/ui/tiles/completed_match_tile.dart';

/// Full matches overview screen adhering to Artboard 10 of GameVerse design.
///
/// Built with flutter_hooks + hooks_riverpod:
/// - Segmented control: Active · n / Completed · n.
/// - Active section grouped into YOUR TURN, WAITING ON THEM, and INVITES.
/// - Completed section displaying chronological CompletedMatchTile list (newest first).
/// - Clean empty states with "Play a friend" action.
class MatchesPage extends HookConsumerWidget {
  final int initialTabIndex; // 0 = Active, 1 = Completed
  final VoidCallback? onClose;

  const MatchesPage({
    super.key,
    this.initialTabIndex = 0,
    this.onClose,
  });

  void _playAFriend(BuildContext context) {
    HapticFeedback.lightImpact();
    MatchSetupDialog.show(
      context,
      initialConfig: const MatchConfig(),
      showGamePicker: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(initialTabIndex);
    final matchesAsync = ref.watch(userMatchesProvider);
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
                    'Matches',
                    style: UiFont.style(
                      size: 26.0,
                      weight: 900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  _buildCircleButton(
                    icon: Icons.close_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onClose != null) {
                        onClose!();
                      } else {
                        Navigator.of(context, rootNavigator: true).maybePop();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Matches Async Loaded content
            Expanded(
              child: matchesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FFCC),
                    strokeWidth: 2.5,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Failed to load matches',
                    style: UiFont.style(
                      size: 14.0,
                      weight: 600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
                data: (allMatches) {
                  final activeMatches =
                      allMatches.where((m) => !m.isFinished).toList();
                  final completedMatches =
                      allMatches.where((m) => m.isFinished).toList()
                        ..sort((a, b) {
                          final aTime =
                              a.updatedAt > 0 ? a.updatedAt : a.createdAt;
                          final bTime =
                              b.updatedAt > 0 ? b.updatedAt : b.createdAt;
                          return bTime.compareTo(aTime);
                        });

                  return Column(
                    children: [
                      // Segmented Control
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 6.0,
                        ),
                        child: _buildSegmentedControl(
                          activeCount: activeMatches.length,
                          completedCount: completedMatches.length,
                          selectedTab: selectedTab.value,
                          onTabChanged: (index) {
                            if (selectedTab.value != index) {
                              HapticFeedback.selectionClick();
                              selectedTab.value = index;
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8.0),

                      // Tab View List
                      Expanded(
                        child: selectedTab.value == 0
                            ? _buildActiveList(context, activeMatches, myUid)
                            : _buildCompletedList(
                                context,
                                completedMatches,
                                myUid,
                              ),
                      ),
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
  // Segmented Control: Active · n / Completed · n
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedControl({
    required int activeCount,
    required int completedCount,
    required int selectedTab,
    required ValueChanged<int> onTabChanged,
  }) {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              title: 'Active · $activeCount',
              isSelected: selectedTab == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          const SizedBox(width: 4.0),
          Expanded(
            child: _buildSegmentButton(
              title: 'Completed · $completedCount',
              isSelected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF1E2638) : Colors.transparent,
      borderRadius: BorderRadius.circular(10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Center(
          child: Text(
            title,
            style: UiFont.style(
              size: 13.0,
              weight: isSelected ? 800 : 600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 0: Active Matches (Grouped)
  // ---------------------------------------------------------------------------
  Widget _buildActiveList(
    BuildContext context,
    List<CloudMatch> activeMatches,
    String myUid,
  ) {
    if (activeMatches.isEmpty) {
      return _buildEmptyState(
        message: 'No active matches right now.',
        ctaLabel: 'Play a friend',
        onCta: () => _playAFriend(context),
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

  // ---------------------------------------------------------------------------
  // Tab 1: Completed Matches
  // ---------------------------------------------------------------------------
  Widget _buildCompletedList(
    BuildContext context,
    List<CloudMatch> completedMatches,
    String myUid,
  ) {
    if (completedMatches.isEmpty) {
      return _buildEmptyState(
        message: 'No completed matches yet.',
        ctaLabel: 'Play a friend',
        onCta: () => _playAFriend(context),
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

  // ---------------------------------------------------------------------------
  // Empty State Widget
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState({
    required String message,
    required String ctaLabel,
    required VoidCallback onCta,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: UiFont.style(
                size: 14.5,
                weight: 600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                elevation: 0,
              ),
              child: Text(
                ctaLabel,
                style: UiFont.style(
                  size: 13.5,
                  weight: 800,
                  color: const Color(0xFF0F172A),
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
