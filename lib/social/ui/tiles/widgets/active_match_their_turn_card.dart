import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/game_chip.dart';
import 'package:b_ball/social/ui/tiles/widgets/active_match_score_row.dart';

/// Card widget for active match in "THEIR TURN" state (Artboard 10 - middle card).
class ActiveMatchTheirTurnCard extends StatelessWidget {
  final CloudMatch match;
  final String effectiveUid;
  final VoidCallback onWatchLive;

  const ActiveMatchTheirTurnCard({
    super.key,
    required this.match,
    required this.effectiveUid,
    required this.onWatchLive,
  });

  @override
  Widget build(BuildContext context) {
    final myPlayer = match.myPlayer(effectiveUid);
    final oppPlayer = match.opponentPlayer(effectiveUid);
    final oppName = oppPlayer?.displayName ?? 'Opponent';

    final scoreData = computeActiveMatchScores(match, effectiveUid);
    final roundText = computeActiveMatchRoundText(match);
    final narrative = _computeLeadNarrative(oppName, scoreData);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFF1E2638),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: GameChip, Round text, THEIR TURN pill
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
                  color: const Color(0x26F59E0B),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'THEIR TURN',
                  style: UiFont.style(
                    size: 11.0,
                    weight: 900,
                    color: const Color(0xFFF59E0B),
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
          const SizedBox(height: 10.0),

          // Row 3: Narrative sentence
          Text(
            narrative,
            style: UiFont.style(
              size: 13.0,
              weight: 600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12.0),

          // Row 4: Watch live Action Button
          SizedBox(
            height: 40.0,
            child: ElevatedButton(
              onPressed: onWatchLive,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
              child: Text(
                'Watch live',
                style: UiFont.style(
                  size: 13.0,
                  weight: 800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _computeLeadNarrative(String oppName, ActiveMatchScoreResult scoreData) {
    final verb = match.isDarts
        ? 'throwing'
        : (match.isArchery ? 'shooting set' : 'shooting');

    final p1Rounds = match.player1.roundScores.length;
    final p2Rounds = match.player2?.roundScores.length ?? 0;
    final roundNumber = math.max(p1Rounds, p2Rounds) + 1;

    final String leadStr;
    if (match.isDarts) {
      final diff = scoreData.oppRaw - scoreData.myRaw; // less left is leading
      if (diff > 0) {
        leadStr = 'You lead by $diff.';
      } else if (diff < 0) {
        leadStr = '$oppName leads by ${-diff}.';
      } else {
        leadStr = 'Tied.';
      }
    } else {
      final diff = scoreData.myRaw - scoreData.oppRaw; // more is leading
      if (diff > 0) {
        leadStr = 'You lead by $diff.';
      } else if (diff < 0) {
        leadStr = '$oppName leads by ${-diff}.';
      } else {
        leadStr = 'Tied.';
      }
    }

    return '$oppName is $verb round $roundNumber now. $leadStr';
  }
}
