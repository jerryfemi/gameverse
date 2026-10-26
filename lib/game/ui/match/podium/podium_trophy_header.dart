import 'package:flutter/material.dart';

import 'package:b_ball/game/match/match_session.dart';

/// Top section of the Winner Podium matching Design Templates 15, 18, and 19:
/// - Floating circular trophy badge with neon accent glow
/// - Glowing "YOU WIN" / "YOU LOSE" / "MATCH TIED" headline
/// - Dynamic subtitle (forfeit reason, score margin, or set count)
class PodiumTrophyHeader extends StatelessWidget {
  final MatchSession session;
  final Color bannerColor;
  final String winnerDeclaration;
  final bool isTie;
  final VoidCallback onClose;

  const PodiumTrophyHeader({
    super.key,
    required this.session,
    required this.bannerColor,
    required this.winnerDeclaration,
    required this.isTie,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final winner = session.overallWinner;
    final isP1Winner = winner == session.player1;

    String subtitle() {
      if (session.isForfeit) {
        final oppName = session.player2.name;
        return isP1Winner
            ? '$oppName left the match · you win by forfeit'
            : 'You left the match · $oppName wins by forfeit';
      }
      if (isTie) {
        return 'Tied score over ${session.totalRounds} rounds';
      }
      final margin = (session.player1.totalScore - session.player2.totalScore).abs();
      return isP1Winner
          ? 'You won by $margin points over ${session.totalRounds} rounds'
          : '${session.player2.name} won by $margin points';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Trophy Circle Badge
        Center(
          child: Container(
            width: 54.0,
            height: 54.0,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1424),
              shape: BoxShape.circle,
              border: Border.all(color: bannerColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: bannerColor.withValues(alpha: 0.35),
                  blurRadius: 16.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isTie ? Icons.handshake_rounded : Icons.emoji_events_rounded,
                size: 26.0,
                color: bannerColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        // Headline: YOU WIN
        Text(
          winnerDeclaration,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: bannerColor,
            fontSize: 26.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: bannerColor.withValues(alpha: 0.4),
                blurRadius: 14.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 3.0),

        // Subtitle
        Text(
          subtitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
