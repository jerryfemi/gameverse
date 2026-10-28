import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:b_ball/archery/ui/archery_match_bar.dart' show ArcheryInbox;
import 'package:b_ball/archery/ui/archery_pause_menu.dart';
import 'package:b_ball/darts/darts_game_screen.dart' show DartsChallenge;
import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/paintball_players.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/social/ui/profile/profile_sheet.dart';
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

  /// CC BY credits shown in the pause menu (full list in assets/paintball/CREDITS.md).
  static const String credits =
      'Player: "Realistic Paintball Player" by Jungle Jim · Tyre: "Dirty Tyre" by amanda_98 · '
      'Net, barrels, sandbags: Alex Martire, _Alexandr, Garbage Raccoon (CC BY 4.0) · Animations: Mixamo';

  @override
  State<PaintballGameScreen> createState() => _PaintballGameScreenState();
}

class _PaintballGameScreenState extends State<PaintballGameScreen> {
  late final PaintballGame _game;

  /// Firebase is only initialised in the full app, not the standalone harness.
  static bool get _firebaseReady => Firebase.apps.isNotEmpty;

  PaintballPlayers _players = PaintballPlayers.solo;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _game = PaintballGame();
    // Paintball's own sounds (decoded only now) and its theme while open.
    unawaited(AudioEngine.loadPaintballSfx());
    AudioEngine.claimSoundtrack(this, track: PaintballGameScreen.themeTrack);
    _loadYou();
  }

  /// Your name and avatar from your profile (solo: you vs the bot).
  void _loadYou() {
    if (!_firebaseReady) return;
    final me = AuthService.instance.currentUser;
    if (me == null) return;
    _players = PaintballPlayers(
      you: PaintballPlayer(name: me.displayName, avatar: me.avatarEmoji, uid: me.uid),
      opponent: PaintballPlayers.bot,
    );
  }

  @override
  void dispose() {
    AudioEngine.releaseSoundtrack(this);
    super.dispose();
  }

  void _pause() {
    if (_paused) return;
    _game.pauseEngine();
    setState(() => _paused = true);
  }

  void _resume() {
    _game.resumeEngine();
    setState(() => _paused = false);
  }

  void _goToLobby() {
    _game.resumeEngine();
    final router = GoRouter.maybeOf(context);
    if (router != null) router.go('/');
  }

  /// Profile / friend sheets freeze the game quietly (no pause menu) and
  /// resume it when they close.
  Future<void> _overGame(Future<void> Function() open) async {
    _game.pauseEngine();
    try {
      await open();
    } finally {
      if (mounted && !_paused) _game.resumeEngine();
    }
  }

  void _openProfile() => _overGame(() => ProfileSheet.show(
      context,
      onOpenMatch: (m) => GoRouter.maybeOf(context)?.go('/match/${m.id}'),
      onOpenMatches: () => ArcheryInbox.open(
        context,
        onCreateMatch: () => DartsChallenge.start(context, showGamePicker: true),
      ),
      onPlayFriend: () => DartsChallenge.start(context, showGamePicker: true),
    ));

  /// Until paintball online lands, PLAY A FRIEND opens the shared match setup
  /// with the game picker, like the profile drawer does.
  void _playFriend() => _overGame(() => DartsChallenge.start(context, showGamePicker: true));

  @override
  Widget build(BuildContext context) {
    // Respect reduced motion: skip arena intro straight to countdown.
    if (MediaQuery.disableAnimationsOf(context) &&
        _game.match.phase == PaintballMatchPhase.intro) {
      _game.skipIntro();
    }

    final m = _game.match;
    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
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
                          return _IntroOverlay(game: game);
                        }
                        if (game.showResults) return const SizedBox.shrink();
                        return PaintballHudOverlay(
                          match: game.match,
                          players: _players,
                          socialReady: _firebaseReady,
                          onPause: _pause,
                          onLobby: _goToLobby,
                          onOpenProfile: _openProfile,
                          onPlayFriend: _playFriend,
                          onPauseEngine: game.pauseEngine,
                          onResumeEngine: game.resumeEngine,
                        );
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
                              players: _players,
                              onRematch: game.resetMatch,
                              onPlayFriend: _firebaseReady ? _playFriend : null,
                              onLobby: GoRouter.maybeOf(context) != null ? _goToLobby : null,
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
          if (_paused)
            Positioned.fill(
              child: ArcheryPauseMenu(
                online: false,
                subtitle: 'Solo vs ${_players.opponent.name} · first to ${PaintballK.hitsToWin} hits',
                stat1Label: 'HITS',
                stat1Value: '${m.opponent.hitsTaken} of ${PaintballK.hitsToWin}',
                stat2Label: 'AMMO',
                stat2Value: '${m.you.ammo} of ${PaintballK.maxAmmo}',
                stat2Color: const Color(0xFF38BDF8),
                stat3Label: 'TIME',
                stat3Value: '${m.timeRemaining.ceil() ~/ 60}:${(m.timeRemaining.ceil() % 60).toString().padLeft(2, '0')}',
                stat3Color: const Color(0xFFF59E0B),
                accentColor: const Color(0xFF38BDF8),
                trackName: 'Paintball Theme',
                credit: PaintballGameScreen.credits,
                onResume: _resume,
                onRestart: () {
                  _resume();
                  _game.resetMatch();
                },
                onLobby: () {
                  setState(() => _paused = false);
                  _goToLobby();
                },
              ),
            ),
        ],
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

