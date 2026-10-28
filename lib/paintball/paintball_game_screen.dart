import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/paintball/paintball_game.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/ui/paintball_hud.dart';
import 'package:b_ball/paintball/ui/paintball_controls.dart';
import 'package:b_ball/paintball/ui/paintball_result_card.dart';

/// Full-screen Paintball Duel Screen (`/paintball`).
///
/// Features:
/// - Real-time Flame game canvas with 2.5D perspective and camera pan.
/// - HUD with live health pips, round timer, and ammo counters.
/// - 3-2-1 pre-match countdown banner.
/// - Dual-thumb touch controls for lane sliding, stance changes, and firing.
/// - High-fidelity GameVerse results card with full career statistics.
class PaintballGameScreen extends StatefulWidget {
  const PaintballGameScreen({super.key});

  @override
  State<PaintballGameScreen> createState() => _PaintballGameScreenState();
}

class _PaintballGameScreenState extends State<PaintballGameScreen> {
  late final PaintballGame _game;

  @override
  void initState() {
    super.initState();
    _game = PaintballGame();
    AudioEngine.silenceForLobby();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: GameWidget<PaintballGame>(
        game: _game,
        overlayBuilderMap: {
          'HUD': (context, game) => StreamBuilder<void>(
                stream: Stream.periodic(const Duration(milliseconds: 100)),
                builder: (context, _) => PaintballHudOverlay(match: game.match),
              ),
          'Controls': (context, game) => StreamBuilder<void>(
                stream: Stream.periodic(const Duration(milliseconds: 50)),
                builder: (context, _) {
                  if (game.match.phase == PaintballMatchPhase.gameOver) {
                    return PaintballResultCard(
                      match: game.match,
                      onRematch: () {
                        game.match.startMatch();
                      },
                      onLobby: () {
                        if (context.mounted) context.go('/');
                      },
                    );
                  }
                  return Stack(
                    children: [
                      PaintballControlsOverlay(game: game),
                      if (game.match.phase == PaintballMatchPhase.countdown)
                        _buildCountdownBanner(game),
                    ],
                  );
                },
              ),
        },
        initialActiveOverlays: const ['HUD', 'Controls'],
      ),
    );
  }

  Widget _buildCountdownBanner(PaintballGame game) {
    final count = game.match.countdownRemaining.ceil();
    final text = count > 1 ? '$count' : (count == 1 ? '1' : 'DUEL!');
    final subtitle = count > 1 ? 'GET READY' : (count == 1 ? 'TAKE COVER!' : 'FIRE AT WILL!');

    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xCC0B1020),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: UiFont.style(
                  size: 42,
                  weight: 900,
                  color: const Color(0xFF00FFCC),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: UiFont.style(
                  size: 13,
                  weight: 700,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
