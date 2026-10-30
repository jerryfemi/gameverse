import 'package:flutter/material.dart';

import 'package:b_ball/archery/ui/archery_pause_menu.dart';

/// Darts pause menu matching Design Templates 21 and 22:
/// Uses Sky Blue accent, Pub Ambience, and 301 match metrics.
///
/// Solo play also offers free-throw Practice: [onPractice] starts it (null =
/// shown disabled, e.g. during the bot's turn) and [inPractice] swaps the
/// button for "Back to match" via [onExitPractice].
class DartsPauseMenu extends StatelessWidget {
  final bool online;
  final VoidCallback onResume;
  final VoidCallback onHowToPlay;
  final VoidCallback? onRestart;
  final VoidCallback onLobby;
  final VoidCallback? onForfeit;
  final String? subtitle;
  final String? stat1Label;
  final String? stat1Value;
  final String? stat2Label;
  final String? stat2Value;
  final String? stat3Label;
  final String? stat3Value;
  final bool inPractice;
  final VoidCallback? onPractice;
  final VoidCallback? onExitPractice;

  const DartsPauseMenu({
    super.key,
    required this.online,
    required this.onResume,
    required this.onHowToPlay,
    required this.onLobby,
    this.onRestart,
    this.onForfeit,
    this.subtitle,
    this.stat1Label,
    this.stat1Value,
    this.stat2Label,
    this.stat2Value,
    this.stat3Label,
    this.stat3Value,
    this.inPractice = false,
    this.onPractice,
    this.onExitPractice,
  });

  static const Color _accent = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    Widget? extra;
    if (!online) {
      extra = inPractice
          ? _PracticeButton(
              icon: Icons.sports_score_rounded,
              label: 'BACK TO MATCH',
              hint: 'Your match continues where you left it',
              onTap: onExitPractice,
            )
          : _PracticeButton(
              icon: Icons.gps_fixed_rounded,
              label: 'PRACTICE THROWS',
              hint: onPractice == null
                  ? 'Available on your turn'
                  : 'Free throws, unlimited darts. Your match waits.',
              onTap: onPractice,
            );
    }

    return ArcheryPauseMenu(
      online: online,
      onResume: onResume,
      onLobby: onLobby,
      onRestart: online || inPractice ? null : onRestart,
      onForfeit: online ? onForfeit : null,
      onHowToPlay: onHowToPlay,
      subtitle: subtitle,
      stat1Label: stat1Label,
      stat1Value: stat1Value,
      stat2Label: stat2Label,
      stat2Value: stat2Value,
      stat2Color: _accent,
      stat3Label: stat3Label,
      stat3Value: stat3Value,
      stat3Color: const Color(0xFFF59E0B),
      accentColor: _accent,
      trackName: 'Pub Ambience',
      extraAction: extra,
    );
  }
}

class _PracticeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onTap;

  const _PracticeButton({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Material(
        color: const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(14.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0x5938BDF8)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20.0, color: const Color(0xFF38BDF8)),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        hint,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
