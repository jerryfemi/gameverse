import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/pause/widgets/pause_action_buttons.dart';
import 'package:b_ball/game/ui/pause/widgets/pause_sound_card.dart';
import 'package:b_ball/game/ui/pause/widgets/pause_stat_chip.dart';

/// Archery Pause Menu matching Design Template 22:
/// - "Paused" header with round and mode subtitle
/// - 3 stat chips: SET POINTS, THIS SET, ARROWS
/// - SOUND section with volume sliders and track name
/// - RESUME button + Restart/Forfeit & Lobby buttons
/// - FittedBox responsive scaling (< 220 lines)
class ArcheryPauseMenu extends StatelessWidget {
  final bool online;
  final VoidCallback onResume;
  final VoidCallback? onRestart;
  final VoidCallback onLobby;
  final VoidCallback? onForfeit;
  final VoidCallback? onHowToPlay;
  final String? subtitle;
  final String? stat1Label;
  final String? stat1Value;
  final String? stat2Label;
  final String? stat2Value;
  final Color stat2Color;
  final String? stat3Label;
  final String? stat3Value;
  final Color stat3Color;
  final Color accentColor;
  final String? trackName;
  final VoidCallback? onCycleTrack;
  final String? credit;

  /// Optional extra button shown above the main actions (e.g. darts Practice).
  final Widget? extraAction;

  const ArcheryPauseMenu({
    super.key,
    required this.online,
    required this.onResume,
    required this.onLobby,
    this.onRestart,
    this.onForfeit,
    this.onHowToPlay,
    this.subtitle,
    this.stat1Label,
    this.stat1Value,
    this.stat2Label,
    this.stat2Value,
    this.stat2Color = const Color(0xFF00FFCC),
    this.stat3Label,
    this.stat3Value,
    this.stat3Color = const Color(0xFFF59E0B),
    this.accentColor = const Color(0xFF00FFCC),
    this.trackName = 'Forest',
    this.onCycleTrack,
    this.credit,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.90;

    return Stack(
      children: [
        // Tap outside = resume
        Positioned.fill(
          child: GestureDetector(
            onTap: onResume,
            child: const ColoredBox(color: Color(0xCC000000)),
          ),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 360.0, maxHeight: maxH),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1424),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0xCC000000), blurRadius: 36.0, offset: Offset(0, 14)),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title & Subtitle
                      const Text(
                        'Paused',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle ?? (online ? 'Live 1v1 match' : 'Solo match'),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // 3 Stat Chips
                      if (stat1Label != null && stat2Label != null && stat3Label != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PauseStatChip(
                                label: stat1Label!,
                                value: stat1Value ?? '0',
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: PauseStatChip(
                                label: stat2Label!,
                                value: stat2Value ?? '0',
                                valueColor: stat2Color,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: PauseStatChip(
                                label: stat3Label!,
                                value: stat3Value ?? '0',
                                valueColor: stat3Color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // SOUND Section Header
                      const Text(
                        'SOUND',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6.0),

                      // Sound Card
                      PauseSoundCard(
                        accentColor: accentColor,
                        trackName: trackName,
                        onCycleTrack: onCycleTrack,
                      ),
                      const SizedBox(height: 20.0),

                      if (extraAction != null) ...[
                        extraAction!,
                        const SizedBox(height: 10.0),
                      ],

                      // Action Buttons: Resume / (Restart or Forfeit) / Lobby
                      PauseActionButtons(
                        accentColor: accentColor,
                        onResume: onResume,
                        onLobby: onLobby,
                        onRestart: online ? null : onRestart,
                        onForfeit: online ? onForfeit : null,
                      ),

                      if (credit != null) ...[
                        const SizedBox(height: 12.0),
                        Text(
                          credit!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
