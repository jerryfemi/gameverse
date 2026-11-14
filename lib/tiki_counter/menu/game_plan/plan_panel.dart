import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:tiki_core/model/game_mode.dart';

/// The dark rounded box used for the board and the side panel.
class PlanPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const PlanPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xFF0D1612),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF1E2E26)),
    ),
    child: child,
  );
}

/// A board that keeps the pitch's proportions inside whatever space it
/// gets. [upright] stands the pitch on its end (phones held upright).
class BoardBox extends StatelessWidget {
  final GameMode mode;
  final bool upright;
  final Widget child;

  const BoardBox({
    super.key,
    required this.mode,
    required this.child,
    this.upright = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: TikiPalette.frame,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF1E2E26)),
    ),
    padding: const EdgeInsets.all(10),
    child: Center(
      child: AspectRatio(
        aspectRatio: BoardGeometry.aspectFor(mode, upright: upright),
        child: child,
      ),
    ),
  );
}
