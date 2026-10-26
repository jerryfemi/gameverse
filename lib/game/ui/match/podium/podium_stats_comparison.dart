import 'package:flutter/material.dart';

import 'package:b_ball/game/match/match_session.dart';

/// Detailed match stats comparison table matching Design Template 18:
/// Field Goals, Accuracy, Swishes, and Best Streak.
class PodiumStatsComparison extends StatelessWidget {
  final MatchSession session;

  const PodiumStatsComparison({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final p1 = session.player1;
    final p2 = session.player2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        children: [
          _buildRow(
            label: 'FIELD GOALS',
            p1Value: '${p1.totalMadeShots}/${p1.totalAttemptedShots}',
            p2Value: '${p2.totalMadeShots}/${p2.totalAttemptedShots}',
            p1Better: p1.totalMadeShots > p2.totalMadeShots,
            p2Better: p2.totalMadeShots > p1.totalMadeShots,
          ),
          const Divider(color: Color(0xFF1E2638), height: 16.0),
          _buildRow(
            label: 'ACCURACY',
            p1Value: '${p1.overallAccuracy.toStringAsFixed(1)}%',
            p2Value: '${p2.overallAccuracy.toStringAsFixed(1)}%',
            p1Better: p1.overallAccuracy > p2.overallAccuracy,
            p2Better: p2.overallAccuracy > p1.overallAccuracy,
          ),
          const Divider(color: Color(0xFF1E2638), height: 16.0),
          _buildRow(
            label: 'SWISHES',
            p1Value: '${p1.totalSwishes}',
            p2Value: '${p2.totalSwishes}',
            p1Better: p1.totalSwishes > p2.totalSwishes,
            p2Better: p2.totalSwishes > p1.totalSwishes,
          ),
          const Divider(color: Color(0xFF1E2638), height: 16.0),
          _buildRow(
            label: 'BEST STREAK',
            p1Value: 'x${p1.bestStreakAcrossMatch}',
            p2Value: 'x${p2.bestStreakAcrossMatch}',
            p1Better: p1.bestStreakAcrossMatch > p2.bestStreakAcrossMatch,
            p2Better: p2.bestStreakAcrossMatch > p1.bestStreakAcrossMatch,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String p1Value,
    required String p2Value,
    required bool p1Better,
    required bool p2Better,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 70.0,
          child: Text(
            p1Value,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: p1Better ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 13.5,
              fontWeight: p1Better ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(
          width: 70.0,
          child: Text(
            p2Value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: p2Better ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 13.5,
              fontWeight: p2Better ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
