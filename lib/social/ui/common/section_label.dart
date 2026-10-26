import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';

/// Standardized section label header with 11px w800 uppercase typography
/// and optional trailing action widget (e.g. "See all", "All matches").
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionLabel({
    super.key,
    required this.text,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text.toUpperCase(),
            style: UiFont.style(
              size: 11.0,
              weight: 800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.1,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
