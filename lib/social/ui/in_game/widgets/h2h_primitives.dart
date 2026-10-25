import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';

/// Two-tone split ratio bar comparing your wins (Sky blue) against opponent wins (Amber).
class H2HSplitBar extends StatelessWidget {
  final double myRatio;
  final double height;

  const H2HSplitBar({
    super.key,
    required this.myRatio,
    this.height = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              flex: (myRatio * 100).round().clamp(1, 99),
              child: Container(color: const Color(0xFF38BDF8)),
            ),
            const SizedBox(width: 2.0),
            Expanded(
              flex: ((1.0 - myRatio) * 100).round().clamp(1, 99),
              child: Container(color: const Color(0xFFF59E0B)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular W/L/D outcome dot for Last-5 performance history.
class H2HOutcomeDot extends StatelessWidget {
  final bool? didWin;

  const H2HOutcomeDot({super.key, required this.didWin});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color textColor;

    if (didWin == true) {
      label = 'W';
      bg = const Color(0xFF00FFCC);
      textColor = const Color(0xFF0B2E28);
    } else if (didWin == false) {
      label = 'L';
      bg = const Color(0x2EF87171);
      textColor = const Color(0xFFF87171);
    } else {
      label = 'D';
      bg = const Color(0xFF1E2638);
      textColor = const Color(0xFF94A3B8);
    }

    return Container(
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          label,
          style: UiFont.style(size: 11.0, weight: 900, color: textColor),
        ),
      ),
    );
  }
}
