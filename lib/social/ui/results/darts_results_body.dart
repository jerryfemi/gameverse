import 'dart:math' as math;

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';

import 'package:b_ball/darts/state/darts_rules.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/section_label.dart';
import 'package:b_ball/social/ui/results/race_to_zero_chart.dart';

/// Darts 301 match recap body presenting the Race-to-Zero trajectory
/// and 3-column head-to-head performance statistics.
class DartsResultsBody extends StatelessWidget {
  final CloudMatch match;
  final String myUid;

  const DartsResultsBody({super.key, required this.match, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final myPlayer = match.myPlayer(myUid);
    final oppPlayer = match.opponentPlayer(myUid);

    final myScores = myPlayer?.roundScores ?? const <int>[];
    final oppScores = oppPlayer?.roundScores ?? const <int>[];

    // Compute stats
    final myRemaining = DartsRules.remaining(myScores);
    final oppRemaining = DartsRules.remaining(oppScores);

    final myScored = 301 - myRemaining;
    final oppScored = 301 - oppRemaining;

    final myRounds = math.max(1, myScores.length);
    final oppRounds = math.max(1, oppScores.length);

    final myAvg = myScores.isNotEmpty
        ? (myScored / myRounds).toStringAsFixed(1)
        : '—';
    final oppAvg = oppScores.isNotEmpty
        ? (oppScored / oppRounds).toStringAsFixed(1)
        : '—';

    final myBest = myScores.isNotEmpty ? '${myScores.reduce(math.max)}' : '—';
    final oppBest = oppScores.isNotEmpty
        ? '${oppScores.reduce(math.max)}'
        : '—';

    // Darts thrown
    final myDartsCount = myPlayer?.totalAttemptedShots ?? 0;
    final oppDartsCount = oppPlayer?.totalAttemptedShots ?? 0;
    final myDartsStr = myDartsCount > 0
        ? '$myDartsCount'
        : '${myScores.length * 3}';
    final oppDartsStr = oppDartsCount > 0
        ? '$oppDartsCount'
        : '${oppScores.length * 3}';

    // Busts (0-point turns)
    final myBusts = myScores.where((s) => s == 0).length;
    final oppBusts = oppScores.where((s) => s == 0).length;

    // Checkout
    final myCheckedOut = myRemaining == 0;
    final oppCheckedOut = oppRemaining == 0;
    final myCheckoutStr = myCheckedOut && myScores.isNotEmpty
        ? '${myScores.last}'
        : '—';
    final oppCheckoutStr = oppCheckedOut && oppScores.isNotEmpty
        ? '${oppScores.last}'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RaceToZeroChart(
          p1RoundScores: myScores,
          p2RoundScores: oppScores,
          p1Name: myPlayer?.displayName ?? 'You',
          p2Name: oppPlayer?.displayName ?? 'Opponent',
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
                label: '3-dart avg',
                val1: myAvg,
                val2: oppAvg,
                betterIsHigher: true,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Best turn',
                val1: myBest,
                val2: oppBest,
                betterIsHigher: true,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Checkout',
                val1: myCheckoutStr,
                val2: oppCheckoutStr,
                isCheckout: true,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Darts thrown',
                val1: myDartsStr,
                val2: oppDartsStr,
                betterIsHigher: false,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Busts',
                val1: '$myBusts',
                val2: '$oppBusts',
                betterIsHigher: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required String label,
    required String val1,
    required String val2,
    bool? betterIsHigher,
    bool isCheckout = false,
  }) {
    bool? isVal1Better;
    if (isCheckout) {
      if (val1 != '—' && val2 == '—') isVal1Better = true;
      if (val1 == '—' && val2 != '—') isVal1Better = false;
    } else if (betterIsHigher != null) {
      final n1 = double.tryParse(val1);
      final n2 = double.tryParse(val2);
      if (n1 != null && n2 != null && n1 != n2) {
        isVal1Better = betterIsHigher ? n1 > n2 : n1 < n2;
      }
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
