import 'package:flutter/material.dart';

/// Fixed rules info card for official Archery and Darts sets.
class MatchRulesCard extends StatelessWidget {
  final bool isArchery;

  const MatchRulesCard({
    super.key,
    required this.isArchery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArchery ? 'OFFICIAL SET RULES' : 'OFFICIAL 301 RULES',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            isArchery
                ? '• Sets of 3 arrows each (first to 6 set points)\n• 2 set points for winning a set, 1 each on a tie\n• 45s shot clock per set'
                : '• 301 points countdown to exactly zero\n• 3 darts per turn · 20 rounds maximum\n• Must finish with a double or bullseye',
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12.0,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
