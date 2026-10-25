import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';

/// Empty state widget for active or completed matches tabs in [MatchesPage].
class MatchesEmptyState extends StatelessWidget {
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;

  const MatchesEmptyState({
    super.key,
    required this.message,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: UiFont.style(
                size: 14.5,
                weight: 600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                elevation: 0,
              ),
              child: Text(
                ctaLabel,
                style: UiFont.style(
                  size: 13.5,
                  weight: 800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
