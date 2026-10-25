import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/social/models/match_summary.dart';

/// Side-by-side comparison score cards displaying user score (cyan)
/// and opponent score (amber) with adaptive [FittedBox] typography.
class ResultsComparisonCards extends StatelessWidget {
  final MatchSummary summary;

  const ResultsComparisonCards({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: You
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 9.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0x1A38BDF8),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0x5538BDF8), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOU',
                  style: UiFont.style(
                    size: 10.0,
                    weight: 800,
                    color: const Color(0xFF38BDF8),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 1.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    summary.me.headline,
                    maxLines: 1,
                    style: UiFont.style(
                      size: 19.0,
                      weight: 900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (summary.me.unit.isNotEmpty) ...[
                  const SizedBox(height: 1.0),
                  Text(
                    summary.me.unit,
                    style: UiFont.style(
                      size: 10.0,
                      weight: 600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8.0),

        // Right: Opponent
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 9.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0x1AF59E0B),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0x55F59E0B), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.opponent.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiFont.style(
                    size: 10.0,
                    weight: 800,
                    color: const Color(0xFFF59E0B),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 1.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    summary.opponent.headline,
                    maxLines: 1,
                    style: UiFont.style(
                      size: 19.0,
                      weight: 900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (summary.opponent.unit.isNotEmpty) ...[
                  const SizedBox(height: 1.0),
                  Text(
                    summary.opponent.unit,
                    style: UiFont.style(
                      size: 10.0,
                      weight: 600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
