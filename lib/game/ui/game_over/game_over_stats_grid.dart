import 'package:flutter/material.dart';

import 'package:b_ball/game/basketball_game.dart';

/// 2x2 grid displaying 4 distinct stat cards matching Design Template 20:
/// - FIELD GOALS ([made]/[total], [acc]% accuracy)
/// - BEST STREAK (x[streak], on fire at 6+)
/// - SWISHES ([count], +3 each)
/// - BANK SHOTS ([count], +3 each)
class GameOverStatsGrid extends StatelessWidget {
  final GameRoundStats stats;

  const GameOverStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GameOverStatCard(
                label: 'FIELD GOALS',
                value: '${stats.madeShots}/${stats.totalShots}',
                subtitle: '${stats.accuracy.round()}% accuracy',
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: GameOverStatCard(
                label: 'BEST STREAK',
                value: 'x${stats.bestStreak}',
                subtitle: stats.bestStreak >= 6 ? 'on fire at 6+' : 'streak bonus',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        Row(
          children: [
            Expanded(
              child: GameOverStatCard(
                label: 'SWISHES',
                value: '${stats.swishCount}',
                subtitle: '+3 each',
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: GameOverStatCard(
                label: 'BANK SHOTS',
                value: '${stats.bankCount}',
                subtitle: '+3 each',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual statistic card container.
class GameOverStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const GameOverStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
