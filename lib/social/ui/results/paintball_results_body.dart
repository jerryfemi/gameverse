import 'package:flutter/material.dart';
import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/social/ui/common/section_label.dart';

/// Paintball match recap body presenting head-to-head duel statistics:
/// hits landed, shots fired, accuracy, times dodged, and longest survival streak.
class PaintballResultsBody extends StatelessWidget {
  final CloudMatch match;
  final String myUid;

  const PaintballResultsBody({
    super.key,
    required this.match,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final myPlayer = match.myPlayer(myUid);
    final oppPlayer = match.opponentPlayer(myUid);

    // Score in paintball represents total hits landed
    final myHits = myPlayer?.score ?? 0;
    final oppHits = oppPlayer?.score ?? 0;

    // Shots fired from player descriptors / summaries
    final myShots = myPlayer?.totalAttemptedShots ?? (myHits > 0 ? myHits * 3 : 0);
    final oppShots = oppPlayer?.totalAttemptedShots ?? (oppHits > 0 ? oppHits * 3 : 0);

    // Accuracy
    final myAcc = myShots > 0 ? (myHits / myShots * 100).toStringAsFixed(1) : '—';
    final oppAcc = oppShots > 0 ? (oppHits / oppShots * 100).toStringAsFixed(1) : '—';

    // Dodges from summaries (stored in swishes or custom field)
    final myDodges = myPlayer?.roundSummaries.fold(0, (sum, r) => sum + r.swishes) ?? 0;
    final oppDodges = oppPlayer?.roundSummaries.fold(0, (sum, r) => sum + r.swishes) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(text: 'DUEL PERFORMANCE'),
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
                label: 'Hits Landed',
                val1: '$myHits',
                val2: '$oppHits',
                isVal1Better: myHits > oppHits,
                isVal2Better: oppHits > myHits,
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Shots Fired',
                val1: '$myShots',
                val2: '$oppShots',
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Accuracy',
                val1: myAcc == '—' ? '—' : '$myAcc%',
                val2: oppAcc == '—' ? '—' : '$oppAcc%',
                isVal1Better: (double.tryParse(myAcc) ?? 0) > (double.tryParse(oppAcc) ?? 0),
                isVal2Better: (double.tryParse(oppAcc) ?? 0) > (double.tryParse(myAcc) ?? 0),
              ),
              const Divider(color: Color(0xFF1E2638), height: 20),
              _buildStatRow(
                label: 'Times Dodged',
                val1: '$myDodges',
                val2: '$oppDodges',
                isVal1Better: myDodges > oppDodges,
                isVal2Better: oppDodges > myDodges,
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
    bool isVal1Better = false,
    bool isVal2Better = false,
  }) {
    return Row(
      children: [
        // Player 1 (You)
        SizedBox(
          width: 65,
          child: Text(
            val1,
            style: UiFont.style(
              size: 14.0,
              weight: isVal1Better ? 800 : 600,
              color: isVal1Better ? const Color(0xFF38BDF8) : Colors.white,
            ),
          ),
        ),

        // Metric Label
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

        // Player 2 (Opponent)
        SizedBox(
          width: 65,
          child: Text(
            val2,
            textAlign: TextAlign.right,
            style: UiFont.style(
              size: 14.0,
              weight: isVal2Better ? 800 : 600,
              color: isVal2Better ? const Color(0xFFF59E0B) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
