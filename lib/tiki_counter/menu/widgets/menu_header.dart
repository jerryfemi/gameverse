import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Back arrow + page title + optional subtitle and trailing widget.
class MenuHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  const MenuHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MenuIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Back',
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Text(title, style: TikiText.display(size: 24, weight: 900)),
        if (subtitle != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              subtitle!,
              overflow: TextOverflow.ellipsis,
              style: TikiText.body(size: 13, color: TikiPalette.slate),
            ),
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// 44 px square icon button with a thin border.
class MenuIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MenuIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TikiPalette.frameBorder),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}

/// Small spaced-out caps label above a group.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text.toUpperCase(),
      style: TikiText.body(size: 11, weight: 700, color: TikiPalette.slate),
    ),
  );
}

/// Big solid cyan action button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TikiPalette.cyan,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              style: TikiText.display(
                size: 18,
                weight: 900,
                color: const Color(0xFF06120E),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
