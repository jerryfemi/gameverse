import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// The one-line "what's happening, what to watch" text above a board.
class BoardCaption extends StatelessWidget {
  final String text;

  const BoardCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 34,
          margin: const EdgeInsets.only(right: 10, top: 2),
          decoration: BoxDecoration(
            color: TikiPalette.cyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TikiText.body(size: 14, weight: 600, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Run / press / pass / opponent key, for the side panels.
class BoardLegend extends StatelessWidget {
  const BoardLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t, {bool dashed = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: dashed ? null : c,
              border: dashed ? Border(top: BorderSide(color: c, width: 3)) : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(t, style: TikiText.body(size: 12, color: TikiPalette.slate)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(Colors.white, 'Run'),
        item(const Color(0xFFEF4444), 'Press'),
        item(TikiPalette.cyan, 'Pass', dashed: true),
        item(TikiPalette.amber.withValues(alpha: 0.45), 'Opponents (faded)'),
      ],
    );
  }
}
