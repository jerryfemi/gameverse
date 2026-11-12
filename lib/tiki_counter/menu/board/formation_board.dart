import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/formation.dart';

/// A formation on the board. Discs are real buttons: tap one to select it.
/// Switching [withBall] slides every disc to the other shape.
class FormationBoard extends StatelessWidget {
  final GameMode mode;
  final Formation formation;
  final bool withBall;
  final int selected;
  final ValueChanged<int> onSelect;

  const FormationBoard({
    super.key,
    required this.mode,
    required this.formation,
    required this.withBall,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final g = BoardGeometry(mode, size);
        final raw = g.px(2.5);
        final d = raw < 26.0 ? 26.0 : (raw > 48.0 ? 48.0 : raw);
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PitchPainter(mode))),
            for (var i = 0; i < formation.spots.length; i++)
              _disc(g, i, d),
          ],
        );
      },
    );
  }

  Widget _disc(BoardGeometry g, int i, double d) {
    final s = formation.spots[i];
    final x = (withBall ? s.ax : s.dx) * mode.halfLength;
    final y = (withBall ? s.ay : s.dy) * mode.halfWidth * 0.85;
    final at = g.at(x, y);
    final on = i == selected;
    return AnimatedPositioned(
      key: ValueKey(i),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      left: at.dx - d / 2,
      top: at.dy - d / 2,
      width: d,
      height: d,
      child: Semantics(
        button: true,
        selected: on,
        label: '${s.number}, ${s.position.short}',
        child: GestureDetector(
          onTap: () => onSelect(i),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4),
                colors: [Color(0xFFFFFFFF), TikiPalette.homeFill, Color(0xFFBDB7AA)],
                stops: [0.0, 0.6, 1.0],
              ),
              border: on ? Border.all(color: TikiPalette.cyan, width: 3) : null,
              boxShadow: const [
                BoxShadow(color: TikiPalette.homeEdge, offset: Offset(0, 3)),
                BoxShadow(color: Color(0x66000000), offset: Offset(0, 7), blurRadius: 10),
              ],
            ),
            child: Text(
              '${s.number}',
              style: TikiText.display(
                size: d * 0.36,
                weight: 900,
                color: TikiPalette.homeText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  final GameMode mode;

  _PitchPainter(this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(mode, size);
    BoardPaint.pitch(canvas, g);
    BoardPaint.directionLabels(canvas, g);
  }

  @override
  bool shouldRepaint(_PitchPainter old) => old.mode != mode;
}
