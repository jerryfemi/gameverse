import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:b_ball/game/basketball_game.dart';
import 'package:b_ball/game/ui/game_over/game_over_actions.dart';
import 'package:b_ball/game/ui/game_over/game_over_header.dart';
import 'package:b_ball/game/ui/game_over/game_over_stats_grid.dart';
import 'package:b_ball/game/ui/inbox/match_inbox_sheet.dart';

/// Celebratory Game Over recap modal matching Design Template 20:
/// - "TIME'S UP" header with giant score and personal best subtitle
/// - 2x2 grid of 4 stat cards (Field Goals, Best Streak, Swishes, Bank Shots)
/// - PLAY AGAIN primary button
/// - Replay & Play 1v1 secondary action row
/// - FittedBox responsive scaling (< 140 lines)
class GameOverOverlay extends HookWidget {
  final BasketballGame game;

  const GameOverOverlay({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final animController = useAnimationController(
      duration: const Duration(milliseconds: 320),
    );

    final scaleAnimation = useMemoized(
      () => Tween<double>(begin: 0.90, end: 1.0).animate(
        CurvedAnimation(parent: animController, curve: Curves.easeOutBack),
      ),
      [animController],
    );

    final fadeAnimation = useMemoized(
      () => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animController, curve: Curves.easeOut),
      ),
      [animController],
    );

    useEffect(() {
      animController.forward();
      return null;
    }, const []);

    final maxH = MediaQuery.sizeOf(context).height * 0.90;

    return ValueListenableBuilder<GameRoundStats?>(
      valueListenable: game.statsNotifier,
      builder: (context, stats, _) {
        if (stats == null) return const SizedBox.shrink();

        final hasReplay = game.lastRoundTelemetry != null &&
            game.lastRoundTelemetry!.shots.isNotEmpty;

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 360.0, maxHeight: maxH),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1424),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: stats.isNewRecord
                            ? const Color(0xFF00FFCC).withValues(alpha: 0.6)
                            : const Color(0xFF1E293B),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xCC000000),
                          blurRadius: 36.0,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GameOverHeader(stats: stats),
                          const SizedBox(height: 20.0),
                          GameOverStatsGrid(stats: stats),
                          const SizedBox(height: 20.0),
                          GameOverActions(
                            onPlayAgain: () => game.exitToSoloMode(),
                            onReplay: hasReplay ? () => game.startReplayMode() : null,
                            onPlay1v1: () => MatchInboxSheet.openWithGame(
                              context,
                              game: game,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
