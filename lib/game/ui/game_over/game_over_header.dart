import 'package:flutter/material.dart';

import 'package:b_ball/game/basketball_game.dart';

/// Header section of the Game Over card matching Design Template 20:
/// - "TIME'S UP" uppercase title
/// - Giant score numerals
/// - "points · best [best], [diff] to beat it" subtitle
class GameOverHeader extends StatelessWidget {
  final GameRoundStats stats;

  const GameOverHeader({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final int best = stats.bestScore;
    final int score = stats.score;
    final bool isBest = stats.isNewRecord || score >= best;
    final int diff = best - score;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TIME'S UP or NEW RECORD title
        Text(
          isBest ? "NEW PERSONAL BEST!" : "TIME'S UP",
          style: TextStyle(
            color: isBest ? const Color(0xFF00FFCC) : const Color(0xFF94A3B8),
            fontSize: 12.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6.0),

        // Giant Final Score Numerals
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72.0,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 6.0),

        // Subtitle: points · best 116, 34 to beat it
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            children: [
              const TextSpan(text: 'points · best '),
              TextSpan(
                text: '$best',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: isBest ? ' (new high score!)' : ', $diff to beat it',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
