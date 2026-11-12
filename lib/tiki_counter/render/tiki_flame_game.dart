import 'dart:ui';

import 'package:flame/game.dart';

import 'package:b_ball/tiki_counter/control/human_input.dart';
import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/team_state.dart';
import 'package:b_ball/tiki_counter/render/components/ball_component.dart';
import 'package:b_ball/tiki_counter/render/components/cursor_component.dart';
import 'package:b_ball/tiki_counter/render/components/debug_component.dart';
import 'package:b_ball/tiki_counter/render/components/discs_component.dart';
import 'package:b_ball/tiki_counter/render/components/pitch_component.dart';
import 'package:b_ball/tiki_counter/render/hud_model.dart';
import 'package:b_ball/tiki_counter/render/pitch_view.dart';
import 'package:b_ball/tiki_counter/runner/match_runner.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';

/// The Flame side of Tiki Counter: a fixed-step loop around [MatchRunner]
/// plus the components that draw it. It never changes the match itself.
///
/// The screen refreshes at whatever rate the device manages; the sim always
/// advances in exact 1/60 s steps. Leftover time ([alpha]) is used to draw
/// discs part-way between their last two positions, so motion stays smooth.
class TikiFlameGame extends FlameGame {
  final MatchRunner runner;
  final HumanInput input;
  final HudModel hud;

  /// True when a person controls the home team (false in "watch bots").
  final bool humanPlays;

  final PitchView view = PitchView();
  bool showDebug = false;
  double _acc = 0.0;

  TikiFlameGame({
    required this.runner,
    required this.input,
    required this.hud,
    required this.humanPlays,
  });

  /// 0..1: how far we are between the last sim step and the next.
  double get alpha => _acc / T.fixedDt;

  TeamState? get humanTeam => humanPlays ? runner.state.home : null;

  @override
  Color backgroundColor() => TikiPalette.background;

  @override
  Future<void> onLoad() async {
    await addAll([
      PitchComponent(),
      DiscsComponent(),
      BallComponent(),
      CursorComponent(),
      DebugComponent(),
    ]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    view.fit(size.x, size.y, runner.state.mode);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final frame = dt > T.maxFrameDt ? T.maxFrameDt : dt;
    input.tick(frame);
    _acc += frame;
    while (_acc >= T.fixedDt) {
      runner.step(T.fixedDt);
      _acc -= T.fixedDt;
      hud.onEvents(runner.state.events);
    }
    hud.refresh(runner.state);
  }
}
