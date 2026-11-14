import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_caption.dart';
import 'package:b_ball/tiki_counter/menu/board/board_layout.dart';
import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:b_ball/tiki_counter/menu/board/preview_board.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/preview/plan_preview.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Drag the ball anywhere: both teams take up the shape their game plans
/// give them for that spot and moment. Let go to see the runs play.
class ScenariosTab extends StatefulWidget {
  final TikiSetup setup;

  const ScenariosTab({super.key, required this.setup});

  @override
  State<ScenariosTab> createState() => _ScenariosTabState();
}

class _ScenariosTabState extends State<ScenariosTab> {
  PreviewMoment _moment = PreviewMoment.defending;
  TeamPlan _opponent = Presets.balanced;
  double? _bx;
  double? _by;
  bool _dragging = false;

  PreviewScene _scene(TikiSetup s) => PlanPreview.build(
    mode: s.mode,
    formation: s.formation,
    plan: s.plan,
    moment: _moment,
    opponentPlan: _opponent,
    ballX: _bx,
    ballY: _by,
  );

  void _moveBall(BoardGeometry g, Offset local) {
    final p = g.toPitch(local);
    final hl = g.mode.halfLength - 1.0;
    final hw = g.mode.halfWidth - 1.0;
    setState(() {
      _bx = p.x.clamp(-hl, hl).toDouble();
      _by = p.y.clamp(-hw, hw).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.setup;
    final scene = _scene(s);
    return BoardLayout(
      mode: s.mode,
      above: [
        TextTabs<PreviewMoment>(
          options: PreviewMoment.values,
          selected: _moment,
          label: (m) => m.label,
          size: 15,
          onChanged: (m) => setState(() => _moment = m),
        ),
      ],
      caption: scene.caption,
      board: LayoutBuilder(
        builder: (context, box) {
          final g = BoardGeometry(s.mode, Size(box.maxWidth, box.maxHeight));
          // Separate up-down and sideways drags (not one pan) so that on a
          // scrolling page a drag on the board moves the ball, not the page.
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (e) => _moveBall(g, e.localPosition),
            onVerticalDragStart: (e) => _startDrag(g, e.localPosition),
            onVerticalDragUpdate: (e) => _moveBall(g, e.localPosition),
            onVerticalDragEnd: (_) => _endDrag(),
            onHorizontalDragStart: (e) => _startDrag(g, e.localPosition),
            onHorizontalDragUpdate: (e) => _moveBall(g, e.localPosition),
            onHorizontalDragEnd: (_) => _endDrag(),
            child: PreviewBoard(scene: scene, animate: !_dragging),
          );
        },
      ),
      sideWidth: 240,
      side: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drag the ball', style: TikiText.display(size: 20, weight: 900)),
          const SizedBox(height: 8),
          Text(
            'Tap or drag anywhere on the board. Both teams move to '
            'where their game plans send them for that spot. Let go to '
            'watch the runs.',
            style: TikiText.body(size: 13, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 14),
          SectionLabel('You: ${s.plan.name}'),
          const SizedBox(height: 6),
          const SectionLabel('Opponent playstyle'),
          TextTabs<TeamPlan>(
            options: Presets.all,
            selected: _opponent,
            label: (x) => x.name,
            size: 13,
            gap: 16,
            wrap: true,
            onChanged: (x) => setState(() => _opponent = x),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => setState(() {
              _bx = null;
              _by = null;
            }),
            child: Text(
              'Reset the ball',
              style: TikiText.body(size: 13, weight: 700, color: TikiPalette.cyan),
            ),
          ),
          const SizedBox(height: 8),
          const BoardLegend(),
        ],
      ),
    );
  }

  void _startDrag(BoardGeometry g, Offset local) {
    _dragging = true;
    _moveBall(g, local);
  }

  void _endDrag() => setState(() => _dragging = false);
}
