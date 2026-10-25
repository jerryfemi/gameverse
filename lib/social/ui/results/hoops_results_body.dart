import 'dart:math' as math;

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/section_label.dart';

/// Hoops / Basketball match recap body displaying round-by-round point breakdown
/// and shooting analytics (accuracy, swishes, streaks).
class HoopsResultsBody extends StatelessWidget {
  final CloudMatch match;
  final String myUid;

  const HoopsResultsBody({super.key, required this.match, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final myPlayer = match.myPlayer(myUid);
    final oppPlayer = match.opponentPlayer(myUid);

    final myScores = myPlayer?.roundScores ?? const <int>[];
    final oppScores = oppPlayer?.roundScores ?? const <int>[];

    final int roundCount = math.max(myScores.length, oppScores.length);

    // Compute shooting stats
    final myMade = myPlayer?.totalMadeShots ?? 0;
    final myTotalShots = myPlayer?.totalAttemptedShots ?? 0;
    final oppMade = oppPlayer?.totalMadeShots ?? 0;
    final oppTotalShots = oppPlayer?.totalAttemptedShots ?? 0;

    final myAcc = myTotalShots > 0
        ? '${((myMade / myTotalShots) * 100).round()}%'
        : '—';
    final oppAcc = oppTotalShots > 0
        ? '${((oppMade / oppTotalShots) * 100).round()}%'
        : '—';

    final mySwishes =
        myPlayer?.roundSummaries.fold(0, (sum, r) => sum + r.swishes) ?? 0;
    final oppSwishes =
        oppPlayer?.roundSummaries.fold(0, (sum, r) => sum + r.swishes) ?? 0;

    final myBestStreak =
        myPlayer?.roundSummaries.fold(0, (m, r) => math.max(m, r.bestStreak)) ??
        0;
    final oppBestStreak =
        oppPlayer?.roundSummaries.fold(
          0,
          (m, r) => math.max(m, r.bestStreak),
        ) ??
        0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(text: 'ROUND BY ROUND'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          ),
          child: Column(
            children: [
              for (int r = 0; r < roundCount; r++) ...[
                if (r > 0) const Divider(color: Color(0xFF1E2638), height: 18),
                _buildRoundRow(
                  label: 'ROUND ${r + 1}',
                  val1: r < myScores.length ? '${myScores[r]}' : '—',
                  val2: r < oppScores.length ? '${oppScores[r]}' : '—',
                ),
              ],
              const Divider(
                color: Color(0xFF334155),
                height: 22,
                thickness: 1.0,
              ),
              _buildRoundRow(
                label: 'TOTAL',
                val1: '${myPlayer?.totalScore ?? 0}',
                val2: '${oppPlayer?.totalScore ?? 0}',
                isTotal: true,
              ),
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
                label: 'Shots made',
                val1: myTotalShots > 0 ? '$myMade/$myTotalShots' : '—',
                val2: oppTotalShots > 0 ? '$oppMade/$oppTotalShots' : '—',
                numeric1: myMade,
                numeric2: oppMade,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Accuracy',
                val1: myAcc,
                val2: oppAcc,
                numeric1: myTotalShots > 0 ? (myMade / myTotalShots) : null,
                numeric2: oppTotalShots > 0 ? (oppMade / oppTotalShots) : null,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Swishes',
                val1: '$mySwishes',
                val2: '$oppSwishes',
                numeric1: mySwishes,
                numeric2: oppSwishes,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Best streak',
                val1: '$myBestStreak',
                val2: '$oppBestStreak',
                numeric1: myBestStreak,
                numeric2: oppBestStreak,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundRow({
    required String label,
    required String val1,
    required String val2,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72.0,
          child: Text(
            val1,
            textAlign: TextAlign.start,
            style: UiFont.style(
              size: isTotal ? 19.0 : 16.0,
              weight: isTotal ? 900 : 800,
              color: const Color(0xFF38BDF8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: UiFont.style(
              size: isTotal ? 12.0 : 11.0,
              weight: 800,
              color: isTotal ? Colors.white : const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(
          width: 72.0,
          child: Text(
            val2,
            textAlign: TextAlign.end,
            style: UiFont.style(
              size: isTotal ? 19.0 : 16.0,
              weight: isTotal ? 900 : 800,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
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
