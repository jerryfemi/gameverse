import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// A row of plain text labels; the selected one is white with a short cyan
/// underline. Takes far less room than chips. Scrolls sideways if needed.
class TextTabs<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final double size;
  final double gap;

  const TextTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.size = 14,
    this.gap = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _TextTab(
              text: label(options[i]),
              on: options[i] == selected,
              size: size,
              onTap: () => onChanged(options[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Same idea, stacked vertically (the game plan side menu).
class SideTabs<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  const SideTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _TextTab(
              text: label(o),
              on: o == selected,
              size: 17,
              onTap: () => onChanged(o),
            ),
          ),
      ],
    );
  }
}

class _TextTab extends StatelessWidget {
  final String text;
  final bool on;
  final double size;
  final VoidCallback onTap;

  const _TextTab({
    required this.text,
    required this.on,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TikiText.display(
                  size: size,
                  weight: on ? 800 : 600,
                  color: on ? Colors.white : TikiPalette.slate,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: on ? 22 : 0,
                color: TikiPalette.cyan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
