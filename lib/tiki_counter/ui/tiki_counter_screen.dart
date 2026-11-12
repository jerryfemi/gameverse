import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/tiki_counter/render/hud_model.dart';
import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_cards.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_choice.dart';
import 'package:b_ball/tiki_counter/ui/cards/start_card.dart';
import 'package:b_ball/tiki_counter/ui/controls/controls_layer.dart';
import 'package:b_ball/tiki_counter/ui/controls/keyboard_controls.dart';
import 'package:b_ball/tiki_counter/ui/hud/event_banner.dart';
import 'package:b_ball/tiki_counter/ui/hud/key_hint.dart';
import 'package:b_ball/tiki_counter/ui/hud/rotate_hint.dart';
import 'package:b_ball/tiki_counter/ui/hud/score_bar.dart';
import 'package:b_ball/tiki_counter/ui/hud/top_buttons.dart';
import 'package:tiki_core/control/bot_controller.dart';
import 'package:tiki_core/control/human_controller.dart';
import 'package:tiki_core/control/human_input.dart';
import 'package:tiki_core/core/rng.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/runner/match_runner.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';

/// Tiki Counter's screen: start card → match (board + HUD + controls) →
/// half-time → full-time. Owns the game for one match at a time.
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

  @override
  void initState() {
    super.initState();
    // Decoded only when Tiki Counter opens, so other games never pay for it.
    unawaited(AudioEngine.loadTikiSfx());
  }

  void _start(MatchChoice c) {
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

  void _newMatch() => setState(() {
    _game = null;
    _paused = false;
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
    _hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      backgroundColor: TikiPalette.background,
      body: game == null
          ? StartCard(onStart: _start, onBack: _lobby)
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
                    const RotateHint(),
                    if (_paused)
                      PauseCard(
                        onResume: _resume,
                        onRestart: _newMatch,
                        onLobby: _lobby,
                      ),
                  ],
                ),
              ),
            ),
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
          Positioned(top: 8, left: 12, child: ScoreBar(snap: snap)),
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
              onPlayAgain: _newMatch,
              onLobby: _lobby,
            ),
        ],
      ),
    );
  }
}
