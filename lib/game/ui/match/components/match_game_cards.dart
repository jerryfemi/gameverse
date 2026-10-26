import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 3 game selection cards (HOOPS, ARCHERY, DARTS) matching Templates 16 and 17.
class MatchGameCards extends StatelessWidget {
  final String selectedGame;
  final bool enabled;
  final ValueChanged<String> onGameSelected;

  const MatchGameCards({
    super.key,
    required this.selectedGame,
    required this.enabled,
    required this.onGameSelected,
  });

  static const Color hoopsColor = Color(0xFFF59E0B);
  static const Color archeryColor = Color(0xFF00FFCC);
  static const Color dartsColor = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCard(
          key: 'basketball',
          label: 'HOOPS',
          icon: Icons.sports_basketball_rounded,
          accent: hoopsColor,
          isSelected: selectedGame == 'basketball',
        ),
        const SizedBox(width: 8.0),
        _buildCard(
          key: 'archery',
          label: 'ARCHERY',
          icon: Icons.track_changes_rounded,
          accent: archeryColor,
          isSelected: selectedGame == 'archery',
        ),
        const SizedBox(width: 8.0),
        _buildCard(
          key: 'darts',
          label: 'DARTS',
          icon: Icons.gps_fixed_rounded,
          accent: dartsColor,
          isSelected: selectedGame == 'darts',
        ),
      ],
    );
  }

  Widget _buildCard({
    required String key,
    required String label,
    required IconData icon,
    required Color accent,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (enabled && !isSelected) {
            HapticFeedback.selectionClick();
            onGameSelected(key);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isSelected ? accent : const Color(0xFF1E2638),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.15),
                      blurRadius: 10.0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? accent : const Color(0xFF64748B),
                size: 20.0,
              ),
              const SizedBox(height: 5.0),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? accent : const Color(0xFF64748B),
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
