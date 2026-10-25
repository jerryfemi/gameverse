import 'dart:math' as math;

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';

import 'package:b_ball/archery/state/archery_rules.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/section_label.dart';

/// Archery match recap body presenting set-by-set outcomes (+2 / +1 / +0 set points)
/// and archery shooting statistics (Xs, arrow averages, best sets).
class ArcheryResultsBody extends StatelessWidget {
  final CloudMatch match;
  final String myUid;

  const ArcheryResultsBody({
    super.key,
    required this.match,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final myPlayer = match.myPlayer(myUid);
    final oppPlayer = match.opponentPlayer(myUid);

    final isP1Me = match.player1.uid == myUid;
    final p1Scores = match.player1.roundScores;
    final p2Scores = match.player2?.roundScores ?? const <int>[];

    final myScores = isP1Me ? p1Scores : p2Scores;
    final oppScores = isP1Me ? p2Scores : p1Scores;

    final int setCount = math.max(myScores.length, oppScores.length);

    // Compute stats
    final myBest = myScores.isNotEmpty ? myScores.reduce(math.max) : 0;
    final oppBest = oppScores.isNotEmpty ? oppScores.reduce(math.max) : 0;

    final myTotalPoints = myScores.fold(0, (sum, s) => sum + s);
    final oppTotalPoints = oppScores.fold(0, (sum, s) => sum + s);

    // Total arrows = sets * 3 (or from summaries)
    final myArrows = myScores.length * ArcheryRules.arrowsPerSet;
    final oppArrows = oppScores.length * ArcheryRules.arrowsPerSet;

    final myArrowAvg = myArrows > 0
        ? (myTotalPoints / myArrows).toStringAsFixed(1)
        : '—';
    final oppArrowAvg = oppArrows > 0
        ? (oppTotalPoints / oppArrows).toStringAsFixed(1)
        : '—';

    // Xs from summaries if available
    final myXs =
        myPlayer?.roundSummaries.fold(0, (sum, r) => sum + r.swishes) ?? 0;
    final oppXs =
        oppPlayer?.roundSummaries.fold(0, (sum, r) => sum + r.swishes) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(text: 'SET BY SET'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          ),
          child: Column(
            children: [
              for (int i = 0; i < setCount; i++) ...[
                if (i > 0) const Divider(color: Color(0xFF1E2638), height: 18),
                _buildSetRow(
                  setIndex: i + 1,
                  mySetScore: i < myScores.length ? myScores[i] : null,
                  oppSetScore: i < oppScores.length ? oppScores[i] : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        const SectionLabel(text: 'MATCH STATS'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          ),
          child: Column(
            children: [
              _buildStatRow(
                label: "X's",
                val1: myXs > 0 ? '$myXs' : '—',
                val2: oppXs > 0 ? '$oppXs' : '—',
                numeric1: myXs,
                numeric2: oppXs,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Arrow avg',
                val1: myArrowAvg,
                val2: oppArrowAvg,
                numeric1: double.tryParse(myArrowAvg),
                numeric2: double.tryParse(oppArrowAvg),
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Best set',
                val1: myBest > 0 ? '$myBest' : '—',
                val2: oppBest > 0 ? '$oppBest' : '—',
                numeric1: myBest,
                numeric2: oppBest,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetRow({
    required int setIndex,
    required int? mySetScore,
    required int? oppSetScore,
  }) {
    int myPts = 0;
    int oppPts = 0;
    if (mySetScore != null && oppSetScore != null) {
      if (mySetScore > oppSetScore) {
        myPts = 2;
      } else if (mySetScore < oppSetScore) {
        oppPts = 2;
      } else {
        myPts = 1;
        oppPts = 1;
      }
    }

    return Row(
      children: [
        // Left: You
        Expanded(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mySetScore != null ? '$mySetScore' : '—',
                    style: UiFont.style(
                      size: 16.0,
                      weight: 800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildPointsBadge(myPts, isYou: true),
            ],
          ),
        ),

        // Center: Label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'SET $setIndex',
            style: UiFont.style(
              size: 11.0,
              weight: 800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Right: Opponent
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildPointsBadge(oppPts, isYou: false),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    oppSetScore != null ? '$oppSetScore' : '—',
                    style: UiFont.style(
                      size: 16.0,
                      weight: 800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsBadge(int points, {required bool isYou}) {
    final color = points > 0
        ? (isYou ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B))
        : const Color(0xFF1E2638);
    final textColor = points > 0 ? Colors.black : const Color(0xFF64748B);

    return Container(
      width: 28.0,
      height: 24.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        '+$points',
        style: UiFont.style(size: 11.5, weight: 900, color: textColor),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String val1,
    required String val2,
    num? numeric1,
    num? numeric2,
  }) {
    bool? isVal1Better;
    if (numeric1 != null && numeric2 != null && numeric1 != numeric2) {
      isVal1Better = numeric1 > numeric2;
    }

    final val1Color = isVal1Better == true
        ? Colors.white
        : (isVal1Better == false ? const Color(0xFF64748B) : Colors.white);
    final val2Color = isVal1Better == false
        ? Colors.white
        : (isVal1Better == true ? const Color(0xFF64748B) : Colors.white);

    final val1Weight = isVal1Better == true ? 900.0 : 600.0;
    final val2Weight = isVal1Better == false ? 900.0 : 600.0;

    return Row(
      children: [
        SizedBox(
          width: 72.0,
          child: Text(
            val1,
            textAlign: TextAlign.start,
            style: UiFont.style(
              size: 17.0,
              weight: val1Weight,
              color: val1Color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: UiFont.style(
              size: 12.0,
              weight: 600,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        SizedBox(
          width: 72.0,
          child: Text(
            val2,
            textAlign: TextAlign.end,
            style: UiFont.style(
              size: 17.0,
              weight: val2Weight,
              color: val2Color,
            ),
          ),
        ),
      ],
    );
  }
}
