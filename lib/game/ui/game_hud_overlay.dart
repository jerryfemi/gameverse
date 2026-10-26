import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/game/basketball_game.dart';
import 'package:b_ball/game/match/match_session.dart';
import 'package:b_ball/services/update/update_service.dart';
import 'package:b_ball/game/ui/common/update_available_banner.dart';
import 'package:b_ball/game/ui/floating_score_toast.dart';
import 'package:b_ball/game/ui/game_over_overlay.dart';
import 'package:b_ball/game/ui/game_rules_dialog.dart';
import 'package:b_ball/game/ui/match/match_winner_podium_overlay.dart';
import 'package:b_ball/game/ui/match/round_intermission_overlay.dart';
import 'package:b_ball/game/ui/pause_overlay.dart';
import 'package:b_ball/game/ui/replay_hud_overlay.dart';
import 'package:b_ball/game/ui/inbox/match_inbox_sheet.dart';
import 'package:b_ball/game/ui/stadium_scoreboard.dart';
import 'package:b_ball/game/ui/tour/onboarding_tour_overlay.dart';
import 'package:b_ball/notifications/notice_stack.dart';
import 'package:b_ball/social/ui/profile/profile_sheet.dart';
import 'package:b_ball/game/ui/common/lobby_pill.dart';
import 'package:b_ball/game/ui/play_friend_button.dart';
import 'package:b_ball/game/ui/match/live_spectator_status_pill.dart';
import 'package:b_ball/game/ui/match/live_turn_transition_overlay.dart';
import 'package:b_ball/game/ui/reactions/live_floating_reactions_overlay.dart';

import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/social/ui/in_game/in_game_h2h_overlay.dart';
import 'package:b_ball/social/ui/in_game/in_game_h2h_panel.dart';

/// Top-level Game HUD Overlay mounted via Flame's [GameWidget.overlayBuilderMap].
class GameHudOverlay extends HookConsumerWidget {
  final BasketballGame game;

  const GameHudOverlay({super.key, required this.game});

  Future<void> _handleHelpTapped(BuildContext context) async {
    final wasPlaying = game.gameStateNotifier.value == GameModeState.playing;
    if (wasPlaying) {
      game.pauseGame(manual: true);
    }
    await showGameRulesDialog(context, game: game);
    if (wasPlaying && game.isPaused) {
      game.resumeGame();
    }
  }

  Future<void> _handleInboxTapped(BuildContext context) =>
      MatchInboxSheet.openWithGame(context, game: game);

  /// Your avatar opens the profile sheet: what's waiting, friends, matches.
  Future<void> _openDrawer(BuildContext context) => ProfileSheet.show(
    context,
    onOpenMatch: (m) =>
        game.startCloudMatch(m, AuthService.instance.currentUser?.uid ?? ''),
    onOpenMatches: () => _handleInboxTapped(context),
    onPlayFriend: () => MatchInboxSheet.playAFriend(context, game: game),
    onHowToPlay: () => _handleHelpTapped(context),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h2hState = useState<InGameH2HState>(InGameH2HState.closed);
    final user = ref.watch(currentUserProfileProvider).value;
    final session = useValueListenable(game.matchSessionNotifier);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Top Stadium Scoreboard Header with integrated controls & match hub
        Align(
          alignment: Alignment.topCenter,
          child: StadiumScoreboard(
            game: game,
            onHelpTapped: () => _handleHelpTapped(context),
            onInboxTapped: () => _openDrawer(context),
            onOpponentAvatarTap: () {
              if (session != null &&
                  session.cloudMatchId != null &&
                  session.player2.id.isNotEmpty &&
                  session.player2.id != 'cpu') {
                h2hState.value = InGameH2HState.peek;
              }
            },
          ),
        ),

        // 1b. Update Available Notification Pill (Positioned right below scoreboard header)
        Positioned(
          top: MediaQuery.of(context).padding.top + 72.0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: UpdateService.isUpdateAvailable,
            builder: (context, hasUpdate, _) {
              if (!hasUpdate) return const SizedBox.shrink();
              return const Center(child: UpdateAvailableBanner());
            },
          ),
        ),

