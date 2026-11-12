import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/ui/cards/card_frame.dart';
import 'package:b_ball/tiki_counter/ui/cards/stats_table.dart';

/// Half-time: stats, then the second half.
/// (Milestone 8 adds the quick tactics changes here.)
class HalfTimeCard extends StatelessWidget {
  final MatchState state;
  final VoidCallback onContinue;

  const HalfTimeCard({super.key, required this.state, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      eyebrow: 'HALF-TIME',
      title: 'First half stats',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatsTable(state: state),
          const SizedBox(height: 16),
          CardButton(label: 'START SECOND HALF', primary: true, onTap: onContinue),
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
          CardButton(label: 'LOBBY', onTap: onLobby),
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
          CardButton(label: 'NEW MATCH', onTap: onRestart),
          const SizedBox(height: 8),
          CardButton(label: 'LOBBY', onTap: onLobby),
        ],
      ),
    );
  }
}
