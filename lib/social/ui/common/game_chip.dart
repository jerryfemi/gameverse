import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';

import 'package:b_ball/models/cloud_match.dart';

/// Translucent pill chip displaying the game's icon and label according to the design canvas.
class GameChip extends StatelessWidget {
  final String game;
  final double fontSize;
  final double iconSize;

  const GameChip({
    super.key,
    required this.game,
    this.fontSize = 11.0,
    this.iconSize = 13.0,
  });

  factory GameChip.fromMatch(CloudMatch match) => GameChip(game: match.game);

  @override
  Widget build(BuildContext context) {
    final g = game.toLowerCase().trim();
    final IconData icon;
    final Color color;
    final String label;

    if (g == 'darts') {
      icon = Icons.adjust_rounded;
      color = const Color(0xFFF87171);
      label = 'Darts 301';
    } else if (g == 'archery') {
      icon = Icons.arrow_outward_rounded;
      color = const Color(0xFF00FFCC);
      label = 'Archery';
    } else {
      icon = Icons.sports_basketball_rounded;
      color = const Color(0xFFF59E0B);
      label = 'Hoops';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF334155), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: UiFont.style(
              size: fontSize,
              weight: 800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
