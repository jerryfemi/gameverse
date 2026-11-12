import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Top-right: the debug toggle (shows each disc's job) and pause.
class TopButtons extends StatelessWidget {
  final bool debugOn;
  final VoidCallback onToggleDebug;
  final VoidCallback onPause;

  const TopButtons({
    super.key,
    required this.debugOn,
    required this.onToggleDebug,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _square(
          onTap: onToggleDebug,
          border: debugOn ? TikiPalette.cyan : TikiPalette.panelBorder,
          child: Text(
            'DBG',
            style: TikiText.display(
              size: 11,
              color: debugOn ? TikiPalette.cyan : TikiPalette.mutedText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _square(
          onTap: onPause,
          border: TikiPalette.panelBorder,
          child: const Icon(Icons.pause_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _square({
    required VoidCallback onTap,
    required Color border,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TikiPalette.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: child,
      ),
    );
  }
}
