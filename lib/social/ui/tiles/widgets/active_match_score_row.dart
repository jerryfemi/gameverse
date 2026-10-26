import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:b_ball/archery/state/archery_rules.dart';
import 'package:b_ball/darts/state/darts_rules.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/crown_avatar.dart';

/// Computed score metrics for active match cards.
class ActiveMatchScoreResult {
  final String myValue;
  final String myUnit;
  final String oppValue;
  final String oppUnit;
  final int myRaw;
  final int oppRaw;

  const ActiveMatchScoreResult({
    required this.myValue,
    required this.myUnit,
    required this.oppValue,
    required this.oppUnit,
    required this.myRaw,
    required this.oppRaw,
  });
}

/// Computes current match score values for active match card displays.
ActiveMatchScoreResult computeActiveMatchScores(
  CloudMatch match,
  String effectiveUid,
) {
  final myPlayer = match.myPlayer(effectiveUid);
  final oppPlayer = match.opponentPlayer(effectiveUid);

  if (match.isDarts) {
    final myRemaining =
        DartsRules.remaining(myPlayer?.roundScores ?? const []);
    final oppRemaining =
        DartsRules.remaining(oppPlayer?.roundScores ?? const []);
    return ActiveMatchScoreResult(
      myValue: '$myRemaining',
      myUnit: 'left',
      oppValue: '$oppRemaining',
      oppUnit: 'left',
      myRaw: myRemaining,
      oppRaw: oppRemaining,
    );
  } else if (match.isArchery) {
    final isP1Me = match.player1.uid == effectiveUid;
    final sp = ArcheryRules.setPoints(
      match.player1.roundScores,
      match.player2?.roundScores ?? const [],
    );
    final mySets = isP1Me ? sp.you : sp.them;
    final oppSets = isP1Me ? sp.them : sp.you;
    return ActiveMatchScoreResult(
      myValue: '$mySets',
      myUnit: 'sets',
      oppValue: '$oppSets',
      oppUnit: 'sets',
      myRaw: mySets,
      oppRaw: oppSets,
    );
  } else {
    final myScore = myPlayer?.totalScore ?? 0;
    final oppScore = oppPlayer?.totalScore ?? 0;
    return ActiveMatchScoreResult(
      myValue: '$myScore',
      myUnit: 'pts',
      oppValue: '$oppScore',
      oppUnit: 'pts',
      myRaw: myScore,
      oppRaw: oppScore,
    );
  }
}

/// Computes current round label (e.g. "Round 2 of 5").
String computeActiveMatchRoundText(CloudMatch match) {
  final p1Rounds = match.player1.roundScores.length;
  final p2Rounds = match.player2?.roundScores.length ?? 0;
  final currentRound = math.max(p1Rounds, p2Rounds) + 1;
  final totalRounds = match.totalRounds > 0
      ? match.totalRounds
      : (match.isDarts ? 20 : (match.isArchery ? 5 : 2));

  final effectiveRound = math.min(currentRound, totalRounds);
  return 'Round $effectiveRound of $totalRounds';
}

/// Score and avatar comparison row used in active match tiles.
class ActiveMatchScoreRow extends StatelessWidget {
  final String myAvatar;
  final String oppAvatar;
  final String oppName;
  final ActiveMatchScoreResult scoreData;

  const ActiveMatchScoreRow({
    super.key,
    required this.myAvatar,
    required this.oppAvatar,
    required this.oppName,
    required this.scoreData,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CrownAvatar(avatar: myAvatar, size: 40.0),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOU',
                style: UiFont.style(
                  size: 11.0,
                  weight: 800,
                  color: const Color(0xFF38BDF8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      scoreData.myValue,
                      style: UiFont.style(
                        size: 20.0,
                        weight: 900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    scoreData.myUnit,
                    style: UiFont.style(
                      size: 12.0,
                      weight: 600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            'VS',
            style: UiFont.style(
              size: 11.0,
              weight: 800,
              color: const Color(0xFF475569),
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                oppName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiFont.style(
                  size: 11.0,
                  weight: 800,
                  color: const Color(0xFFF59E0B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    scoreData.oppUnit,
                    style: UiFont.style(
                      size: 12.0,
                      weight: 600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      scoreData.oppValue,
                      style: UiFont.style(
                        size: 20.0,
                        weight: 900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10.0),
        CrownAvatar(avatar: oppAvatar, size: 40.0),
      ],
    );
  }
}
