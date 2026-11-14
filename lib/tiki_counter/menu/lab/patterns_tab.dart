import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_caption.dart';
import 'package:b_ball/tiki_counter/menu/board/board_layout.dart';
import 'package:b_ball/tiki_counter/menu/board/preview_board.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/brain/patterns/pattern.dart';
import 'package:tiki_core/preview/pattern_preview.dart';
import 'package:tiki_core/preview/preview_scene.dart';

/// Every pattern your team knows, played on a loop in your formation:
/// who fills each part, the runs, and the passes.
class PatternsTab extends StatefulWidget {
  final TikiSetup setup;

  const PatternsTab({super.key, required this.setup});

  @override
  State<PatternsTab> createState() => _PatternsTabState();
}

class _PatternsTabState extends State<PatternsTab> {
  Pattern _pattern = PatternPreview.all.first;
  PreviewScene? _scene;
  String _key = '';

  PreviewScene _sceneFor(TikiSetup s) {
    final key = '${s.mode.name}|${s.formation.name}|${_pattern.id}';
    if (key != _key || _scene == null) {
      _key = key;
      _scene = PatternPreview.build(
        mode: s.mode,
        pattern: _pattern,
        formation: s.formation,
        plan: s.plan,
      );
    }
    return _scene!;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.setup;
    final scene = _sceneFor(s);
    final info = PatternPreview.info(_pattern);
    final used = _pattern.allowedFor(s.plan);
    return BoardLayout(
      mode: s.mode,
      lead: SideTabs<Pattern>(
        options: PatternPreview.all,
        selected: _pattern,
        label: (p) => PatternPreview.info(p).title,
        onChanged: (p) => setState(() => _pattern = p),
      ),
      leadWidth: 150,
      leadStacked: TextTabs<Pattern>(
        options: PatternPreview.all,
        selected: _pattern,
        label: (p) => PatternPreview.info(p).title,
        size: 15,
        wrap: true,
        onChanged: (p) => setState(() => _pattern = p),
      ),
      caption: scene.caption,
      board: PreviewBoard(scene: scene),
      sideWidth: 250,
      side: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.title, style: TikiText.display(size: 22, weight: 900)),
          const SizedBox(height: 8),
          Text(
            info.blurb,
            style: TikiText.body(size: 13, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 14),
          const SectionLabel('The parts'),
          for (final r in info.roles)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(r, style: TikiText.body(size: 13, color: Colors.white)),
            ),
          const SizedBox(height: 10),
          Text(
            used
                ? '${s.plan.name} uses this pattern.'
                : '${s.plan.name} doesn\'t use this pattern (it fits '
                      'other attacking styles).',
            style: TikiText.body(
              size: 12,
              weight: 700,
              color: used ? TikiPalette.cyan : TikiPalette.slate,
            ),
          ),
          const SizedBox(height: 14),
          const BoardLegend(),
        ],
      ),
    );
  }
}
