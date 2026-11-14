import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/game_plan/formation_tab.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/style_tab.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/tune_tab.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/tabbed_page.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/layout/page_shape.dart';
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
    final shape = PageShape.of(context);
    return TabbedPage<PlanTab>(
      title: 'Game plan',
      subtitle: '${s.clubCode} · ${s.formation.name} · ${s.plan.name}',
      onBack: widget.onBack,
      tabs: PlanTab.values,
      selected: _tab,
      label: (t) => t.label,
      onTab: (t) => setState(() => _tab = t),
      sideTabsWidth: 120,
      extra: TextTabs<GameMode>(
        options: GameMode.values,
        selected: s.mode,
        label: (m) => m.label,
        size: shape.wide ? 14 : 13,
        gap: shape.wide ? 22 : 16,
        onChanged: (m) => widget.onChanged(s.copyWith(mode: m)),
      ),
      action: _testButton(short: !shape.wide),
      body: _body(s),
    );
  }

  Widget _body(TikiSetup s) => switch (_tab) {
    PlanTab.formation => FormationTab(setup: s, onChanged: widget.onChanged),
    PlanTab.style => StyleTab(setup: s, onChanged: widget.onChanged),
    PlanTab.tune => TuneTab(setup: s, onChanged: widget.onChanged),
  };

  /// "Test vs bot"; just "Test" where room is short.
  Widget _testButton({required bool short}) => OutlinedButton.icon(
    onPressed: widget.onTest,
    icon: const Icon(Icons.play_arrow_rounded, color: TikiPalette.cyan),
    label: Text(
      short ? 'Test' : 'Test vs bot',
      style: TikiText.body(size: 14, weight: 700, color: TikiPalette.cyan),
    ),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: EdgeInsets.symmetric(horizontal: short ? 12 : 16),
      side: const BorderSide(color: TikiPalette.cyan),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
