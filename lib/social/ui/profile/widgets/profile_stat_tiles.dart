import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';

/// 3-column stats panel for [ProfileSheet] displaying Wins, Win Rate, and Best Streak.
class ProfileStatTiles extends StatelessWidget {
  final int wins;
  final int winRate;
  final int bestStreak;

  const ProfileStatTiles({
    super.key,
    required this.wins,
    required this.winRate,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTile(value: '$wins', label: 'WINS'),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildTile(value: '$winRate%', label: 'WIN RATE'),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildTile(value: '$bestStreak', label: 'BEST STREAK'),
        ),
      ],
    );
  }

  Widget _buildTile({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: UiFont.style(
                size: 22.0,
                weight: 900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 3.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: UiFont.style(
                size: 10.5,
                weight: 800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
