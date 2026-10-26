import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Action buttons for the match podium matching Design Templates 15, 18, and 19:
/// - Primary REMATCH button with game accent
/// - Secondary BACK TO SOLO / CLOSE ROOM button with animated countdown bar
class PodiumActionButtons extends StatelessWidget {
  final Color accentColor;
  final bool isRematching;
  final VoidCallback onRematch;
  final VoidCallback onClose;
  final int? countdownSeconds;
  final int totalCountdown;

  const PodiumActionButtons({
    super.key,
    required this.accentColor,
    required this.isRematching,
    required this.onRematch,
    required this.onClose,
    this.countdownSeconds,
    this.totalCountdown = 45,
  });

  @override
  Widget build(BuildContext context) {
    final hasCountdown = countdownSeconds != null && countdownSeconds! > 0;
    final double progress = hasCountdown
        ? (countdownSeconds! / totalCountdown).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary REMATCH button
        ElevatedButton(
          onPressed: isRematching
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onRematch();
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
          child: isRematching
              ? const SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF0A0E1A),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.replay_rounded, size: 20.0),
                    SizedBox(width: 6.0),
                    Text(
                      'REMATCH',
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

        // Secondary Button: BACK TO SOLO · 43s or CLOSE ROOM
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onClose();
            },
            borderRadius: BorderRadius.circular(14.0),
            child: Container(
              height: 44.0,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2638),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFF2A364F)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Stack(
                  children: [
                    if (hasCountdown)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        top: 0,
                        right: MediaQuery.sizeOf(context).width * (1.0 - progress),
                        child: Container(
                          color: const Color(0xFF334155).withValues(alpha: 0.4),
                        ),
                      ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasCountdown ? Icons.person_rounded : Icons.close_rounded,
                            size: 16.0,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            hasCountdown
                                ? 'BACK TO SOLO · ${countdownSeconds}s'
                                : 'CLOSE ROOM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
