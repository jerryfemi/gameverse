import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/tiki_counter/menu/club/club_screen.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/game_plan_screen.dart';
import 'package:b_ball/tiki_counter/menu/home/home_hub.dart';
import 'package:b_ball/tiki_counter/menu/kick_off_sheet.dart';
import 'package:b_ball/tiki_counter/menu/record/record_screen.dart';
import 'package:b_ball/tiki_counter/menu/record/record_store.dart';
import 'package:b_ball/tiki_counter/menu/setup/gameverse_link.dart';
import 'package:b_ball/tiki_counter/menu/setup/setup_store.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/platform/landscape_lock.dart';
import 'package:b_ball/tiki_counter/render/hud_model.dart';
import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_cards.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_choice.dart';
import 'package:b_ball/tiki_counter/ui/controls/controls_layer.dart';
import 'package:b_ball/tiki_counter/ui/controls/keyboard_controls.dart';
import 'package:b_ball/tiki_counter/ui/hud/event_banner.dart';
import 'package:b_ball/tiki_counter/ui/hud/key_hint.dart';
import 'package:b_ball/tiki_counter/ui/portrait_gate.dart';
import 'package:b_ball/tiki_counter/ui/hud/score_bar.dart';
import 'package:b_ball/tiki_counter/ui/hud/top_buttons.dart';
import 'package:tiki_core/control/bot_controller.dart';
import 'package:tiki_core/control/human_controller.dart';
import 'package:tiki_core/control/human_input.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/record/club_record.dart';
import 'package:tiki_core/record/record_entry.dart';
import 'package:tiki_core/runner/match_runner.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';

/// Which menu page shows when no match is running.
enum MenuPage { home, gamePlan, club, record }

/// Tiki Counter's screen: menus (home hub, game plan, club, kick-off sheet)
/// → match (board + HUD + controls) → half-time → full-time.
/// Owns the saved setup and the game for one match at a time.
class TikiCounterScreen extends StatefulWidget {
  const TikiCounterScreen({super.key});

  @override
  State<TikiCounterScreen> createState() => _TikiCounterScreenState();
}

class _TikiCounterScreenState extends State<TikiCounterScreen> {
  final HumanInput _input = HumanInput();
  final HudModel _hud = HudModel();
  TikiFlameGame? _game;
  bool _watching = false;
  bool _paused = false;

  /// True once a key is pressed: the touch buttons hide and a key hint
  /// shows instead. A touch on the screen brings the buttons back.
  bool _keyboardMode = false;

  /// Null until the saved setup has loaded (a few milliseconds).
  TikiSetup? _setup;
  MenuPage _page = MenuPage.home;
  PlanTab _planTab = PlanTab.style;

  /// The last match's choice, for PLAY AGAIN / RESTART.
  MatchChoice? _lastChoice;

  /// Your club's record vs the bot, and whose it is (user id or 'guest').
  ClubRecord _record = ClubRecord();
  String _recordOwner = 'guest';

  /// Watches the running match for full-time (removed when it ends).
  VoidCallback? _fullTimeWatch;

  @override
  void initState() {
    super.initState();
    // Decoded only when Tiki Counter opens, so other games never pay for it.
    unawaited(AudioEngine.loadTikiSfx());
    unawaited(_loadSetup());
  }

  Future<void> _loadSetup() async {
    final saved = await SetupStore.loadSaved();
    if (!mounted) return;
    setState(() => _setup = saved ?? TikiSetup.initial);
    // First launch: name the club after the player ("Oyin FC").
    if (saved == null) GameVerseLink.whenUser(_nameClubAfter);
    unawaited(_loadRecord(GameVerseLink.recordOwner));
    // Signed in after the screen opened: switch to that account's record.
    GameVerseLink.whenUser((u) {
      if (u.uid != _recordOwner) unawaited(_loadRecord(u.uid));
    });
  }

  void _nameClubAfter(UserProfile u) {
    final setup = _setup;
    final name = TikiSetup.clubNameFor(u.displayName);
    if (!mounted || setup == null || name == null) return;
    if (setup.clubName != TikiSetup.initial.clubName) return; // already named
    _changeSetup(setup.copyWith(clubName: name, clubCode: TikiSetup.codeFor(name)));
  }

