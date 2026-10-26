import 'package:flutter/material.dart';

import 'package:b_ball/archery/ui/archery_pause_menu.dart';

/// Darts pause menu matching Design Templates 21 and 22:
/// Uses Sky Blue accent, Pub Ambience, and 301 match metrics.
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
  });

  @override
  Widget build(BuildContext context) {
    return ArcheryPauseMenu(
      online: online,
      onResume: onResume,
      onLobby: onLobby,
      onRestart: online ? null : onRestart,
      onForfeit: online ? onForfeit : null,
      onHowToPlay: onHowToPlay,
      subtitle: subtitle,
      stat1Label: stat1Label,
      stat1Value: stat1Value,
      stat2Label: stat2Label,
      stat2Value: stat2Value,
      stat2Color: const Color(0xFF38BDF8),
      stat3Label: stat3Label,
      stat3Value: stat3Value,
      stat3Color: const Color(0xFFF59E0B),
      accentColor: const Color(0xFF38BDF8),
      trackName: 'Pub Ambience',
    );
  }
}
