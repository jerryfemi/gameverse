import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Action button layout matching Design Template 20:
/// - Primary green "PLAY AGAIN" button
/// - Secondary dual row: "Replay" + "Play 1v1"
class GameOverActions extends StatelessWidget {
  final VoidCallback onPlayAgain;
  final VoidCallback? onReplay;
  final VoidCallback onPlay1v1;

  const GameOverActions({
    super.key,
    required this.onPlayAgain,
    this.onReplay,
    required this.onPlay1v1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary PLAY AGAIN button
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onPlayAgain();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: const Color(0xFF0A0E1A),
            elevation: 0,
            minimumSize: const Size.fromHeight(48.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.replay_rounded, size: 20.0),
              SizedBox(width: 6.0),
              Text(
                'PLAY AGAIN',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),

        // Secondary Row: [Replay] + [Play 1v1]
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                icon: Icons.play_arrow_rounded,
                label: 'Replay',
                enabled: onReplay != null,
                onTap: onReplay == null
                    ? () {}
                    : () {
                        HapticFeedback.selectionClick();
                        onReplay!();
                      },
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildSecondaryButton(
                icon: Icons.people_alt_rounded,
                label: 'Play 1v1',
                enabled: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPlay1v1();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          height: 44.0,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2638),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFF2A364F)),
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16.0, color: Colors.white),
                const SizedBox(width: 6.0),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
