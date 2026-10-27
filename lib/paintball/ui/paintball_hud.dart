import 'package:flutter/material.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';

/// Top HUD overlay showing player health pips, round clock, and opponent status.
///
/// Follows Paintball Plan §8 & docs/images/paintball-prospect.png.
class PaintballHudOverlay extends StatelessWidget {
  final PaintballMatchState match;

  const PaintballHudOverlay({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Player Pill (YOU + 3 blue pips)
            _buildPlayerPill(
              label: 'YOU',
              hitsTaken: match.you.hitsTaken,
              pipColor: const Color(0xFF38BDF8),
              avatarBg: const Color(0xFF0284C7),
            ),

            // Center: Timer or Countdown
            _buildCenterTimer(),

            // Right: Opponent Pill (3 orange pips + BOT)
            _buildPlayerPill(
              label: 'BOT',
              hitsTaken: match.opponent.hitsTaken,
              pipColor: const Color(0xFFF59E0B),
              avatarBg: const Color(0xFFD97706),
              isReversed: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterTimer() {
    String text;
    Color color = Colors.white;

    switch (match.phase) {
      case PaintballMatchPhase.countdown:
        final count = match.countdownRemaining.ceil();
        text = count > 0 ? '$count' : 'GO!';
        color = const Color(0xFFFACC15);
      case PaintballMatchPhase.live:
        final secs = match.timeRemaining.ceil();
        final m = secs ~/ 60;
        final s = secs % 60;
        text = '$m:${s.toString().padLeft(2, '0')}';
        if (secs <= 10) color = const Color(0xFFEF4444);
      case PaintballMatchPhase.suddenDeath:
        text = 'SUDDEN DEATH';
        color = const Color(0xFFEF4444);
      case PaintballMatchPhase.gameOver:
        text = match.winner == PaintballWinner.you ? 'VICTORY!' : 'DEFEAT';
        color = match.winner == PaintballWinner.you
            ? const Color(0xFF00FFCC)
            : const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x990A0E1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildPlayerPill({
    required String label,
    required int hitsTaken,
    required Color pipColor,
    required Color avatarBg,
    bool isReversed = false,
  }) {
    final remainingPips = (PaintballK.hitsToWin - hitsTaken).clamp(0, PaintballK.hitsToWin);

    final pips = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(PaintballK.hitsToWin, (index) {
        final isFilled = index < remainingPips;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? pipColor : const Color(0xFF334155),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: pipColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        );
      }),
    );

    final avatar = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: avatarBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          fontFamily: 'Inter',
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xCC0A0E1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isReversed
            ? [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: pips),
                avatar,
              ]
            : [
                avatar,
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: pips),
              ],
      ),
    );
  }
}
