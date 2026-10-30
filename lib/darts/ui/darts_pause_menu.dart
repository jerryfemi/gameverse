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
    // A plain text link, only when it can be used (solo, on your throw).
    Widget? extra;
    final VoidCallback? tap = inPractice ? onExitPractice : onPractice;
    if (!online && tap != null) {
      extra = Center(
        child: TextButton.icon(
          onPressed: tap,
          style: TextButton.styleFrom(foregroundColor: _accent),
          icon: Icon(
            inPractice ? Icons.sports_score_rounded : Icons.gps_fixed_rounded,
            size: 18.0,
          ),
          label: Text(
            inPractice ? 'Back to match' : 'Practice mode',
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800),
          ),
        ),
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