        // 1c. Notifications from any game (invites, friend requests) at the
        //     top. In a live 1v1 they shrink to bubbles on the right edge.
        ValueListenableBuilder<MatchSession?>(
          valueListenable: game.matchSessionNotifier,
          builder: (context, session, _) {
            final bool live = session != null && session.isOnline;
            return Positioned(
              // Solo: below the Lobby pill and the people button.
              top: MediaQuery.of(context).padding.top + (live ? 62.0 : 112.0),
              left: 16.0,
              right: live ? 12.0 : 16.0,
              child: NoticeStack(
                live: live,
                onBeforeOpen: () {
                  if (game.gameStateNotifier.value == GameModeState.playing) {
                    game.pauseGame(manual: true);
                  }
                },
                onOpenMatch: (m) {
                  final myUid = AuthService.instance.currentUser?.uid ?? '';
                  game.startCloudMatch(m, myUid);
                },
              ),
            );
          },
        ),

        // 1d. Live Spectator Connection & Grace Guard Pill (mounted strictly during active 1v1 spectator phase)
        Positioned(
          top: MediaQuery.of(context).padding.top + 76.0,
          left: 16.0,
          right: 16.0,
          child: ValueListenableBuilder<MatchSession?>(
            valueListenable: game.matchSessionNotifier,
            builder: (context, session, _) {
              if (session == null ||
                  session.phase != MatchTurnPhase.watchingLiveOpponent) {
                return const SizedBox.shrink();
              }
              return LiveSpectatorStatusPill(game: game);
            },
          ),
        ),

