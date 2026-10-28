import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

  /// Looping theme (loop points are trimmed to the first/last real sample).
  static const String themeTrack = 'assets/paintball/pb_theme.mp3';

  @override
  State<PaintballGameScreen> createState() => _PaintballGameScreenState();
}

class _PaintballGameScreenState extends State<PaintballGameScreen> {
  late final PaintballGame _game;

  @override
  void initState() {
    super.initState();
    _game = PaintballGame();
    // Paintball's own sounds (decoded only now) and its theme while open.
    unawaited(AudioEngine.loadPaintballSfx());
    AudioEngine.claimSoundtrack(this, track: PaintballGameScreen.themeTrack);
  }

  @override
  void dispose() {
    AudioEngine.releaseSoundtrack(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced motion: skip arena intro straight to countdown.
    if (MediaQuery.disableAnimationsOf(context) &&
        _game.match.phase == PaintballMatchPhase.intro) {
      _game.skipIntro();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // A tap anywhere during arena intro skips it.
          if (_game.match.phase == PaintballMatchPhase.intro) {
            _game.skipIntro();
          }
        },
        child: GameWidget<PaintballGame>(
          game: _game,
          overlayBuilderMap: {
            'HUD': (context, game) => StreamBuilder<void>(
                  stream: Stream.periodic(const Duration(milliseconds: 100)),
                  builder: (context, _) {
                    if (game.match.phase == PaintballMatchPhase.intro) {
                      return const SizedBox.shrink();
                    }
                    return PaintballHudOverlay(match: game.match);
                  },
                ),
            'Controls': (context, game) => StreamBuilder<void>(
                  stream: Stream.periodic(const Duration(milliseconds: 50)),
                  builder: (context, _) {
                    if (game.match.phase == PaintballMatchPhase.intro) {
                      return const SizedBox.shrink();
                    }
                    if (game.match.phase == PaintballMatchPhase.gameOver) {
                      // Let the death / win animations play before the card.
                      if (!game.showResults) return const SizedBox.shrink();
                      return _ResultReveal(
                        child: PaintballResultCard(
                          match: game.match,
                          onRematch: game.resetMatch,
                          onLobby: () {
                            if (context.mounted) context.go('/');
                          },
                        ),
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

/// Soft entrance for the results card: a dim scrim fades in while the card
/// rises a few pixels and fades from transparent to opaque on a critically
/// damped spring (no overshoot; nothing the player did "threw" it in).
/// With reduced motion it is an opacity fade only.
class _ResultReveal extends StatefulWidget {
  final Widget child;
  const _ResultReveal({required this.child});

  @override
  State<_ResultReveal> createState() => _ResultRevealState();
}

class _ResultRevealState extends State<_ResultReveal>
    with SingleTickerProviderStateMixin {
  // Damping ratio 1.0, response ~0.45 s.
  static final SpringDescription _spring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 195, ratio: 1.0);

  late final AnimationController _c =
      AnimationController.unbounded(vsync: this, value: 0.0);

  @override
  void initState() {
    super.initState();
    _c.animateWith(SpringSimulation(_spring, 0.0, 1.0, 0.0));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value.clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Scrim pushes the scene back so the card reads as the focus.
            IgnorePointer(
              child: ColoredBox(color: Color.fromRGBO(6, 9, 19, 0.62 * t)),
            ),
            Opacity(
              opacity: t,
              child: reduceMotion
                  ? child
                  : Transform.translate(
                      offset: Offset(0, 24 * (1 - _c.value)),
                      child: Transform.scale(scale: 0.97 + 0.03 * _c.value, child: child),
                    ),
            ),
          ],
        );
      },
    );
  }
}
