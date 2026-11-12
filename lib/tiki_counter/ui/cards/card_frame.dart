import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Dimmed backdrop + centred dark panel used by every Tiki Counter card.
class CardFrame extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final Widget child;
  final double maxWidth;

  const CardFrame({
    super.key,
    this.eyebrow,
    required this.title,
    required this.child,
    this.maxWidth = 440,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xB3000000),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1813),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TikiPalette.frameBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  style: TikiText.body(size: 11, weight: 600),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: TikiText.display(size: 24)),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width button for cards. [primary] = solid cyan.
class CardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const CardButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? TikiPalette.cyan : const Color(0xFF111C17),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primary ? TikiPalette.cyan : TikiPalette.panelBorder,
          ),
        ),
        child: Text(
          label,
          style: TikiText.display(
            size: 14,
            color: primary ? const Color(0xFF04241D) : Colors.white,
          ),
        ),
      ),
    );
  }
}
