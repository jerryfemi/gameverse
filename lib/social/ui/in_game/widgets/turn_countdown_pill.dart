import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';

/// Floating status pill shown above the in-game H2H panel during live 1v1 online matches
/// indicating active throw turn and remaining shot clock per Artboard 4.
class TurnCountdownPill extends StatelessWidget {
  final int secondsRemaining;

  const TurnCountdownPill({
    super.key,
    required this.secondsRemaining,
  });

  static const Color _mint = Color(0xFF00FFCC);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: const Color(0xF20F172A),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: _mint.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _mint.withValues(alpha: 0.35),
            blurRadius: 12.0,
            spreadRadius: 1.0,
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'YOUR THROW',
            style: UiFont.style(
              size: 12.0,
              weight: 900,
              color: _mint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 6.0),
          Container(
            width: 4.0,
            height: 4.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _mint,
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            '${secondsRemaining}s',
            style: UiFont.style(
              size: 12.0,
              weight: 800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
