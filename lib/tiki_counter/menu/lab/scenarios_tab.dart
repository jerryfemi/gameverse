import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_caption.dart';
import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:b_ball/tiki_counter/menu/board/preview_board.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/plan_panel.dart';
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
    final aspect = (s.mode.length + BoardGeometry.margin * 2) /
        (s.mode.width + BoardGeometry.margin * 2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextTabs<PreviewMoment>(
                options: PreviewMoment.values,
                selected: _moment,
                label: (m) => m.label,
                size: 15,
                onChanged: (m) => setState(() => _moment = m),
              ),
              const SizedBox(height: 8),
              BoardCaption(scene.caption),
              const SizedBox(height: 8),
              Expanded(
                child: BoardBox(
                  aspect: aspect,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final g = BoardGeometry(s.mode, Size(box.maxWidth, box.maxHeight));
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (e) => _moveBall(g, e.localPosition),
                        onPanStart: (e) {
                          _dragging = true;
                          _moveBall(g, e.localPosition);
                        },
                        onPanUpdate: (e) => _moveBall(g, e.localPosition),
                        onPanEnd: (_) => setState(() => _dragging = false),
                        child: PreviewBoard(scene: scene, animate: !_dragging),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 240,
          child: PlanPanel(
            child: SingleChildScrollView(
              child: Column(
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
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      for (final p in Presets.all)
                        TextTabs<TeamPlan>(
                          options: [p],
                          selected: _opponent,
                          label: (x) => x.name,
                          size: 13,
                          onChanged: (x) => setState(() => _opponent = x),
                        ),
                    ],
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
            ),
          ),
        ),
      ],
    );
  }
}
