import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/drills/drill.dart';

/// Top-centre during a drill: its name, the goal and the time left.
class DrillBar extends StatelessWidget {
  final Drill drill;
  final ValueNotifier<double> elapsed;

  const DrillBar({super.key, required this.drill, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: TikiPalette.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TikiPalette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drill.title, style: TikiText.display(size: 13, weight: 900)),
                Text(
                  drill.goal,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TikiText.body(size: 11, color: const Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ValueListenableBuilder<double>(
            valueListenable: elapsed,
            builder: (context, t, _) {
              final left = (drill.timeLimit - t).clamp(0.0, drill.timeLimit).toDouble();
              return Text(
                left.toStringAsFixed(1),
                style: TikiText.display(
                  size: 22,
                  weight: 900,
                  color: left < 3.0 ? const Color(0xFFEF4444) : TikiPalette.cyan,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ½× · 1× · 2× for watched matches.
class SpeedBar extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;

  const SpeedBar({super.key, required this.speed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [(0.5, '½×'), (1.0, '1×'), (2.0, '2×')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: TikiPalette.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TikiPalette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            GestureDetector(
              onTap: () => onChanged(o.$1),
              child: Container(
                width: 40,
                height: 28,
                alignment: Alignment.center,
                child: Text(
                  o.$2,
                  style: TikiText.display(
                    size: 13,
                    weight: speed == o.$1 ? 900 : 600,
                    color: speed == o.$1 ? TikiPalette.cyan : TikiPalette.slate,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