        // 2. Floating Score Toasts: callouts pop beside the hoop (never over
        //    the rim); the streak-bonus chip stays under the scoreboard.
        //    Full-screen so the system can place each part itself.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: FloatingScoreToastSystem(game: game),
          ),
        ),

        // 3a. "‹ Lobby" top-left (solo only; hidden when paused, game over, replay, or tour is active)
        Positioned(
          top: MediaQuery.of(context).padding.top + 62.0,
          left: 12.0,
          child: ListenableBuilder(
            listenable: Listenable.merge([
              game.matchSessionNotifier,
              game.isPausedNotifier,
              game.gameStateNotifier,
              game.isTourActiveNotifier,
            ]),
            builder: (context, _) {
              final isModalOrInactive =
                  game.matchSessionNotifier.value != null ||
                  game.isPausedNotifier.value ||
                  game.gameStateNotifier.value == GameModeState.gameOver ||
                  game.gameStateNotifier.value == GameModeState.replay ||
                  game.isTourActiveNotifier.value;

              if (isModalOrInactive) return const SizedBox.shrink();

              return LobbyPill(onTap: () => GoRouter.maybeOf(context)?.go('/'));
            },
          ),
        ),

        // 3b. "Play a friend" button under the sound button (solo only; hidden during modals)
        Positioned(
          top: MediaQuery.of(context).padding.top + 62.0,
          right: 12.0,
          child: ListenableBuilder(
            listenable: Listenable.merge([
              game.matchSessionNotifier,
              game.isPausedNotifier,
              game.gameStateNotifier,
              game.isTourActiveNotifier,
            ]),
            builder: (context, _) {
              final isModalOrInactive =
                  game.matchSessionNotifier.value != null ||
                  game.isPausedNotifier.value ||
                  game.gameStateNotifier.value == GameModeState.gameOver ||
                  game.gameStateNotifier.value == GameModeState.replay ||
                  game.isTourActiveNotifier.value;

              if (isModalOrInactive) return const SizedBox.shrink();

              return PlayFriendButton(
                key: game.playFriendKey,
                onTap: () => MatchInboxSheet.playAFriend(context, game: game),
              );
            },
          ),
        ),

        // 4. Pause Overlay (Displayed when game is paused and not gameOver)
        ValueListenableBuilder<bool>(
          valueListenable: game.isPausedNotifier,
          builder: (context, isPaused, _) {
            if (isPaused &&
                game.gameStateNotifier.value != GameModeState.gameOver) {
              return PauseOverlay(game: game);
            }
            return const SizedBox.shrink();
          },
        ),

        // 5. Game Over / Match Intermission / Match Winner Podium Overlays
        ValueListenableBuilder<GameModeState>(
          valueListenable: game.gameStateNotifier,
          builder: (context, state, _) {
            if (state == GameModeState.gameOver) {
              return ValueListenableBuilder<MatchSession?>(
                valueListenable: game.matchSessionNotifier,
                builder: (context, session, _) {
                  if (session != null) {
                    if (session.phase == MatchTurnPhase.matchComplete) {
                      return MatchWinnerPodiumOverlay(
                        game: game,
                        session: session,
                      );
                    } else if (session.phase == MatchTurnPhase.turnComplete) {
                      return RoundIntermissionOverlay(
                        game: game,
                        session: session,
                      );
                    }
                  }
                  return GameOverOverlay(game: game);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // 6. Replay HUD Overlay (Displayed when watching replay mode)
        ValueListenableBuilder<GameModeState>(
          valueListenable: game.gameStateNotifier,
          builder: (context, state, _) {
            if (state == GameModeState.replay) {
              return ReplayHudOverlay(game: game);
            }
            return const SizedBox.shrink();
          },
        ),

        // 7. First-Launch / Replay Onboarding Tour Overlay
        ValueListenableBuilder<bool>(
          valueListenable: game.isTourActiveNotifier,
          builder: (context, isTourActive, _) {
            if (isTourActive) {
              return OnboardingTourOverlay(game: game);
            }
            return const SizedBox.shrink();
          },
        ),

        // 7. Live Floating Reactions Overlay (Left-court track + spectator banter dock)
        LiveFloatingReactionsOverlay(game: game),

        // 8. Live Turn Transition Interstitial Overlay (3-2-1 countdown)
        ValueListenableBuilder<LiveTransitionData?>(
          valueListenable: game.liveTransitionNotifier,
          builder: (context, data, _) {
            if (data == null) return const SizedBox.shrink();
            return LiveTurnTransitionOverlay(
              isMyTurnNow: data.isMyTurnNow,
              opponentName: data.opponentName,
              currentRound: data.currentRound,
              totalRounds: data.totalRounds,
              onFinished: data.onFinished,
            );
          },
        ),

        // 9. In-Game Head-to-Head Peek & Full Panel Overlay (Artboards 3, 4)
        if (h2hState.value != InGameH2HState.closed && session != null)
          InGameH2HOverlay(
            state: h2hState.value,
            myUid: user?.uid ?? '',
            myAvatar: user?.avatarEmoji,
            opponentUid: session.player2.id,
            opponentName: session.player2.name,
            opponentAvatar: session.player2.avatar,
            defaultGame: 'basketball',
            footerSummary: _buildHoopsFooter(
              session.player2.name,
              session.player2.totalScore,
              () => h2hState.value = InGameH2HState.closed,
            ),
            onExpand: () => h2hState.value = InGameH2HState.full,
            onCollapse: () => h2hState.value = InGameH2HState.closed,
            onClose: () => h2hState.value = InGameH2HState.closed,
            turnCountdown: session.cloudMatchId != null &&
                    session.activePlayerIndex == 0
                ? game.timeRemainingNotifier.value
                : null,
            isOnline: session.cloudMatchId != null,
            isMyTurn: session.activePlayerIndex == 0,
            onPauseEngine: () => game.pauseGame(manual: true),
            onResumeEngine: () => game.resumeGame(),
          ),
      ],
    );
  }

  Widget _buildHoopsFooter(String name, int score, VoidCallback onTap) {
    return Material(
      color: const Color(0xCC0F172A),
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0x22FFFFFF), width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${name.toUpperCase()} · $score PTS',
                style: UiFont.style(
                  size: 11.5,
                  weight: 800,
                  color: const Color(0xFFF59E0B),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6.0),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18.0,
                color: Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
