import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/render/hud_model.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Short call-out near the top ("GOAL!", "OFFSIDE", "THROW-IN") that fades
/// in, holds, and fades out. A new banner restarts the animation.
class EventBanner extends StatelessWidget {
  final ValueNotifier<HudBanner?> banner;

  const EventBanner({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<HudBanner?>(
        valueListenable: banner,
        builder: (context, b, _) {
          if (b == null) return const SizedBox.shrink();
          final big = b.text == 'GOAL!';
          return Align(
            alignment: const Alignment(0, -0.55),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(b.serial),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: big ? 1800 : 1300),
              builder: (context, t, child) {
                final opacity = t < 0.12
                    ? t / 0.12
                    : (t > 0.78 ? (1.0 - t) / 0.22 : 1.0);
                final scale = 0.9 + 0.1 * (t < 0.12 ? t / 0.12 : 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: TikiPalette.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: big ? TikiPalette.cyan : TikiPalette.panelBorder,
                  ),
                ),
                child: Text(
                  b.text,
                  style: TikiText.display(
                    size: big ? 30 : 16,
                    color: big ? TikiPalette.cyan : Colors.white,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
