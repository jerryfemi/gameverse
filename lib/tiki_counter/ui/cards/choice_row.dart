import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// A small label and a wrap of selectable chips (one choice).
class ChoiceRow<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T selected;
  final String Function(T) name;
  final ValueChanged<T> onChanged;

  const ChoiceRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.name,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TikiText.body(size: 11, weight: 600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final o in options) _chip(o)],
          ),
        ],
      ),
    );
  }

  Widget _chip(T o) {
    final on = o == selected;
    return GestureDetector(
      onTap: () => onChanged(o),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? const Color(0xFF062B24) : const Color(0xFF111C17),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: on ? TikiPalette.cyan : TikiPalette.panelBorder,
          ),
        ),
        child: Text(
          name(o),
          style: TikiText.body(
            size: 12,
            weight: 600,
            color: on ? TikiPalette.cyan : const Color(0xFFCFDAD3),
          ),
        ),
      ),
    );
  }
}
