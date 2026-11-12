import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/cards/card_frame.dart';
import 'package:b_ball/tiki_counter/ui/cards/choice_row.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_choice.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// First screen: mode, your formation and style, the bot's style and level,
/// then play — or watch two bots.
class StartCard extends StatefulWidget {
  final ValueChanged<MatchChoice> onStart;
  final VoidCallback onBack;

  const StartCard({super.key, required this.onStart, required this.onBack});

  @override
  State<StartCard> createState() => _StartCardState();
}

class _StartCardState extends State<StartCard> {
  GameMode _mode = GameMode.fiveASide;
  Formation _formation = Formations.defaultFor(GameMode.fiveASide);
  TeamPlan _plan = Presets.tikiTaka;
  TeamPlan? _botPlan; // null = random
  BotLevel _level = BotLevel.normal;

  void _go(bool watch) => widget.onStart(
    MatchChoice(
      mode: _mode,
      watch: watch,
      homeFormation: _formation,
      homePlan: _plan,
      awayPlan: _botPlan,
      botLevel: _level,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      eyebrow: 'TIKI COUNTER · EARLY BUILD',
      title: 'Football on a tactics board',
      maxWidth: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No dribbling. Move, pass and press to break them down. '
            '7 minutes, half-time at 3:30.',
            style: TikiText.body(size: 13),
          ),
          const SizedBox(height: 14),
          ChoiceRow<GameMode>(
            label: 'MODE',
            options: GameMode.values,
            selected: _mode,
            name: (m) => m.offside ? '${m.label} · offside on' : m.label,
            onChanged: (m) => setState(() {
              _mode = m;
              _formation = Formations.defaultFor(m);
            }),
          ),
          ChoiceRow<Formation>(
            label: 'YOUR FORMATION',
            options: Formations.forMode(_mode),
            selected: _formation,
            name: (f) => f.name,
            onChanged: (f) => setState(() => _formation = f),
          ),
          Text(
            _formation.blurb,
            style: TikiText.body(size: 11, color: TikiPalette.slate),
          ),
          const SizedBox(height: 10),
          ChoiceRow<TeamPlan>(
            label: 'YOUR STYLE',
            options: Presets.all,
            selected: _plan,
            name: (p) => p.name,
            onChanged: (p) => setState(() => _plan = p),
          ),
          ChoiceRow<TeamPlan?>(
            label: 'BOT STYLE',
            options: [null, ...Presets.all],
            selected: _botPlan,
            name: (p) => p?.name ?? 'Random',
            onChanged: (p) => setState(() => _botPlan = p),
          ),
          ChoiceRow<BotLevel>(
            label: 'BOT LEVEL',
            options: BotLevel.all,
            selected: _level,
            name: (l) => l.name,
            onChanged: (l) => setState(() => _level = l),
          ),
          const SizedBox(height: 6),
          CardButton(label: 'PLAY VS BOT', primary: true, onTap: () => _go(false)),
          const SizedBox(height: 8),
          CardButton(label: 'WATCH BOTS PLAY', onTap: () => _go(true)),
          const SizedBox(height: 14),
          Text(
            'Touch: joystick to move · PASS / THROUGH / LOB / SHOOT: hold for '
            'power, release to kick, aim with the joystick · DASH with the '
            'ball is faster but your touches get heavy · PRESS closes down · '
            'SWITCH: tap or swipe.',
            style: TikiText.body(size: 11, color: TikiPalette.slate),
          ),
          const SizedBox(height: 6),
          Text(
            'Keyboard: WASD / arrows move · J pass · K through · L shoot · '
            'U lob (hold for power) · Space dash / press · defending: '
            'J tackle · K switch · L 2nd man · Esc pause.',
            style: TikiText.body(size: 11, color: TikiPalette.slate),
          ),
          const SizedBox(height: 12),
          CardButton(label: 'BACK', onTap: widget.onBack),
        ],
      ),
    );
  }
}
