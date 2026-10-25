import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/cloud_match.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_match_service.dart';
import '../../models/match_summary.dart';
import '../common/crown_avatar.dart';
import '../common/game_chip.dart';
import '../common/verdict_banner.dart';
import '../results/results_sheet.dart';

/// Card widget for completed matches adhering to Artboard 5 of GameVerse design.
///
/// Features:
/// - Row 1: GameChip pill, relative/compact timestamp, trash button with delete flow.
/// - Row 2: Tile-style VerdictBanner with outcome badge and narrative explanation.
/// - Row 3: CrownAvatar (40px) and formatted player performance summaries.
/// - Row 4: Full-width secondary "View results ›" button triggering ResultsSheet.
class CompletedMatchTile extends StatelessWidget {
  final CloudMatch match;
  final String? myUid;
  final VoidCallback? onDelete;
  final VoidCallback? onViewResults;

  const CompletedMatchTile({
    super.key,
    required this.match,
    this.myUid,
    this.onDelete,
    this.onViewResults,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUid = myUid ?? AuthService.instance.currentUser?.uid ?? '';
    final summary = MatchSummary.fromMatch(match, effectiveUid);
    final dateStr = _formatDate(summary.finishedAt);

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
          // Row 1: GameChip, Date, and Delete Button
          Row(
            children: [
              GameChip.fromMatch(match),
              const SizedBox(width: 10.0),
              Text(
                dateStr,
                style: UiFont.style(
                  size: 12.0,
                  weight: 600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              _buildTrashButton(context, effectiveUid),
            ],
          ),
          const SizedBox(height: 12.0),

          // Row 2: VerdictBanner (tile style)
          VerdictBanner.tile(
            win: summary.didIWin == true,
            line: summary.verdictLine,
          ),
          const SizedBox(height: 12.0),

          // Row 3: H2H Performance and Avatars
          Row(
            children: [
              // You
              CrownAvatar(
                avatar: summary.me.avatar,
                size: 40.0,
                crowned: summary.didIWin == true,
              ),
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
                    Text(
                      summary.me.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiFont.style(
                        size: 18.0,
                        weight: 900,
                        color: Colors.white,
                      ),
                    ),
                    if (summary.me.unit.isNotEmpty) ...[
                      const SizedBox(height: 1.0),
                      Text(
                        summary.me.unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiFont.style(
                          size: 11.0,
                          weight: 600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // VS divider
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

              // Opponent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      summary.opponent.name.toUpperCase(),
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
                    Text(
                      summary.opponent.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiFont.style(
                        size: 18.0,
                        weight: 900,
                        color: Colors.white,
                      ),
                    ),
                    if (summary.opponent.unit.isNotEmpty) ...[
                      const SizedBox(height: 1.0),
                      Text(
                        summary.opponent.unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiFont.style(
                          size: 11.0,
                          weight: 600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              CrownAvatar(
                avatar: summary.opponent.avatar,
                size: 40.0,
                crowned: summary.didIWin == false,
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Row 4: View Results Button
          SizedBox(
            height: 40.0,
            child: Material(
              color: const Color(0xFF1E2638),
              borderRadius: BorderRadius.circular(12.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (onViewResults != null) {
                    onViewResults!();
                  } else {
                    ResultsSheet.show(context, match);
                  }
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0xFF2A344A),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View results',
                        style: UiFont.style(
                          size: 13.0,
                          weight: 700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16.0,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashButton(BuildContext context, String effectiveUid) {
    return SizedBox(
      width: 32.0,
      height: 32.0,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.delete_outline_rounded,
          size: 18.0,
          color: Color(0xFF64748B),
        ),
        tooltip: 'Remove match',
        onPressed: () {
          if (onDelete != null) {
            onDelete!();
          } else {
            _confirmDelete(context, effectiveUid);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String effectiveUid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF131826),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color(0xFF2E3954),
            width: 1.5,
          ),
        ),
        title: Text(
          'REMOVE MATCH',
          style: UiFont.style(
            size: 16.0,
            weight: 900,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        content: Text(
          'Remove this finished match from your history?',
          style: UiFont.style(
            size: 13.0,
            weight: 500,
            color: const Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'CANCEL',
              style: UiFont.style(
                size: 13.0,
                weight: 700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'REMOVE',
              style: UiFont.style(
                size: 13.0,
                weight: 800,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && effectiveUid.isNotEmpty) {
      await FirestoreMatchService.instance.leaveOrDismissMatch(
        matchId: match.id,
        myUid: effectiveUid,
      );
      onDelete?.call();
    }
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