/// Cinematic dressing for the arena intro: letterbox bars, the two name
/// cards and a "FIRST TO 3 HITS" caption. Reads the intro clock every frame
/// (only while the intro runs) so it stays locked to the camera moves.
class _IntroOverlay extends StatefulWidget {
  final PaintballGame game;
  const _IntroOverlay({required this.game});

  @override
  State<_IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends State<_IntroOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _tick =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  // Smootherstep, clamped.
  static double _e(double x) {
    final t = x.clamp(0.0, 1.0);
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  // 0 -> 1 between a and b, then 1 -> 0 between c and d.
  static double _window(double t, double a, double b, double c, double d) =>
      _e((t - a) / (b - a)) * (1 - _e((t - c) / (d - c)));

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _tick,
        builder: (context, _) {
          final t = widget.game.match.introElapsed;
          final size = MediaQuery.sizeOf(context);
          final bars = _window(t, 0.0, 0.35, 3.9, 4.35);
          final cards = _window(t, 1.6, 2.1, 3.4, 3.8);
          final caption = _window(t, 3.0, 3.5, 4.15, 4.45);
          final barH = size.height * 0.085 * bars;
          return Stack(
            children: [
              // Letterbox.
              Positioned(top: 0, left: 0, right: 0, height: barH,
                  child: const ColoredBox(color: Color(0xFF05070D))),
              Positioned(bottom: 0, left: 0, right: 0, height: barH,
                  child: const ColoredBox(color: Color(0xFF05070D))),
              // Name cards slide in from each side during the sweep.
              Positioned(
                top: size.height * 0.12,
                left: 16 - 180 * (1 - cards),
                child: Opacity(opacity: cards, child: _card('YOU', const Color(0xFF38BDF8))),
              ),
              Positioned(
                top: size.height * 0.12,
                right: 16 - 180 * (1 - cards),
                child: Opacity(opacity: cards, child: _card('BOT', const Color(0xFFF59E0B))),
              ),
              // Caption above the bottom bar.
              Positioned(
                left: 0,
                right: 0,
                bottom: size.height * 0.12 + 12 * (1 - caption),
                child: Opacity(
                  opacity: caption,
                  child: Center(
                    child: Text(
                      'FIRST TO 3 HITS',
                      style: UiFont.style(size: 15, weight: 800, color: Colors.white, letterSpacing: 2.4),
                    ),
                  ),
                ),
              ),
              // Skip hint, bottom right inside the bar.
              Positioned(
                right: 16,
                bottom: (barH - 16).clamp(0.0, double.infinity) / 2,
                child: Opacity(
                  opacity: bars * 0.7,
                  child: Text('TAP TO SKIP',
                      style: UiFont.style(size: 10, weight: 700, color: const Color(0xFF94A3B8), letterSpacing: 1.4)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(String label, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xCC0A0E1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.85), width: 1.5),
        ),
        child: Text(label,
            style: UiFont.style(size: 14, weight: 900, color: accent, letterSpacing: 1.6)),
      );
}