  Future<void> _loadRecord(String owner) async {
    final r = await RecordStore.load(owner);
    if (!mounted) return;
    setState(() {
      _recordOwner = owner;
      _record = r;
    });
  }

  /// Calls [_matchFinished] once when this match reaches full-time.
  void _watchFullTime(MatchRunner runner, MatchChoice c) {
    _stopWatchingFullTime();
    void watch() {
      if (_hud.snapshot.value.phase != MatchPhase.fullTime) return;
      _stopWatchingFullTime();
      _matchFinished(runner.state, c);
    }

    _fullTimeWatch = watch;
    _hud.snapshot.addListener(watch);
  }

  void _stopWatchingFullTime() {
    final w = _fullTimeWatch;
    if (w != null) _hud.snapshot.removeListener(w);
    _fullTimeWatch = null;
  }

  /// Full-time: count it for the dashboard and, if you played (not just
  /// watched), add it to your club record.
  void _matchFinished(MatchState state, MatchChoice c) {
    if (c.watch) return;
    GameVerseLink.soloMatchFinished();
    final entry = RecordEntry.fromMatch(
      state,
      botLevel: c.botLevel.name,
      playedAt: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() => _record.add(entry));
    unawaited(RecordStore.save(_recordOwner, _record));
  }

  /// Every menu change goes through here: shown at once, saved quietly.
  void _changeSetup(TikiSetup s) {
    setState(() => _setup = s);
    unawaited(SetupStore.save(s));
  }

  void _openKickOff({required bool watch}) {
    final setup = _setup;
    if (setup == null) return;
    unawaited(
      showKickOffSheet(
        context,
        setup: setup,
        watch: watch,
        onSetupChanged: _changeSetup,
        onStart: _start,
        onEditPlan: () => setState(() {
          _planTab = PlanTab.style;
          _page = MenuPage.gamePlan;
        }),
      ),
    );
  }

  void _start(MatchChoice c) {
    // Called from the KICK OFF tap: the browser allows full screen here.
    LandscapeLock.request();
    _lastChoice = c;
    _input.releaseAll();
    final seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final pick = Rng(seed + 3);
    final formations = Formations.forMode(c.mode);
    final runner = MatchRunner.create(
      mode: c.mode,
      home: c.watch
          ? BotController(rng: Rng(seed + 1), level: c.botLevel)
          : HumanController(_input),
      away: BotController(rng: Rng(seed + 2), level: c.botLevel),
      homeFormation: c.homeFormation,
      awayFormation: formations[pick.nextInt(formations.length)],
      homePlan: c.homePlan,
      awayPlan: c.awayPlan ?? Presets.all[pick.nextInt(Presets.all.length)],
      seed: seed,
    );
    _watchFullTime(runner, c);
    final st = runner.state;
    st.home.name = c.homeName;
    st.home.code = c.homeCode;
    st.away.name = c.opponent.name;
    st.away.code = c.opponent.code;
    final watch = c.watch;
    _hud.snapshot.value = HudSnapshot.initial;
    _hud.banner.value = null;
    setState(() {
      _watching = watch;
      _paused = false;
      _game = TikiFlameGame(
        runner: runner,
        input: _input,
        hud: _hud,
        humanPlays: !watch,
      );
    });
  }

  void _pause() {
    _input.releaseAll();
    _game?.pauseEngine();
    setState(() => _paused = true);
  }

  void _togglePause() => _paused ? _resume() : _pause();

