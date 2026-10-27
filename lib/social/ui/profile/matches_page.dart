import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/game/ui/match/match_setup_dialog.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/social/ui/profile/widgets/matches_active_list.dart';
import 'package:b_ball/social/ui/profile/widgets/matches_completed_list.dart';
import 'package:b_ball/social/ui/profile/widgets/matches_segmented_control.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/services/firestore_match_service.dart';

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

  const MatchesPage({super.key, this.initialTabIndex = 0, this.onClose});

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
    final user = ref.watch(currentUserProfileProvider).value;
    final myUid = (user != null && user.uid.isNotEmpty)
        ? user.uid
        : (AuthService.instance.currentUser?.uid ?? '');

    final cachedMatches = FirestoreMatchService.instance.getCachedUserMatches(
      myUid,
    );
    final allMatches =
        matchesAsync.value ?? (cachedMatches.isNotEmpty ? cachedMatches : null);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
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

            // Matches Async Loaded content with immediate cached fallback
            Expanded(
              child: allMatches != null
                  ? _buildMatchesContent(
                      context: context,
                      allMatches: allMatches,
                      myUid: myUid,
                      selectedTab: selectedTab,
                    )
                  : matchesAsync.when(
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
                      data: (matches) => _buildMatchesContent(
                        context: context,
                        allMatches: matches,
                        myUid: myUid,
                        selectedTab: selectedTab,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesContent({
    required BuildContext context,
    required List<CloudMatch> allMatches,
    required String myUid,
    required ValueNotifier<int> selectedTab,
  }) {
    final activeMatches = allMatches.where((m) => !m.isFinished).toList();
    final completedMatches = allMatches.where((m) => m.isFinished).toList()
      ..sort((a, b) {
        final aTime = a.updatedAt > 0 ? a.updatedAt : a.createdAt;
        final bTime = b.updatedAt > 0 ? b.updatedAt : b.createdAt;
        return bTime.compareTo(aTime);
      });

    return Column(
      children: [
        // Segmented Control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: MatchesSegmentedControl(
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
              ? MatchesActiveList(
                  activeMatches: activeMatches,
                  myUid: myUid,
                  onPlayAFriend: () => _playAFriend(context),
                )
              : MatchesCompletedList(
                  completedMatches: completedMatches,
                  myUid: myUid,
                  onPlayAFriend: () => _playAFriend(context),
                ),
        ),
      ],
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
