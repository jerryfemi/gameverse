import 'package:flutter/material.dart';

import 'package:b_ball/game/match/match_session.dart';
import 'package:b_ball/game/ui/common/app_avatar.dart';

/// Head-to-Head avatar comparison row matching Design Templates 15, 18, and 19:
/// - Avatars with winner gold crowns
/// - Gamer tags with player theme colors
/// - Giant score numerals and "POINTS" subtext
class PodiumAvatarsRow extends StatelessWidget {
  final MatchSession session;
  final bool isP1Winner;
  final bool isTie;

  const PodiumAvatarsRow({
    super.key,
    required this.session,
    required this.isP1Winner,
    required this.isTie,
  });

  @override
  Widget build(BuildContext context) {
    final p1 = session.player1;
    final p2 = session.player2;
    final p2Winner = !isTie && !isP1Winner;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPlayerColumn(
          name: session.displayNameFor(p1),
          avatar: p1.avatar,
          score: p1.totalScore,
          accentColor: const Color(0xFF38BDF8),
          isWinner: isP1Winner && !isTie,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'VS',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
        _buildPlayerColumn(
          name: p2.name,
          avatar: p2.avatar,
          score: p2.totalScore,
          accentColor: const Color(0xFFF59E0B),
          isWinner: p2Winner,
        ),
      ],
    );
  }

  Widget _buildPlayerColumn({
    required String name,
    required String avatar,
    required int score,
    required Color accentColor,
    required bool isWinner,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isWinner ? const Color(0xFFF59E0B) : const Color(0xFF1E2638),
                  width: isWinner ? 2.2 : 1.2,
                ),
                boxShadow: isWinner
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 14.0,
                        ),
                      ]
                    : null,
              ),
              child: AppAvatar(avatar: avatar, size: 52.0),
            ),
            if (isWinner)
              const Positioned(
                top: -12.0,
                child: Text('👑', style: TextStyle(fontSize: 16.0)),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        Text(
          name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accentColor,
            fontSize: 12.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32.0,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2.0),
        const Text(
          'POINTS',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
