import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/ui/cards/card_frame.dart';
import 'package:b_ball/tiki_counter/ui/cards/choice_row.dart';
import 'package:b_ball/tiki_counter/ui/cards/stats_table.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Half-time: stats, a quick change of formation or style for your team,
/// then the second half (ends swap).
class HalfTimeCard extends StatefulWidget {
  final MatchState state;
  final VoidCallback onContinue;

  const HalfTimeCard({super.key, required this.state, required this.onContinue});

  @override
  State<HalfTimeCard> createState() => _HalfTimeCardState();
}

class _HalfTimeCardState extends State<HalfTimeCard> {
  late Formation _formation = widget.state.home.formation;
  late TeamPlan _plan = widget.state.home.plan;

  void _continue() {
    widget.state.home.formation = _formation;
    widget.state.home.plan = _plan;
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      eyebrow: 'HALF-TIME',
      title: 'First half stats',
      maxWidth: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatsTable(state: widget.state),
          const SizedBox(height: 14),
          ChoiceRow<Formation>(
            label: 'FORMATION',
            options: Formations.forMode(widget.state.mode),
            selected: _formation,
            name: (f) => f.name,
            onChanged: (f) => setState(() => _formation = f),
          ),
          ChoiceRow<TeamPlan>(
            label: 'PLAYSTYLE',
            options: Presets.all,
            selected: _plan,
            name: (p) => p.name,
            onChanged: (p) => setState(() => _plan = p),
          ),
          const SizedBox(height: 6),
          CardButton(
            label: 'START SECOND HALF',
            primary: true,
            onTap: _continue,
          ),
        ],
      ),
    );
  }
}

class FullTimeCard extends StatelessWidget {
  final MatchState state;
  final VoidCallback onPlayAgain;
  final VoidCallback onLobby;

  const FullTimeCard({
    super.key,
    required this.state,
    required this.onPlayAgain,
    required this.onLobby,
  });

  @override
  Widget build(BuildContext context) {
    final h = state.home.score;
    final a = state.away.score;
    final title = h > a ? 'You win' : (h < a ? 'You lose' : 'Draw');
    return CardFrame(
      eyebrow: 'FULL-TIME',
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatsTable(state: state),
          const SizedBox(height: 16),
          CardButton(label: 'PLAY AGAIN', primary: true, onTap: onPlayAgain),
          const SizedBox(height: 8),
          CardButton(label: 'MENU', onTap: onLobby),
        ],
      ),
    );
  }
}

class PauseCard extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLobby;

  const PauseCard({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onLobby,
  });

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      title: 'Paused',
      maxWidth: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardButton(label: 'RESUME', primary: true, onTap: onResume),
          const SizedBox(height: 8),
          CardButton(label: 'RESTART', onTap: onRestart),
          const SizedBox(height: 8),
          CardButton(label: 'MENU', onTap: onLobby),
        ],
      ),
    );
  }
}

/// End of a Lab drill: passed or failed, the time, and what next.
class DrillResultCard extends StatelessWidget {
  final bool passed;
  final String title;
  final String detail;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final VoidCallback onLab;

  const DrillResultCard({
    super.key,
    required this.passed,
    required this.title,
    required this.detail,
    required this.onRetry,
    required this.onNext,
    required this.onLab,
  });

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      eyebrow: title.toUpperCase(),
      title: passed ? 'Drill passed' : 'Not this time',
      maxWidth: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(detail, style: TikiText.body(size: 14, color: Colors.white)),
          const SizedBox(height: 16),
          CardButton(label: 'TRY AGAIN', primary: !passed || onNext == null, onTap: onRetry),
          if (passed && onNext != null) ...[
            const SizedBox(height: 8),
            CardButton(label: 'NEXT DRILL', primary: true, onTap: onNext!),
          ],
          const SizedBox(height: 8),
          CardButton(label: 'BACK TO LAB', onTap: onLab),
        ],
      ),
    );
  }
}
