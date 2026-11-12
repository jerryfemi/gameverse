import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// One-line key reminder shown at the bottom while playing with a keyboard.
/// Changes with possession, like the touch buttons.
class KeyHint extends StatelessWidget {
  final bool attacking;

  const KeyHint({super.key, required this.attacking});

  @override
  Widget build(BuildContext context) {
    final text = attacking
        ? 'WASD move  ·  J pass  ·  K through  ·  L shoot  ·  U lob  ·  '
              'Space dash  ·  hold for power'
        : 'WASD move  ·  Space press  ·  J tackle  ·  K switch (+ direction)'
              '  ·  L 2nd man';
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TikiPalette.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TikiPalette.panelBorder),
          ),
          child: Text(
            text,
            style: TikiText.body(size: 11, color: TikiPalette.slate),
          ),
        ),
      ),
    );
  }
}
