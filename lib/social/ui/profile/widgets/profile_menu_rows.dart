import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/ui/game_rules_dialog.dart';

/// Grouped list rows in [ProfileSheet] for Matches, How to play, and Sound settings.
class ProfileMenuRows extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final VoidCallback onOpenMatches;
  final VoidCallback? onHowToPlay;
  final VoidCallback onOpenSound;

  const ProfileMenuRows({
    super.key,
    required this.activeCount,
    required this.completedCount,
    required this.onOpenMatches,
    this.onHowToPlay,
    required this.onOpenSound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
      ),
      child: Column(
        children: [
          // Matches row
          _buildRowItem(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFF00FFCC),
            iconBg: const Color(0xFF0D3B36),
            title: 'Matches',
            subtitle: '$activeCount active · $completedCount completed',
            onTap: onOpenMatches,
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),

          // How to play row
          _buildRowItem(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF38BDF8),
            iconBg: const Color(0xFF0C2E42),
            title: 'How to play',
            subtitle: 'Hoops, Archery, Darts',
            onTap: () {
              if (onHowToPlay != null) {
                onHowToPlay!();
              } else {
                showGameRulesDialog(context);
              }
            },
          ),
          const Divider(color: Color(0xFF1E2638), height: 1.0),

          // Sound row
          _buildRowItem(
            icon: Icons.volume_up_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFF382408),
            title: 'Sound',
            subtitle: 'Music, effects, ambience',
            onTap: onOpenSound,
          ),
        ],
      ),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, color: iconColor, size: 20.0),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: UiFont.style(
                        size: 15.0,
                        weight: 800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: UiFont.style(
                        size: 12.0,
                        weight: 500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
                size: 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
