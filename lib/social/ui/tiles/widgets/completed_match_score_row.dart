import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';

/// Middle row in [CompletedMatchTile] displaying You vs Opponent avatars,
/// crowned status, and headline scores with adaptive [FittedBox] scaling.
class CompletedMatchScoreRow extends StatelessWidget {
  final MatchSummary summary;

  const CompletedMatchScoreRow({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // You Avatar
        CrownAvatar(
          avatar: summary.me.avatar,
          size: 40.0,
          crowned: summary.didIWin == true,
        ),
        const SizedBox(width: 10.0),

        // You Score
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOU',
                style: UiFont.style(
                  size: 11.0,
                  weight: 800,
                  color: const Color(0xFF38BDF8),
                  letterSpacing: 0.5,
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
                    size: 18.0,
                    weight: 900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (summary.me.unit.isNotEmpty) ...[
                const SizedBox(height: 1.0),
                Text(
                  summary.me.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiFont.style(
                    size: 11.0,
                    weight: 600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),

        // VS divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            'VS',
            style: UiFont.style(
              size: 11.0,
              weight: 800,
              color: const Color(0xFF475569),
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Opponent Score
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                summary.opponent.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiFont.style(
                  size: 11.0,
                  weight: 800,
                  color: const Color(0xFFF59E0B),
                  letterSpacing: 0.5,
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
                    size: 18.0,
                    weight: 900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (summary.opponent.unit.isNotEmpty) ...[
                const SizedBox(height: 1.0),
                Text(
                  summary.opponent.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiFont.style(
                    size: 11.0,
                    weight: 600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10.0),

        // Opponent Avatar
        CrownAvatar(
          avatar: summary.opponent.avatar,
          size: 40.0,
          crowned: summary.didIWin == false,
        ),
      ],
    );
  }
}
