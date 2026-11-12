import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/cards/card_frame.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/model/game_mode.dart';

typedef StartMatch = void Function(GameMode mode, {required bool watch});

/// First screen: pick 5v5 or 7v7 against the bot, or watch two bots.
class StartCard extends StatelessWidget {
  final StartMatch onStart;
  final VoidCallback onBack;

  const StartCard({super.key, required this.onStart, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      eyebrow: 'TIKI COUNTER · EARLY BUILD',
      title: 'Football on a tactics board',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No dribbling. Move, pass and press to break them down. '
            '7 minutes, half-time at 3:30.',
            style: TikiText.body(size: 13),
          ),
          const SizedBox(height: 16),
          for (final mode in GameMode.values) ...[
            CardButton(
              label: '${mode.label} VS BOT'
                  '${mode.offside ? '  ·  OFFSIDE ON' : ''}',
              primary: mode == GameMode.fiveASide,
              onTap: () => onStart(mode, watch: false),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          Text('Watch bots play', style: TikiText.body(size: 11, weight: 600)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final mode in GameMode.values) ...[
                Expanded(
                  child: CardButton(
                    label: mode.label,
                    onTap: () => onStart(mode, watch: true),
                  ),
                ),
                if (mode != GameMode.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Touch: joystick to move · PASS / THROUGH / LOB / SHOOT: hold for '
            'power, release to kick, aim with the joystick · DASH with the '
            'ball is faster but your touches get heavy · PRESS closes down · '
            'SWITCH: tap or swipe.',
            style: TikiText.body(size: 11, color: TikiPalette.slate),
          ),
          const SizedBox(height: 6),
          Text(
            'Keyboard: WASD / arrows move · J pass · K through · L shoot · '
            'U lob (hold for power) · Space dash / press · defending: '
            'J tackle · K switch · L 2nd man · Esc pause.',
            style: TikiText.body(size: 11, color: TikiPalette.slate),
          ),
          const SizedBox(height: 12),
          CardButton(label: 'BACK', onTap: onBack),
        ],
      ),
    );
  }
}
