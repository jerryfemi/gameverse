import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/home/club_badge.dart';
import 'package:b_ball/tiki_counter/menu/setup/opponent_clubs.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/cards/match_choice.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Slides in from the right over the home screen. Everything is already
/// set from your saved setup, so it's usually one tap: KICK OFF.
/// [watch] = Lab's "watch bots play" (your playstyle on both bots).
Future<void> showKickOffSheet(
  BuildContext context, {
  required TikiSetup setup,
  required bool watch,
  required ValueChanged<TikiSetup> onSetupChanged,
  required ValueChanged<MatchChoice> onStart,
  required VoidCallback onEditPlan,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x99050806),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.centerRight,
      child: _KickOffSheet(
        setup: setup,
        watch: watch,
        onSetupChanged: onSetupChanged,
        onStart: (c) {
          Navigator.of(context).pop();
          onStart(c);
        },
        onEditPlan: () {
          Navigator.of(context).pop();
          onEditPlan();
        },
      ),
    ),
    transitionBuilder: (context, anim, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(anim),
      child: child,
    ),
  );
}

class _KickOffSheet extends StatefulWidget {
  final TikiSetup setup;
  final bool watch;
  final ValueChanged<TikiSetup> onSetupChanged;
  final ValueChanged<MatchChoice> onStart;
  final VoidCallback onEditPlan;

  const _KickOffSheet({
    required this.setup,
    required this.watch,
    required this.onSetupChanged,
    required this.onStart,
    required this.onEditPlan,
  });

  @override
  State<_KickOffSheet> createState() => _KickOffSheetState();
}

/// "Random" sits in front of the presets in the opponent's row.
const TeamPlan _random = TeamPlan(name: 'Random');

class _KickOffSheetState extends State<_KickOffSheet> {
  late TikiSetup _setup = widget.setup;
  TeamPlan _opponentPlan = _random;
  late final OpponentClub _opponent = OpponentClubs.random(
    math.Random(),
    avoidCode: widget.setup.clubCode,
  );

  void _change(TikiSetup s) {
    setState(() => _setup = s);
    widget.onSetupChanged(s);
  }

  void _go() => widget.onStart(
    MatchChoice(
      mode: _setup.mode,
      watch: widget.watch,
      homeFormation: _setup.formation,
      homePlan: _setup.plan,
      awayPlan: identical(_opponentPlan, _random) ? null : _opponentPlan,
      botLevel: _setup.level,
      homeName: _setup.clubName,
      homeCode: _setup.clubCode,
      opponent: _opponent,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final width = math.min(460.0, MediaQuery.sizeOf(context).width * 0.9);
    return Material(
      color: const Color(0xFF0D1612),
      child: Container(
        width: width,
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: TikiPalette.frameBorder)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      widget.watch ? 'Watch bots' : 'Kick off',
                      style: TikiText.display(size: 28, weight: 900),
                    ),
                    const Spacer(),
                    MenuIconButton(
                      icon: Icons.close_rounded,
                      label: 'Close',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _matchup(),
                const SizedBox(height: 18),
                const SectionLabel('Mode'),
                TextTabs<GameMode>(
                  options: GameMode.values,
                  selected: _setup.mode,
                  label: (m) => m.offside ? '${m.label} · offside' : m.label,
                  onChanged: (m) => _change(_setup.copyWith(mode: m)),
                ),
                const SizedBox(height: 14),
                SectionLabel(widget.watch ? 'Bot level' : 'Opponent level'),
                TextTabs<BotLevel>(
                  options: BotLevel.all,
                  selected: _setup.level,
                  label: (l) => l.name,
                  onChanged: (l) => _change(_setup.copyWith(botLevel: l.name)),
                ),
                const SizedBox(height: 14),
                const SectionLabel('Opponent playstyle'),
                TextTabs<TeamPlan>(
                  options: const [_random, ...Presets.all],
                  selected: _opponentPlan,
                  label: (p) => p.name,
                  onChanged: (p) => setState(() => _opponentPlan = p),
                ),
                const SizedBox(height: 18),
                _playstyle(),
                const SizedBox(height: 22),
                _kickOffButton(),
                const SizedBox(height: 8),
                Text(
                  '7 minutes · half-time at 3:30',
                  textAlign: TextAlign.center,
                  style: TikiText.body(size: 12, color: TikiPalette.slate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchup() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TikiPalette.frameBorder),
      ),
      child: Row(
        children: [
          ClubBadge(code: _setup.clubCode, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _setup.clubName,
              overflow: TextOverflow.ellipsis,
              style: TikiText.display(size: 15, weight: 800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('vs', style: TikiText.body(size: 12, color: TikiPalette.slate)),
          ),
          Expanded(
            child: Text(
              _opponent.name,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TikiText.display(size: 15, weight: 800, color: TikiPalette.amber),
            ),
          ),
          const SizedBox(width: 10),
          ClubBadge(code: _opponent.code, size: 38, away: true),
        ],
      ),
    );
  }

  Widget _playstyle() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Your playstyle'),
              Text(
                '${_setup.plan.name} · ${_setup.formation.name}',
                style: TikiText.display(size: 16, weight: 800),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: widget.onEditPlan,
          child: Text(
            'Edit',
            style: TikiText.body(size: 14, weight: 700, color: TikiPalette.cyan),
          ),
        ),
      ],
    );
  }

  Widget _kickOffButton() => PrimaryButton(
    label: widget.watch ? 'WATCH' : 'KICK OFF',
    height: 60,
    onTap: _go,
  );
}
