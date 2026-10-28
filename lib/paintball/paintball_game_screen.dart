import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:b_ball/game/ui/common/app_avatar.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:b_ball/archery/ui/archery_match_bar.dart' show ArcheryInbox;
import 'package:b_ball/archery/ui/archery_pause_menu.dart';
import 'package:b_ball/archery/ui/archery_tour.dart';
import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/paintball_players.dart';
import 'package:b_ball/paintball/net/paintball_session.dart';
import 'package:b_ball/models/friend_profile.dart';
import 'package:b_ball/game/match/match_config.dart';
import 'package:b_ball/game/ui/match/match_setup_dialog.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/models/player_descriptor.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/firestore_match_service.dart';
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
  const PaintballGameScreen({super.key, this.match});

  /// The online match this screen was opened for (`/match/{id}`); null for
  /// solo play against the bot. Live play over RTDB plugs in here.
  final CloudMatch? match;

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

  /// Live 1v1 connection (null in bot mode).
  PaintballSession? _session;
  bool get _online => widget.match != null;

  /// First visit on this device (solo only): how-to-play before the match.
  bool _tour = false;

  /// Phone held upright: suggest landscape for the wider view.
  bool _tiltDismissed = false;
  static const String _tourKey = 'paintball_tour_seen_v1';

  static const List<TourStep> _tourSteps = [
    TourStep(Icons.swap_horiz_rounded, 'Slide between tyres',
        'Tap ◀ ▶ to move along your five lanes. On a keyboard, use the arrow keys or A and D.'),
    TourStep(Icons.unfold_more_rounded, 'Stand, crouch, duck',
        'Tap ▲ ▼ to change stance. Standing shows your whole body, crouching only your head and shoulders, and ducking hides you completely.'),
    TourStep(Icons.my_location_rounded, 'Drag to aim, tap FIRE',
        'Drag on the right side to move the reticle, then tap FIRE or press Space. The ball takes a moment to fly, so lead your target.'),
    TourStep(Icons.refresh_rounded, 'Duck to reload',
        'You carry 5 balls. They only refill while you\'re ducked behind cover.'),
    TourStep(Icons.emoji_events_rounded, 'First to 3 hits wins',
        'You have 90 seconds. If it\'s tied when time runs out, the next hit wins.'),
  ];

  void _checkTour() {
    if (_online) return;
    ArcheryTour.shouldShow(_tourKey).then((show) {
      if (!show || !mounted) return;
      _game.pauseEngine();
      setState(() => _tour = true);
    });
  }

  void _endTour() {
    setState(() => _tour = false);
    _game.resumeEngine();
    // Start fresh so the arena intro plays in full after the tour.
    if (_game.isLoaded) _game.resetMatch();
  }

  @override
  void initState() {
    super.initState();
    _game = PaintballGame(online: _online);
    _startSession();
    _checkTour();
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
    final opp = widget.match?.opponentPlayer(me.uid);
    _players = PaintballPlayers(
      you: PaintballPlayer(name: me.displayName, avatar: me.avatarEmoji, uid: me.uid),
      opponent: opp == null || opp.uid.isEmpty
          ? PaintballPlayers.bot
          : PaintballPlayer(name: opp.displayName, avatar: opp.avatarEmoji, uid: opp.uid),
    );
  }

  /// Online: connect to the live match (RTDB only while this screen is open).
  Future<void> _startSession() async {
    final m = widget.match;
    if (m == null || !_firebaseReady) return;
    final user = await AuthService.instance.ensureAuthenticated();
    if (!mounted) return;
    final session = PaintballSession(match: m, myUid: user.uid, game: _game);
    _session = session;
    session.opponentUid.addListener(_refreshOpponent);
    session.status.addListener(() {
      if (mounted) setState(() {});
    });
    await session.connect();
  }

  /// The host learns who joined: read their name and avatar from the match.
  Future<void> _refreshOpponent() async {
    final uid = _session?.opponentUid.value;
    final m = widget.match;
    if (uid == null || m == null) return;
    final fresh = await FirestoreMatchService.instance.getMatch(m.id) ?? m;
    final opp = fresh.player1.uid == uid ? fresh.player1 : fresh.player2;
    if (!mounted || opp == null) return;
    setState(() {
      _players = PaintballPlayers(
        you: _players.you,
        opponent: PaintballPlayer(name: opp.displayName, avatar: opp.avatarEmoji, uid: opp.uid),
      );
    });
  }

  @override
  void dispose() {
    _session?.dispose();
    AudioEngine.releaseSoundtrack(this);
    super.dispose();
  }

  void _pause() {
    if (_paused) return;
    if (!_online) _game.pauseEngine();
    setState(() => _paused = true);
  }

  void _resume() {
    _game.resumeEngine();
    setState(() => _paused = false);
  }

  void _goToLobby() {
    _game.resumeEngine();
    // Leaving a live duel is a forfeit (no-op once it has ended).
    _session?.forfeit();
    final router = GoRouter.maybeOf(context);
    if (router != null) router.go('/');
  }

  /// Profile / friend sheets freeze the game quietly (no pause menu) and
  /// resume it when they close.
  Future<void> _overGame(Future<void> Function() open) async {
    if (_online) {
      await open(); // the duel keeps running online
      return;
    }
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
        onCreateMatch: () => PaintballChallenge.start(context, showGamePicker: true),
      ),
      onPlayFriend: () => PaintballChallenge.start(context, showGamePicker: true),
    ));

  /// PLAY A FRIEND opens the shared match setup preset to paintball, like
  /// archery and darts open theirs.
  void _playFriend() => _overGame(() => PaintballChallenge.start(context));

  @override
  Widget build(BuildContext context) {
    // Respect reduced motion: skip arena intro straight to countdown.
    if (!_online &&
        MediaQuery.disableAnimationsOf(context) &&
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
              if (!_online && _game.match.phase == PaintballMatchPhase.intro) {
                _game.skipIntro();
              }
            },
            child: GameWidget<PaintballGame>(
              game: _game,
              loadingBuilder: (_) => _LoadingCard(progress: _game.loadProgress),
              overlayBuilderMap: {
                'HUD': (context, game) => ValueListenableBuilder<int>(
                      valueListenable: game.uiVersion,
                      builder: (context, _, _) {
                        if (game.waitingForOpponent) return const SizedBox.shrink();
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
                          isOnline: widget.match != null,
                          matchId: widget.match?.id,
                        );
                      },
                    ),
                'Controls': (context, game) => ValueListenableBuilder<int>(
                      valueListenable: game.uiVersion,
                      builder: (context, _, _) {
                        if (game.waitingForOpponent ||
                            game.match.phase == PaintballMatchPhase.intro) {
                          return const SizedBox.shrink();
                        }
                        if (game.match.phase == PaintballMatchPhase.gameOver) {
                          // Let the death / win animations play before the card.
                          if (!game.showResults) return const SizedBox.shrink();
                          return _ResultReveal(
                            child: PaintballResultCard(
                              match: game.match,
                              players: _players,
                              onRematch: _online ? _rematchOnline : game.resetMatch,
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
          if (!_tiltDismissed &&
              MediaQuery.sizeOf(context).shortestSide < 600 &&
              MediaQuery.orientationOf(context) == Orientation.portrait)
            _RotateChip(onDone: () => setState(() => _tiltDismissed = true)),
          if (_tour) ArcheryTour(steps: _tourSteps, onDone: _endTour),
          if (_session != null && _game.waitingForOpponent)
            _ReadyRoom(
              session: _session!,
              code: widget.match!.joinCode,
              you: _players.you,
              opponent: _players.opponent,
              onPlayBot: _leaveRoom(toBot: true),
              onLobby: _leaveRoom(toBot: false),
            ),
          if (_session != null && !_game.waitingForOpponent) _SessionPills(session: _session!),
          if (_paused)
            Positioned.fill(
              child: ArcheryPauseMenu(
                online: _online,
                onForfeit: _online
                    ? () {
                        setState(() => _paused = false);
                        _goToLobby();
                      }
                    : null,
                subtitle: _online
                    ? 'Live vs ${_players.opponent.name} · first to ${PaintballK.hitsToWin} hits'
                    : 'Solo vs ${_players.opponent.name} · first to ${PaintballK.hitsToWin} hits',
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

  /// Online rematch: the shared instant-rematch challenge (same as archery).
  /// Reads the match fresh: the copy this screen opened with may predate the
  /// opponent joining, and then there's "nobody" to rematch.
  Future<void> _rematchOnline() async {
    final m = widget.match;
    final me = AuthService.instance.currentUser?.uid;
    if (m == null || me == null) return;
    final fresh = await FirestoreMatchService.instance.getMatch(m.id) ?? m;
    if (!mounted) return;
    await PaintballChallenge.rematch(context, finished: fresh, myUid: me);
  }

  /// Leaving the ready room before the duel starts. Nobody joined yet: close
  /// the room (and withdraw a friend challenge). Otherwise just leave; the
  /// opponent sees you go. Not a forfeit, nothing was played.
  VoidCallback _leaveRoom({required bool toBot}) => () async {
        final m = widget.match;
        final me = AuthService.instance.currentUser?.uid;
        final router = GoRouter.maybeOf(context);
        if (m != null && me != null && _session?.opponentUid.value == null) {
          final fresh = await FirestoreMatchService.instance.getMatch(m.id) ?? m;
          if (fresh.player2 == null) {
            unawaited(FirestoreMatchService.instance.leaveOrDismissMatch(matchId: m.id, myUid: me));
          }
        }
        router?.go(toBot ? '/paintball' : '/');
      };

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

/// Creates an online paintball match (code or friend challenge) and takes the
/// player into it: the shared MatchSetupDialog, then this screen's ready room.
abstract final class PaintballChallenge {
  static const MatchConfig config = MatchConfig(
    game: 'paintball',
    totalRounds: 1,
    roundDurationSeconds: PaintballK.matchDurationSeconds,
  );

  static Future<void> start(
    BuildContext context, {
    bool showGamePicker = false,
  }) async {
    final chosen = await MatchSetupDialog.show(
      context,
      initialConfig: config,
      showGamePicker: showGamePicker,
    );
    if (chosen == null || !context.mounted) return;

    // "Join with a code": the match already exists, just open it.
    final joined = chosen.joinedMatch;
    if (joined != null) {
      GoRouter.maybeOf(context)?.go('/match/${joined.id}');
      return;
    }

    final profile = await _me();
    final CloudMatch match = chosen.precreatedMatch ??
        await FirestoreMatchService.instance.createMatch(
          config: chosen.copyWith(
            player1Name: profile.displayName,
            player1Avatar: profile.avatarEmoji,
          ),
          player1Profile: profile,
        );
    if (!context.mounted) return;

    // Straight into the paintball ready room (code, presence, READY);
    // the turn-based lobby dialog doesn't fit a live duel.
    GoRouter.maybeOf(context)?.go('/match/${match.id}');
  }

  /// Instant rematch with the same opponent: creates or joins their rematch.
  static Future<void> rematch(
    BuildContext context, {
    required CloudMatch finished,
    required String myUid,
  }) async {
    final opp = finished.opponentPlayer(myUid);
    if (opp == null || opp.uid.isEmpty) {
      await start(context);
      return;
    }
    final profile = await _me();
    final cfg = config.copyWith(
      player1Name: profile.displayName,
      player1Avatar: profile.avatarEmoji,
      player2Name: opp.displayName,
      player2Avatar: opp.avatarEmoji,
      player2Uid: opp.uid,
      opponentFriend: FriendProfile(
        uid: opp.uid,
        displayName: opp.displayName,
        avatarEmoji: opp.avatarEmoji,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    final result = await FirestoreMatchService.instance.createOrJoinRematch(
      finishedMatchId: finished.id,
      config: cfg,
      me: profile,
    );
    if (!context.mounted) return;
    GoRouter.maybeOf(context)?.go('/match/${result.match.id}');
  }

  static Future<UserProfile> _me() async {
    final user = await AuthService.instance.ensureAuthenticated();
    return AuthService.instance.currentUser ??
        UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? 'Player',
          avatarEmoji: PlayerDescriptor.defaultAvatar,
        );
  }
}

/// In-match online pills: opponent reconnecting, or an "update needed" card.
class _SessionPills extends StatelessWidget {
  final PaintballSession session;
  const _SessionPills({required this.session});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaintballSessionStatus>(
      valueListenable: session.status,
      builder: (context, st, _) {
        if (st == PaintballSessionStatus.opponentReconnecting) {
          return const Positioned(
            top: 86,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(child: _Pill(text: 'OPPONENT RECONNECTING…', color: Color(0xFFF59E0B))),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Live 1v1 ready room: both players, who's here, who's READY. Both ready →
/// a shared 3-2-1 on this card, then the arena. Always has a way out.
class _ReadyRoom extends StatefulWidget {
  final PaintballSession session;
  final String code;
  final PaintballPlayer you;
  final PaintballPlayer opponent;
  final VoidCallback onPlayBot;
  final VoidCallback onLobby;

  const _ReadyRoom({
    required this.session,
    required this.code,
    required this.you,
    required this.opponent,
    required this.onPlayBot,
    required this.onLobby,
  });

  @override
  State<_ReadyRoom> createState() => _ReadyRoomState();
}

class _ReadyRoomState extends State<_ReadyRoom> {
  static const _sky = Color(0xFF38BDF8);
  static const _cyan = Color(0xFF00FFCC);
  static const _slate = Color(0xFF94A3B8);

  Timer? _tick;
  late final DateTime _opened = DateTime.now();
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    // Drives the 3-2-1 and the "still waiting" nudge.
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.code));
      HapticFeedback.lightImpact();
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return ListenableBuilder(
      listenable: Listenable.merge([
        s.connected, s.struggling, s.meReady, s.opponentReady, s.opponentHere,
        s.startAt, s.opponentUid, s.status,
      ]),
      builder: (context, _) {
        if (s.status.value == PaintballSessionStatus.versionMismatch) {
          return _wrap(_message(Icons.system_update_rounded, 'UPDATE NEEDED',
              'You and your opponent are on different versions. Refresh the page.'));
        }
        final joined = s.opponentUid.value != null;
        final here = s.opponentHere.value;
        final at = s.startAt.value;
        final secs = at == null ? null : ((at - s.clock.serverNowMs) / 1000.0).ceil().clamp(0, 3);
        final waitedLong = DateTime.now().difference(_opened).inSeconds > 120 && !here;

        return _wrap(Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PAINTBALL · LIVE 1V1',
                style: UiFont.style(size: 12, weight: 800, color: _sky, letterSpacing: 1.6)),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _seat(widget.you, here: s.connected.value, ready: s.meReady.value)),
                Padding(
                  padding: const EdgeInsets.only(top: 26),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: secs != null
                        ? Text('$secs',
                            key: ValueKey(secs),
                            style: UiFont.style(size: 40, weight: 900, color: _cyan))
                        : Text('VS',
                            key: const ValueKey('vs'),
                            style: UiFont.style(size: 14, weight: 800, color: const Color(0xFF64748B))),
                  ),
                ),
                Expanded(
                  child: _seat(
                    joined ? widget.opponent : null,
                    here: here,
                    ready: s.opponentReady.value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                key: ValueKey('${secs != null}$joined$here${s.opponentReady.value}${s.meReady.value}'),
                secs != null
                    ? 'Get ready…'
                    : !joined
                        ? 'Send your friend the code to join'
                        : !here
                            ? 'Waiting for ${widget.opponent.name} to open the match'
                            : s.opponentReady.value && !s.meReady.value
                                ? '${widget.opponent.name} is ready. Tap READY!'
                                : s.meReady.value && !s.opponentReady.value
                                    ? 'Waiting for ${widget.opponent.name} to tap READY'
                                    : 'Tap READY when you\'re set',
                textAlign: TextAlign.center,
                style: UiFont.style(size: 13.5, weight: 500, color: _slate),
              ),
            ),
            if (!joined) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _copy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _copied ? _cyan : const Color(0xFF1E2638)),
                  ),
                  child: Text(_copied ? '✓ CODE COPIED' : widget.code,
                      style: UiFont.style(
                          size: _copied ? 13 : 20, weight: 900, color: _copied ? _cyan : Colors.white, letterSpacing: 3)),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, height: 50, child: _readyButton(s, locked: secs != null)),
            const SizedBox(height: 6),
            if (waitedLong)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Still waiting… try the bot in the meantime?',
                    style: UiFont.style(size: 12, weight: 600, color: const Color(0xFFF59E0B))),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: widget.onPlayBot,
                  child: Text('PLAY THE BOT',
                      style: UiFont.style(size: 12, weight: 800, color: _sky, letterSpacing: 0.8)),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: widget.onLobby,
                  child: Text('BACK TO LOBBY',
                      style: UiFont.style(size: 12, weight: 800, color: _slate, letterSpacing: 0.8)),
                ),
              ],
            ),
          ],
        ));
      },
    );
  }

  Widget _readyButton(PaintballSession s, {required bool locked}) {
    final connected = s.connected.value;
    final ready = s.meReady.value;
    final Widget label;
    if (!connected) {
      label = s.struggling.value
          ? Text('RECONNECTING…', style: UiFont.style(size: 14, weight: 800, color: _slate, letterSpacing: 1))
          : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: _sky));
    } else {
      label = Text(ready ? '✓ READY' : 'READY',
          style: UiFont.style(
              size: 16, weight: 900, color: ready ? _cyan : const Color(0xFF0A0E1A), letterSpacing: 1.4));
    }
    return GestureDetector(
      onTap: !connected || locked
          ? null
          : () {
              HapticFeedback.mediumImpact();
              s.setReady(!ready);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !connected
              ? const Color(0xFF1E2638)
              : ready
                  ? const Color(0x1A00FFCC)
                  : _sky,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ready ? _cyan : Colors.transparent, width: 1.6),
          boxShadow: ready ? [BoxShadow(color: _cyan.withValues(alpha: 0.25), blurRadius: 18)] : null,
        ),
        child: label,
      ),
    );
  }

  /// One player: avatar with a presence dot, name, and a READY tick.
  Widget _seat(PaintballPlayer? p, {required bool here, required bool ready}) {
    final ring = ready ? _cyan : (here ? _sky : const Color(0xFF334155));
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2.2),
                boxShadow: ready ? [BoxShadow(color: _cyan.withValues(alpha: 0.35), blurRadius: 16)] : null,
              ),
              child: p == null
                  ? const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.person_outline_rounded, color: Color(0xFF475569), size: 34),
                    )
                  : Opacity(opacity: here ? 1 : 0.45, child: AppAvatar(avatar: p.avatar, size: 64)),
            ),
            if (ready)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: _cyan, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0A0E1A)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(p?.name ?? 'Waiting…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiFont.style(size: 14, weight: 800, color: p == null ? _slate : Colors.white)),
        const SizedBox(height: 3),
        Text(
          ready ? 'READY' : (here ? 'Here' : (p == null ? 'Not joined' : 'Not here yet')),
          style: UiFont.style(
              size: 11, weight: 700, letterSpacing: 0.6, color: ready ? _cyan : (here ? _sky : const Color(0xFF64748B))),
        ),
      ],
    );
  }

  Widget _message(IconData icon, String title, String body) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFEF4444), size: 30),
          const SizedBox(height: 12),
          Text(title, style: UiFont.style(size: 15, weight: 900, color: Colors.white, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: UiFont.style(size: 13, weight: 500, color: _slate)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onLobby,
            child: Text('BACK TO LOBBY', style: UiFont.style(size: 12, weight: 800, color: _sky)),
          ),
        ],
      );

  Widget _wrap(Widget child) => Positioned.fill(
        child: ColoredBox(
          color: const Color(0xB30A0E1A),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xF20F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x4038BDF8)),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 40)],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xE60F172A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Text(text, style: UiFont.style(size: 11, weight: 800, color: color, letterSpacing: 1.0)),
      );
}

