import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/render/hud_model.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Compact score bar, top-left: ● HOME 0  3:12  0 AWAY ●
class ScoreBar extends StatelessWidget {
  final HudSnapshot snap;

  const ScoreBar({super.key, required this.snap});

  @override
  Widget build(BuildContext context) {
    final m = snap.clockSeconds ~/ 60;
    final s = (snap.clockSeconds % 60).toString().padLeft(2, '0');
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TikiPalette.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TikiPalette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Dot(TikiPalette.homeFill),
          const SizedBox(width: 6),
          Text('HOME', style: TikiText.display(size: 12, weight: 600)),
          const SizedBox(width: 10),
          Text('${snap.homeScore}', style: TikiText.display(size: 20)),
          const SizedBox(width: 12),
          Text(
            '$m:$s',
            style: TikiText.display(
              size: 13,
              weight: 500,
              color: TikiPalette.mutedText,
            ),
          ),
          const SizedBox(width: 12),
          Text('${snap.awayScore}', style: TikiText.display(size: 20)),
          const SizedBox(width: 10),
          Text('AWAY', style: TikiText.display(size: 12, weight: 600)),
          const SizedBox(width: 6),
          const _Dot(TikiPalette.awayFill),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot(this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
