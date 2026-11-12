import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/game_plan/formation_tab.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/style_tab.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/tune_tab.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/model/game_mode.dart';

enum PlanTab {
  formation('Formation'),
  style('Playstyle'),
  tune('Tune');

  final String label;
  const PlanTab(this.label);
}

/// Formation, playstyle and fine-tuning, each tab with a big board.
/// Every change is handed up at once ([onChanged]) and saved.
class GamePlanScreen extends StatefulWidget {
  final TikiSetup setup;
  final ValueChanged<TikiSetup> onChanged;
  final VoidCallback onBack;
  final VoidCallback onTest;
  final PlanTab startTab;

  const GamePlanScreen({
    super.key,
    required this.setup,
    required this.onChanged,
    required this.onBack,
    required this.onTest,
    this.startTab = PlanTab.style,
  });

  @override
  State<GamePlanScreen> createState() => _GamePlanScreenState();
}

class _GamePlanScreenState extends State<GamePlanScreen> {
  late PlanTab _tab = widget.startTab;

  @override
  Widget build(BuildContext context) {
    final s = widget.setup;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuHeader(
              title: 'Game plan',
              subtitle: '${s.clubCode} · ${s.formation.name} · ${s.plan.name}',
              onBack: widget.onBack,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextTabs<GameMode>(
                    options: GameMode.values,
                    selected: s.mode,
                    label: (m) => m.label,
                    onChanged: (m) => widget.onChanged(s.copyWith(mode: m)),
                  ),
                  const SizedBox(width: 22),
                  _testButton(),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 120,
                    child: SideTabs<PlanTab>(
                      options: PlanTab.values,
                      selected: _tab,
                      label: (t) => t.label,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                  ),
                  Expanded(child: _body(s)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(TikiSetup s) => switch (_tab) {
    PlanTab.formation => FormationTab(setup: s, onChanged: widget.onChanged),
    PlanTab.style => StyleTab(setup: s, onChanged: widget.onChanged),
    PlanTab.tune => TuneTab(setup: s, onChanged: widget.onChanged),
  };

  Widget _testButton() => OutlinedButton.icon(
    onPressed: widget.onTest,
    icon: const Icon(Icons.play_arrow_rounded, color: TikiPalette.cyan),
    label: Text(
      'Test vs bot',
      style: TikiText.body(size: 14, weight: 700, color: TikiPalette.cyan),
    ),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      side: const BorderSide(color: TikiPalette.cyan),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
