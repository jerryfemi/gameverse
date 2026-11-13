import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/lab/drills_tab.dart';
import 'package:b_ball/tiki_counter/menu/lab/patterns_tab.dart';
import 'package:b_ball/tiki_counter/menu/lab/scenarios_tab.dart';
import 'package:b_ball/tiki_counter/menu/lab/watch_tab.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_choice.dart';
import 'package:tiki_core/drills/drill.dart';

enum LabTab {
  watch('Watch bots'),
  patterns('Patterns'),
  scenarios('Scenarios'),
  drills('Drills');

  final String label;
  const LabTab(this.label);
}

/// The Lab: test and learn tactics without playing a full match.
/// - Watch bots: pick both sides' playstyles, watch at ½×–2× with the
///   debug view on.
/// - Patterns: each combination your team knows, played on a loop.
/// - Scenarios: drag the ball anywhere; both teams take up their shape.
/// - Drills: short scored challenges.
class LabScreen extends StatefulWidget {
  final TikiSetup setup;
  final Map<String, double> bestTimes;
  final VoidCallback onBack;
  final ValueChanged<MatchChoice> onWatch;
  final ValueChanged<Drill> onDrill;

  const LabScreen({
    super.key,
    required this.setup,
    required this.bestTimes,
    required this.onBack,
    required this.onWatch,
    required this.onDrill,
  });

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  LabTab _tab = LabTab.watch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuHeader(
              title: 'Lab',
              subtitle: 'Test and learn tactics',
              onBack: widget.onBack,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 130,
                    child: SideTabs<LabTab>(
                      options: LabTab.values,
                      selected: _tab,
                      label: (t) => t.label,
                      onChanged: (t) => setState(() => _tab = t),
                    ),
                  ),
                  Expanded(child: _body()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() => switch (_tab) {
    LabTab.watch => WatchTab(setup: widget.setup, onWatch: widget.onWatch),
    LabTab.patterns => PatternsTab(setup: widget.setup),
    LabTab.scenarios => ScenariosTab(setup: widget.setup),
    LabTab.drills => DrillsTab(
      bestTimes: widget.bestTimes,
      onPlay: widget.onDrill,
    ),
  };
}
