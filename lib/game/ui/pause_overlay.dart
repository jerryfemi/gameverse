import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/game/basketball_game.dart';
import 'package:b_ball/game/performance/adaptive_quality.dart';
import 'package:b_ball/game/ui/pause/widgets/pause_action_buttons.dart';
import 'package:b_ball/game/ui/pause/widgets/pause_forfeit_dialog.dart';
import 'package:b_ball/game/ui/pause/widgets/pause_sound_card.dart';
import 'package:b_ball/game/ui/pause/widgets/pause_stat_chip.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';

/// Hoops Pause Overlay matching Design Template 21:
/// - "Paused" header with round and mode subtitle
/// - 3 stat chips: SCORE, CLOCK, STREAK
/// - SOUND section with volume sliders, track selector, streak FX, and graphics quality
/// - RESUME button + Restart/Forfeit & Lobby buttons
/// - FittedBox responsive scaling (< 250 lines)
class PauseOverlay extends HookWidget {
  final BasketballGame game;

  const PauseOverlay({super.key, required this.game});

  static const Color accentGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final session = useValueListenable(game.matchSessionNotifier);
    final score = useValueListenable(game.scoreNotifier);
    final clock = useValueListenable(game.timeRemainingNotifier);
    final streak = useValueListenable(game.streakNotifier);
    final difficulty = useValueListenable(game.soloDifficultyNotifier);
    final currentTrackIdx = useValueListenable(AudioEngine.currentTrackIndexNotifier);
    final isOnlineMatch = session != null;

    final String subtitle = isOnlineMatch
        ? '1v1 vs ${session.player2.name} · round ${session.currentRoundIndex + 1}'
        : 'Solo · round 1 · ${difficulty.label}';

    final trackName = AudioEngine.availableTracks.isNotEmpty
        ? AudioEngine.availableTracks[currentTrackIdx.clamp(0, AudioEngine.availableTracks.length - 1)].title
        : 'Godzilla';

    Future<void> handleForfeit() async {
      final confirmed = await PauseForfeitDialog.show(context);
      if (confirmed && context.mounted && session != null) {
        HapticFeedback.heavyImpact();
        final myUid = AuthService.instance.currentUser?.uid ?? '';
        final cloudMatchId = session.cloudMatchId;
        final opponent = session.player2;

        if (cloudMatchId != null && myUid.isNotEmpty) {
          unawaited(
            FirestoreMatchService.instance.forfeitMatch(
              matchId: cloudMatchId,
              forfeiterUid: myUid,
              winnerUid: opponent.id.isNotEmpty && opponent.id != 'them' ? opponent.id : '',
            ),
          );
        }
        game.exitToSoloMode();
      }
    }

    final maxH = MediaQuery.sizeOf(context).height * 0.90;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360.0, maxHeight: maxH),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1424),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0xCC000000), blurRadius: 36.0, offset: Offset(0, 14)),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Subtitle
                  Text(
                    'Paused',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // 3 Stat Chips: SCORE, CLOCK, STREAK
                  Row(
                    children: [
                      Expanded(child: PauseStatChip(label: 'SCORE', value: '$score')),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: PauseStatChip(
                          label: 'CLOCK',
                          value: '${clock}s',
                          valueColor: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: PauseStatChip(
                          label: 'STREAK',
                          value: '$streak',
                          valueColor: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // SOUND Section Header
                  const Text(
                    'SOUND',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6.0),

                  // Sound & Settings Card
                  PauseSoundCard(
                    accentColor: accentGreen,
                    trackName: trackName,
                    onCycleTrack: () {
                      HapticFeedback.selectionClick();
                      final next = (currentTrackIdx + 1) % AudioEngine.availableTracks.length;
                      AudioEngine.selectTrack(next);
                    },
                    streakFxRow: _buildStreakFxRow(),
                    graphicsRow: _buildGraphicsRow(),
                  ),
                  const SizedBox(height: 20.0),

                  // Action Buttons: Resume / (Restart or Forfeit) / Lobby
                  PauseActionButtons(
                    accentColor: accentGreen,
                    onResume: game.resumeGame,
                    onLobby: () {
                      game.resumeGame();
                      GoRouter.maybeOf(context)?.go('/games');
                    },
                    onRestart: isOnlineMatch ? null : game.restartRound,
                    onForfeit: isOnlineMatch ? handleForfeit : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakFxRow() {
    return ValueListenableBuilder<bool>(
      valueListenable: game.streakFxEnabledNotifier,
      builder: (context, enabled, _) {
        return Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak effects',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 1.0),
                  Text(
                    'Lightning at 3, fire at 6',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11.0),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (_) {
                HapticFeedback.selectionClick();
                unawaited(game.toggleStreakFx());
              },
              activeThumbColor: accentGreen,
              activeTrackColor: accentGreen.withValues(alpha: 0.35),
              inactiveThumbColor: const Color(0xFF64748B),
              inactiveTrackColor: const Color(0xFF1E2638),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGraphicsRow() {
    return ValueListenableBuilder<QualityMode>(
      valueListenable: game.quality.modeNotifier,
      builder: (context, mode, _) {
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            unawaited(game.quality.cycleMode());
          },
          borderRadius: BorderRadius.circular(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Text(
                  'Graphics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${mode.label}  >',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
