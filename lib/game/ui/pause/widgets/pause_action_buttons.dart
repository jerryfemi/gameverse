import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Action button block for pause menus matching Templates 21 and 22:
/// - Primary RESUME button with game accent
/// - Secondary row: [Restart / Forfeit] + [Lobby]
class PauseActionButtons extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onResume;
  final VoidCallback onLobby;
  final VoidCallback? onRestart;
  final VoidCallback? onForfeit;
  final bool isForfeiting;

  const PauseActionButtons({
    super.key,
    required this.accentColor,
    required this.onResume,
    required this.onLobby,
    this.onRestart,
    this.onForfeit,
    this.isForfeiting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary RESUME button
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onResume();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
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
              Icon(Icons.play_arrow_rounded, size: 20.0),
              SizedBox(width: 6.0),
              Text(
                'RESUME',
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

        // Secondary Row: [Restart / Forfeit] + [Lobby]
        Row(
          children: [
            if (onRestart != null)
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.replay_rounded,
                  label: 'Restart',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRestart!();
                  },
                ),
              )
            else if (onForfeit != null)
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.replay_rounded,
                  label: 'Forfeit',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onForfeit!();
                  },
                ),
              ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _buildSecondaryButton(
                icon: Icons.grid_view_rounded,
                label: 'Lobby',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onLobby();
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          height: 44.0,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2638),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFF2A364F)),
          ),
          alignment: Alignment.center,
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
    );
  }
}
