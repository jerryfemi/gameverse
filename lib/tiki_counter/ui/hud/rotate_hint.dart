import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// On a phone held upright, suggests turning it sideways (tap to hide).
class RotateHint extends StatefulWidget {
  const RotateHint({super.key});

  @override
  State<RotateHint> createState() => _RotateHintState();
}

class _RotateHintState extends State<RotateHint> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final portraitPhone = MediaQuery.sizeOf(context).shortestSide < 600 &&
        MediaQuery.orientationOf(context) == Orientation.portrait;
    if (_dismissed || !portraitPhone) return const SizedBox.shrink();
    return Align(
      alignment: const Alignment(0, 0.75),
      child: GestureDetector(
        onTap: () => setState(() => _dismissed = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: TikiPalette.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TikiPalette.panelBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.screen_rotation_rounded,
                color: TikiPalette.cyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Turn your phone sideways for the full board',
                style: TikiText.body(size: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