  void _useKeyboard() {
    if (!_keyboardMode) setState(() => _keyboardMode = true);
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_keyboardMode && e.kind == PointerDeviceKind.touch) {
      setState(() => _keyboardMode = false);
    }
  }

  void _resume() {
    _game?.resumeEngine();
    setState(() => _paused = false);
  }

  /// Same choice again (new random seed).
  void _replay() {
    final c = _lastChoice;
    if (c == null) return _toMenu();
    _start(c);
  }

  void _toMenu() => setState(() {
    _stopWatchingFullTime();
    _game = null;
    _paused = false;
    _page = MenuPage.home;
  });

  void _lobby() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go('/');
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  void dispose() {
    _stopWatchingFullTime();
    _hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      backgroundColor: TikiPalette.background,
      body: PortraitGate(
        onPortrait: _pauseForPortrait,
        child: _body(game),
      ),
    );
  }

  /// Phone turned upright mid-match: pause (the pause card is waiting when
  /// it turns back). Watching bots just carries on.
  void _pauseForPortrait() {
    if (_game != null && !_paused && !_watching) _pause();
  }

  Widget _body(TikiFlameGame? game) {
    return game == null
          ? _menu()
          : Listener(
              onPointerDown: _onPointerDown,
              child: KeyboardControls(
                input: _input,
                attacking: () => _hud.snapshot.value.homeAttacking,
                onPause: _togglePause,
                onKeyboardUsed: _useKeyboard,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GameWidget<TikiFlameGame>(key: ObjectKey(game), game: game),
                    ValueListenableBuilder<HudSnapshot>(
                      valueListenable: _hud.snapshot,
                      builder: (context, snap, _) => _hudLayer(game, snap),
                    ),
                    EventBanner(banner: _hud.banner),
                    if (_paused)
                      PauseCard(
                        onResume: _resume,
                        onRestart: _replay,
                        onLobby: _toMenu,
                      ),
                  ],
                ),
              ),
            );
  }

  Widget _menu() {
    final setup = _setup;
    if (setup == null) return const SizedBox.expand();
    final page = switch (_page) {
      MenuPage.home => HomeHub(
        setup: setup,
        record: _record,
        onRecord: () => setState(() => _page = MenuPage.record),
        onKickOff: () => _openKickOff(watch: false),
        onGamePlan: () => setState(() {
          _planTab = PlanTab.style;
          _page = MenuPage.gamePlan;
        }),
        onLab: () => _openKickOff(watch: true),
        onClub: () => setState(() => _page = MenuPage.club),
        onExit: _lobby,
      ),
      MenuPage.gamePlan => GamePlanScreen(
        setup: setup,
        startTab: _planTab,
        onChanged: _changeSetup,
        onBack: () => setState(() => _page = MenuPage.home),
        onTest: () => _openKickOff(watch: false),
      ),
      MenuPage.record => RecordScreen(
        clubName: setup.clubName,
        record: _record,
        onBack: () => setState(() => _page = MenuPage.home),
      ),
      MenuPage.club => ClubScreen(
        setup: setup,
        onSave: (s) {
          _changeSetup(s);
          setState(() => _page = MenuPage.home);
        },
        onBack: () => setState(() => _page = MenuPage.home),
      ),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(_page), child: page),
    );
  }

  Widget _hudLayer(TikiFlameGame game, HudSnapshot snap) {
    final playing = snap.phase == MatchPhase.firstHalf ||
        snap.phase == MatchPhase.secondHalf;
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_watching && playing && !_paused && !_keyboardMode)
            ControlsLayer(input: _input, attacking: snap.homeAttacking),
          if (!_watching && playing && _keyboardMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: KeyHint(attacking: snap.homeAttacking),
            ),
          Positioned(
            top: 8,
            left: 12,
            child: ScoreBar(
              snap: snap,
              homeCode: game.runner.state.home.code,
              awayCode: game.runner.state.away.code,
            ),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: TopButtons(
              debugOn: game.showDebug,
              onToggleDebug: () => setState(() => game.showDebug = !game.showDebug),
              onPause: _pause,
            ),
          ),
          if (snap.phase == MatchPhase.halfTime)
            HalfTimeCard(
              state: game.runner.state,
              onContinue: game.runner.startSecondHalf,
            ),
          if (snap.phase == MatchPhase.fullTime)
            FullTimeCard(
              state: game.runner.state,
              onPlayAgain: _replay,
              onLobby: _toMenu,
            ),
        ],
      ),
    );
  }
}
