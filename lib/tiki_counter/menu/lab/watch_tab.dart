import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/game_plan/plan_panel.dart';
import 'package:b_ball/tiki_counter/menu/setup/opponent_clubs.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_choice.dart';
import 'package:b_ball/tiki_counter/ui/layout/page_shape.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Bot vs bot with both sides chosen: the quickest way to see whether a
/// playstyle beats another. The match runs with speed controls and the
/// debug view on (each disc's job and target).
class WatchTab extends StatefulWidget {
  final TikiSetup setup;
  final ValueChanged<MatchChoice> onWatch;

  const WatchTab({super.key, required this.setup, required this.onWatch});

  @override
  State<WatchTab> createState() => _WatchTabState();
}

class _WatchTabState extends State<WatchTab> {
  late GameMode _mode = widget.setup.mode;
  late TeamPlan _yours = widget.setup.plan;
  TeamPlan _theirs = Presets.lowBlock;
  BotLevel _level = BotLevel.normal;

  List<TeamPlan> get _styles => [
    ...Presets.all,
    if (!Presets.all.any((p) => p.name == widget.setup.plan.name))
      widget.setup.plan,
  ];

  TeamPlan _match(TeamPlan p) =>
      _styles.firstWhere((s) => s.name == p.name, orElse: () => _styles.first);

  void _go() {
    final s = widget.setup;
    widget.onWatch(
      MatchChoice(
        mode: _mode,
        watch: true,
        homeFormation: s.formationFor(_mode),
        homePlan: _yours,
        awayPlan: _theirs,
        botLevel: _level,
        homeName: s.clubName,
        homeCode: s.clubCode,
        opponent: OpponentClubs.random(math.Random(), avoidCode: s.clubCode),
        lab: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shape = PageShape.of(context);
    final wrap = !shape.wide;
    final choices = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Mode'),
        TextTabs<GameMode>(
          options: GameMode.values,
          selected: _mode,
          label: (m) => m.label,
          wrap: wrap,
          onChanged: (m) => setState(() => _mode = m),
        ),
        const SizedBox(height: 16),
        SectionLabel('${widget.setup.clubCode} (white) playstyle'),
        TextTabs<TeamPlan>(
          options: _styles,
          selected: _match(_yours),
          label: (p) => p.name,
          wrap: wrap,
          onChanged: (p) => setState(() => _yours = p),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Opponent (amber) playstyle'),
        TextTabs<TeamPlan>(
          options: Presets.all,
          selected: _theirs,
          label: (p) => p.name,
          wrap: wrap,
          onChanged: (p) => setState(() => _theirs = p),
        ),
        const SizedBox(height: 16),
        const SectionLabel('How well both bots play'),
        TextTabs<BotLevel>(
          options: BotLevel.all,
          selected: _level,
          label: (l) => l.name,
          wrap: wrap,
          onChanged: (l) => setState(() => _level = l),
        ),
      ],
    );
    final about = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_match(_yours).name} vs ${_theirs.name}',
          style: TikiText.display(size: 20, weight: 900),
        ),
        const SizedBox(height: 10),
        Text(
          'Both teams are bots. The debug view is on: every disc shows '
          'its job and where it is heading. Use ½× to follow the runs, '
          '2× to get through a half quickly.',
          style: TikiText.body(size: 13, color: const Color(0xFFCBD5E1)),
        ),
        const SizedBox(height: 10),
        Text(
          'Watched matches don\'t count in your club record.',
          style: TikiText.body(size: 12, color: TikiPalette.slate),
        ),
      ],
    );
    final watch = PrimaryButton(label: 'WATCH', onTap: _go);

    // Phone upright: one column, the button last.
    if (shape.stacked) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          choices,
          const SizedBox(height: 18),
          PlanPanel(child: about),
          const SizedBox(height: 14),
          watch,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SingleChildScrollView(child: choices)),
        SizedBox(width: shape.gap),
        SizedBox(
          width: shape.side(280),
          child: PlanPanel(
            padding: EdgeInsets.all(shape.compact ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SingleChildScrollView(child: about)),
                const SizedBox(height: 12),
                watch,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
