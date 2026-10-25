import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/providers/app_providers.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/ui/results/results_sheet.dart';

/// Single match history row in the full Head-to-Head panel per Artboard 4.
class H2HMatchRow extends ConsumerWidget {
  final MatchSummary summary;

  const H2HMatchRow({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMatches = ref.read(userMatchesProvider).value ?? const [];
    final originalMatch =
        allMatches.where((m) => m.id == summary.matchId).firstOrNull;

    final IconData icon;
    final Color iconColor;
    final Color iconBg;

    final g = summary.game.toLowerCase().trim();
    if (g == 'darts') {
      icon = Icons.adjust_rounded;
      iconColor = const Color(0xFFF87171);
      iconBg = const Color(0x26F87171);
    } else if (g == 'archery') {
      icon = Icons.arrow_outward_rounded;
      iconColor = const Color(0xFF00FFCC);
      iconBg = const Color(0x2600FFCC);
    } else {
      icon = Icons.sports_basketball_rounded;
      iconColor = const Color(0xFFF59E0B);
      iconBg = const Color(0x26F59E0B);
    }

    final dateStr = _formatDate(summary.finishedAt);
    final isWin = summary.didIWin == true;
    final isLoss = summary.didIWin == false;

    final pillLabel = isWin ? 'WON' : (isLoss ? 'LOST' : 'DRAW');
    final pillBg = isWin
        ? const Color(0x2600FFCC)
        : (isLoss ? const Color(0x26F87171) : const Color(0xFF1E2638));
    final pillColor = isWin
        ? const Color(0xFF00FFCC)
        : (isLoss ? const Color(0xFFF87171) : const Color(0xFF94A3B8));

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (originalMatch != null) {
          ResultsSheet.show(context, originalMatch);
        }
      },
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 16.0, color: iconColor),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.verdictLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiFont.style(
                      size: 13.0,
                      weight: 700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    dateStr,
                    style: UiFont.style(
                      size: 11.0,
                      weight: 600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                pillLabel,
                style: UiFont.style(
                  size: 11.0,
                  weight: 900,
                  color: pillColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int timestampMs) {
    if (timestampMs <= 0) return 'Recent';
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.subtract(const Duration(days: 1)).day;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (isToday) return 'Today · $hour:$minute';
    if (isYesterday) return 'Yesterday · $hour:$minute';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