/// Shown while the arena's images and sounds load, so the screen is never blank.
class _LoadingCard extends StatelessWidget {
  final ValueNotifier<double> progress;
  const _LoadingCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.blur_circular_rounded, color: Color(0xFF38BDF8), size: 40),
              const SizedBox(height: 14),
              Text('PAINTBALL',
                  style: UiFont.style(size: 22, weight: 900, color: Colors.white, letterSpacing: 1.6)),
              const SizedBox(height: 6),
              Text('Setting up the arena…',
                  style: UiFont.style(size: 13, weight: 500, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 20),
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (context, p, _) => TweenAnimationBuilder<double>(
                  // Eases between steps instead of jumping.
                  tween: Tween(end: p.clamp(0.06, 1.0)),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: const Color(0xFF1E2638),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone held upright: a small chip suggests landscape for a wider view,
/// then fades away after 2 seconds. Once per visit.
class _RotateChip extends StatefulWidget {
  final VoidCallback onDone;
  const _RotateChip({required this.onDone});

  @override
  State<_RotateChip> createState() => _RotateChipState();
}

class _RotateChipState extends State<_RotateChip> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _shown = false);
    });
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 64,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            opacity: _shown ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSlide(
              offset: _shown ? Offset.zero : const Offset(0, -0.3),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xE60F172A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x6638BDF8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.screen_rotation_rounded, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 8),
                    Text('Rotate for a better view',
                        style: UiFont.style(size: 12.5, weight: 700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
