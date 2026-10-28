import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/game_chip.dart';
import 'package:b_ball/social/ui/tiles/widgets/active_match_score_row.dart';

/// Card widget for active match in "YOUR TURN" state (Artboard 10 - top card).
class ActiveMatchYourTurnCard extends StatelessWidget {
  final CloudMatch match;
  final String effectiveUid;
  final VoidCallback onPlay;
  final VoidCallback? onLeave;

  const ActiveMatchYourTurnCard({
    super.key,
    required this.match,
    required this.effectiveUid,
    required this.onPlay,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final myPlayer = match.myPlayer(effectiveUid);
    final oppPlayer = match.opponentPlayer(effectiveUid);
    final oppName = oppPlayer?.displayName ?? 'Opponent';

    final scoreData = computeActiveMatchScores(match, effectiveUid);
    final roundText = computeActiveMatchRoundText(match);

    // Paintball is live, not turn-based: rejoin the duel instead.
    final ctaVerb = match.isPaintball
        ? 'REJOIN DUEL'
        : match.isDarts
            ? 'THROW YOUR TURN'
            : (match.isArchery ? 'SHOOT YOUR SET' : 'SHOOT YOUR TURN');
    final ctaIcon = match.isPaintball
        ? Icons.sports_esports_rounded
        : match.isDarts
            ? Icons.adjust_rounded
            : (match.isArchery
                ? Icons.arrow_outward_rounded
                : Icons.sports_basketball_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A1F),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFF00FFCC),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2900FFCC),
            blurRadius: 12.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: GameChip, Round text, YOUR TURN pill
          Row(
            children: [
              GameChip.fromMatch(match),
              const SizedBox(width: 10.0),
              Text(
                roundText,
                style: UiFont.style(
                  size: 12.0,
                  weight: 600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFCC),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  match.isPaintball ? 'LIVE 1V1' : 'YOUR TURN',
                  style: UiFont.style(
                    size: 11.0,
                    weight: 900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Row 2: Scores and Avatars
          ActiveMatchScoreRow(
            myAvatar: myPlayer?.avatarEmoji ?? '👤',
            oppAvatar: oppPlayer?.avatarEmoji ?? '⏳',
            oppName: oppName,
            scoreData: scoreData,
          ),
          const SizedBox(height: 14.0),

          // Row 3: Action Button (Primary CTA)
          Row(children: [
          Expanded(child: SizedBox(
            height: 44.0,
            child: ElevatedButton.icon(
              onPressed: onPlay,
              icon: Icon(ctaIcon, size: 16.0),
              label: Text(
                ctaVerb,
                style: UiFont.style(
                  size: 13.0,
                  weight: 900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.6,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFCC),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
            ),
          )),
          activeMatchLeaveButton(onLeave),
          ]),
        ],
      ),
    );
  }
}

/// Secondary "Leave" next to the main action: ends the match for both
/// (a forfeit once it has started).
Widget activeMatchLeaveButton(VoidCallback? onLeave, {double height = 44.0}) {
  if (onLeave == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(left: 8.0),
    child: SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onLeave,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF87171),
          side: const BorderSide(color: Color(0x66EF4444)),
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        child: Text('Leave', style: UiFont.style(size: 13.0, weight: 800, color: const Color(0xFFF87171))),
      ),
    ),
  );
}

