import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/paintball/paintball_game.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/ui/paintball_hud.dart';
import 'package:b_ball/paintball/ui/paintball_controls.dart';

/// Full-screen Paintball Duel Screen (`/paintball`).
///
/// Features:
/// - Real-time Flame game canvas with 2.5D perspective and camera pan.
/// - HUD with live health pips, round timer, and ammo counters.
/// - Dual-thumb touch controls for lane sliding, stance changes, and firing.
/// - Game-over results card with full career statistics.
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
                    return _buildGameOverOverlay(context, game);
                  }
                  return PaintballControlsOverlay(game: game);
                },
              ),
        },
        initialActiveOverlays: const ['HUD', 'Controls'],
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, PaintballGame game) {
    final you = game.match.you;
    final isWinner = game.match.winner == PaintballWinner.you;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isWinner ? const Color(0xFF00FFCC) : const Color(0xFFEF4444),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isWinner ? const Color(0xFF00FFCC) : const Color(0xFFEF4444))
                  .withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWinner ? 'VICTORY!' : 'DEFEAT',
              style: TextStyle(
                color: isWinner ? const Color(0xFF00FFCC) : const Color(0xFFEF4444),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isWinner
                ? 'You eliminated the opponent!'
                : 'You took 3 hits. Better luck next time!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Table
            _buildStatRow('Hits Scored', '${you.shotsHit}'),
            _buildStatRow('Shots Fired', '${you.shotsFired}'),
            _buildStatRow('Accuracy', '${you.accuracyPercent.toStringAsFixed(1)}%'),
            _buildStatRow('Times Dodged', '${you.timesDodged}'),
            _buildStatRow('Longest Survival', '${you.longestSurvivalSeconds.toStringAsFixed(1)} s'),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (context.mounted) context.go('/');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('LOBBY', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      game.match.startMatch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0A0E1A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('PLAY AGAIN', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontFamily: 'Inter')),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}
