import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:b_ball/tiki_counter/control/bot_controller.dart';
import 'package:b_ball/tiki_counter/control/human_controller.dart';
import 'package:b_ball/tiki_counter/control/human_input.dart';
import 'package:b_ball/tiki_counter/core/rng.dart';
import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/render/hud_model.dart';
import 'package:b_ball/tiki_counter/render/tiki_flame_game.dart';
import 'package:b_ball/tiki_counter/runner/match_runner.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_cards.dart';
import 'package:b_ball/tiki_counter/ui/cards/start_card.dart';
import 'package:b_ball/tiki_counter/ui/controls/controls_layer.dart';
import 'package:b_ball/tiki_counter/ui/hud/event_banner.dart';
import 'package:b_ball/tiki_counter/ui/hud/rotate_hint.dart';
import 'package:b_ball/tiki_counter/ui/hud/score_bar.dart';
import 'package:b_ball/tiki_counter/ui/hud/top_buttons.dart';

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

  void _start(GameMode mode, {required bool watch}) {
    _input.releaseAll();
    final seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    final runner = MatchRunner.create(
      mode: mode,
      home: watch ? BotController(rng: Rng(seed + 1)) : HumanController(_input),
      away: BotController(rng: Rng(seed + 2)),
      seed: seed,
    );
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
          : Stack(
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
    );
  }

  Widget _hudLayer(TikiFlameGame game, HudSnapshot snap) {
    final playing = snap.phase == MatchPhase.firstHalf ||
        snap.phase == MatchPhase.secondHalf;
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_watching && playing && !_paused)
            ControlsLayer(input: _input, attacking: snap.homeAttacking),
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
