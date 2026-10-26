import 'package:flutter/material.dart';

import 'package:b_ball/game/match/match_session.dart';

/// Round-by-round score matrix matching Design Template 18:
/// Left score · ROUND [X] · Right score
class PodiumScoreMatrix extends StatelessWidget {
  final MatchSession session;

  const PodiumScoreMatrix({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final int totalRounds = session.totalRounds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < totalRounds; i++) ...[
            if (i > 0) const Divider(color: Color(0xFF1E2638), height: 16.0),
            _buildRoundRow(
              roundNumber: i + 1,
              p1Score: i < session.player1.roundScores.length ? session.player1.roundScores[i] : 0,
              p2Score: i < session.player2.roundScores.length ? session.player2.roundScores[i] : 0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundRow({
    required int roundNumber,
    required int p1Score,
    required int p2Score,
  }) {
    final bool p1Won = p1Score > p2Score;
    final bool p2Won = p2Score > p1Score;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 50.0,
          child: Text(
            '$p1Score',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: p1Won ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 14.0,
              fontWeight: p1Won ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          'ROUND $roundNumber',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(
          width: 50.0,
          child: Text(
            '$p2Score',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: p2Won ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 14.0,
              fontWeight: p2Won ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
