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
import 'package:tiki_core/preview/plan_words.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Pick a playstyle and see what it does in each moment of play on the big
/// board. The board is the real team brain run on a staged moment.
class StyleTab extends StatefulWidget {
  final TikiSetup setup;
  final ValueChanged<TikiSetup> onChanged;

  const StyleTab({super.key, required this.setup, required this.onChanged});

  @override
  State<StyleTab> createState() => _StyleTabState();
}

class _StyleTabState extends State<StyleTab> {
  PreviewMoment _moment = PreviewMoment.attacking;
  PreviewScene? _scene;
  String _sceneKey = '';

  PreviewScene _sceneFor(TikiSetup s) {
    final key = '${s.mode.name}|${s.formation.name}|${s.plan.toJson()}|${_moment.name}';
    if (key != _sceneKey || _scene == null) {
      _sceneKey = key;
      _scene = PlanPreview.build(
        mode: s.mode,
        formation: s.formation,
        plan: s.plan,
        moment: _moment,
      );
    }
    return _scene!;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.setup;
    final scene = _sceneFor(s);
    final styles = <TeamPlan>[
      ...Presets.all,
      if (!Presets.all.any((p) => p.name == s.plan.name)) s.plan,
    ];
    final current = styles.firstWhere((p) => p.name == s.plan.name);
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
                  child: PreviewBoard(scene: scene),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'PLAYSTYLE',
                    style: TikiText.body(size: 11, weight: 700, color: TikiPalette.slate),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: TextTabs<TeamPlan>(
                      options: styles,
                      selected: current,
                      label: (p) => p.name,
                      onChanged: (p) => widget.onChanged(s.copyWith(plan: p)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(width: 260, child: _side(s.plan, scene)),
      ],
    );
  }

  Widget _side(TeamPlan plan, PreviewScene scene) {
    final jobs = [
      for (final d in scene.discs)
        if (d.moves && !d.keeper) '${d.number}  ${PlanWords.move(d.job)}',
    ];
    return PlanPanel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel('${plan.name} · ${_moment.label}'),
            Text(
              PlanWords.headline(plan, _moment),
              style: TikiText.display(size: 22, weight: 900),
            ),
            const SizedBox(height: 10),
            Text(
              PlanWords.explain(plan, _moment),
              style: TikiText.body(size: 14, color: const Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 16),
            const SectionLabel('On the board'),
            if (jobs.isEmpty)
              Text(
                'Everyone holds their spot.',
                style: TikiText.body(size: 13, color: TikiPalette.slate),
              ),
            for (final j in jobs)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(j, style: TikiText.body(size: 13, color: Colors.white)),
              ),
            const SizedBox(height: 14),
            const BoardLegend(),
          ],
        ),
      ),
    );
  }
}
