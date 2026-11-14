import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/game_plan/plan_panel.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/drills/drill.dart';

/// Short scored challenges. Each starts from a staged moment against a
/// bot with a fitting playstyle; you play it with the normal controls.
class DrillsTab extends StatelessWidget {
  final Map<String, double> bestTimes;
  final ValueChanged<Drill> onPlay;

  const DrillsTab({super.key, required this.bestTimes, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: Drills.all.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _row(Drills.all[i]),
    );
  }

  Widget _row(Drill d) {
    final best = bestTimes[d.id];
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(d.title, style: TikiText.display(size: 18, weight: 900)),
            Text(
              '${d.mode.label} · vs ${d.opponentPlan.name} · '
              '${d.timeLimit.round()} s',
              style: TikiText.body(size: 12, color: TikiPalette.slate),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(d.goal, style: TikiText.body(size: 14, weight: 600, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          d.lesson,
          style: TikiText.body(size: 12, color: const Color(0xFFCBD5E1)),
        ),
      ],
    );
    final bestText = Text(
      best == null ? 'Not done yet' : 'Best ${best.toStringAsFixed(1)} s',
      style: TikiText.body(
        size: 12,
        weight: 700,
        color: best == null ? TikiPalette.slate : TikiPalette.cyan,
      ),
    );
    return PlanPanel(
      // Narrow: the best time and PLAY go under the text.
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth < 460
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: 12),
                  Row(children: [bestText, const Spacer(), _play(d)]),
                ],
              )
            : Row(
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [bestText, const SizedBox(height: 8), _play(d)],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _play(Drill d) => SizedBox(
    width: 110,
    height: 44,
    child: Material(
      color: TikiPalette.cyan,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onPlay(d),
        child: Center(
          child: Text(
            'PLAY',
            style: TikiText.display(
              size: 15,
              weight: 900,
              color: const Color(0xFF06120E),
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    ),
  );
}
