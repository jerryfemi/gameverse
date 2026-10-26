import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/basketball_game.dart';
import 'package:b_ball/game/ui/common/app_modal_sheet.dart';
import 'package:b_ball/game/ui/common/edit_profile_dialog.dart';
import 'package:b_ball/game/ui/inbox/widgets/inbox_active_list.dart';
import 'package:b_ball/game/ui/inbox/widgets/inbox_completed_list.dart';
import 'package:b_ball/game/ui/inbox/widgets/inbox_header.dart';
import 'package:b_ball/game/ui/match/match_lobby_dialog.dart';
import 'package:b_ball/game/ui/match/match_setup_dialog.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
import 'package:b_ball/social/ui/results/results_sheet.dart';

/// The central 1v1 Match Hub bottom sheet modal.
class MatchInboxSheet extends HookConsumerWidget {
  final ValueChanged<CloudMatch> onPlayMatch;
  final VoidCallback onCreateMatch;
  final ValueChanged<CloudMatch>? onViewPodium;

  const MatchInboxSheet({
    super.key,
    required this.onPlayMatch,
    required this.onCreateMatch,
    this.onViewPodium,
  });

  /// Summon the Match Inbox sheet.
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<CloudMatch> onPlayMatch,
    required VoidCallback onCreateMatch,
    ValueChanged<CloudMatch>? onViewPodium,
  }) {
    return AppModalSheet.show<void>(
      context: context,
      builder: (ctx) => MatchInboxSheet(
        onPlayMatch: onPlayMatch,
        onCreateMatch: onCreateMatch,
        onViewPodium: onViewPodium ?? ((m) => ResultsSheet.show(ctx, m)),
      ),
    );
  }

  /// "Play a friend": create a 1v1 match (code or friend challenge) or join
  /// one with a code, then go into it. Used by the inbox and by the Hoops
  /// people button.
  static Future<void> playAFriend(
    BuildContext context, {
    required BasketballGame game,
  }) async {
    final config = await MatchSetupDialog.show(
      context,
      initialConfig: game.currentMatchConfig,
      showGamePicker: true,
    );
    final joined = config?.joinedMatch;
    if (joined != null) {
      final myUid = AuthService.instance.currentUser?.uid ?? '';
      game.startCloudMatch(joined, myUid);
      return;
    }
    if (config != null && context.mounted) {
      final user = await AuthService.instance.ensureAuthenticated();
      final profile =
          AuthService.instance.currentUser ??
          UserProfile(
            uid: user.uid,
            displayName: user.displayName ?? 'Player',
            avatarEmoji: PlayerDescriptor.defaultAvatar,
          );
      final newMatch = config.precreatedMatch ??
          await FirestoreMatchService.instance.createMatch(
            config: config,
            player1Profile: profile,
          );

      if (context.mounted) {
        MatchLobbyDialog.show(
          context: context,
          match: newMatch,
          challengedFriend: config.opponentFriend,
          onPlaySoloWhileWaiting: () {
            game.startCloudMatch(newMatch, profile.uid);
          },
          onEnterArena: (confirmedMatch) {
            game.startCloudMatch(confirmedMatch, profile.uid);
          },
        );
      }
    }
  }

  /// Convenience coordinator to open the Match Inbox and wire all cloud match actions
  /// (joining, creating lobby, playing, viewing podium) directly to the [BasketballGame].
  static Future<void> openWithGame(
    BuildContext context, {
    required BasketballGame game,
  }) async {
    final wasPlaying = game.gameStateNotifier.value == GameModeState.playing;
    if (wasPlaying) {
      game.pauseGame(manual: true);
    }
    await show(
      context,
      onPlayMatch: (match) {
        final myUid = AuthService.instance.currentUser?.uid ?? '';
        game.startCloudMatch(match, myUid);
      },
      onCreateMatch: () => playAFriend(context, game: game),
      onViewPodium: (match) {
        ResultsSheet.show(context, match);
      },
    );
    if (wasPlaying && game.isPaused) {
      game.resumeGame();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0); // 0: Live Matches, 1: Trophy History
    final myProfile = ref.watch(currentUserProfileProvider).value;
    final myUid = myProfile?.uid ?? '';

    return AppModalSheet(
      heightFactor: 0.85,
      header: InboxHeader(
        profile: myProfile,
        onEditProfile: () {
          if (myProfile != null) {
            EditProfileDialog.show(context, profile: myProfile);
          }
        },
        onClose: () => Navigator.of(context).pop(),
        onPlayMatch: onPlayMatch,
        onCreateMatch: onCreateMatch,
        onViewPodium: onViewPodium,
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),

          // Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTabPill(0, 'ACTIVE MATCHES', selectedTab),
                const SizedBox(width: 8),
                _buildTabPill(1, 'COMPLETED', selectedTab),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Match Lists: Active streams live, Completed lazily paginated
          Expanded(
            child: selectedTab.value == 0
                ? InboxActiveList(
                    myUid: myUid,
                    onPlayMatch: onPlayMatch,
                    onViewPodium: onViewPodium,
                  )
                : InboxCompletedList(
                    myUid: myUid,
                    onViewPodium: onViewPodium,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(
    int index,
    String label,
    ValueNotifier<int> selectedTab,
  ) {
    final isSelected = selectedTab.value == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        selectedTab.value = index;
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2638) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00FFCC)
                : const Color(0xFF26324A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF00FFCC)
                : const Color(0xFF94A3B8),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
