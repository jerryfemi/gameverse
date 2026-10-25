import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/ui/common/game_chip.dart';
import 'package:b_ball/social/ui/common/verdict_banner.dart';
import 'package:b_ball/social/ui/results/archery_results_body.dart';
import 'package:b_ball/social/ui/results/darts_results_body.dart';
import 'package:b_ball/social/ui/results/hoops_results_body.dart';
import 'package:b_ball/social/ui/results/widgets/results_comparison_cards.dart';
import 'package:b_ball/social/ui/results/widgets/results_footer_actions.dart';
import 'package:b_ball/social/ui/results/widgets/results_h2h_peek_row.dart';
import 'package:b_ball/social/ui/results/widgets/results_header_versus.dart';

/// Full-screen modern match recap modal sheet displaying comprehensive scores,
/// player performance analytics, and instant rematch triggers without launching Flame.
class ResultsSheet extends StatelessWidget {
  final CloudMatch match;
  final VoidCallback? onOpenH2H;

  const ResultsSheet({super.key, required this.match, this.onOpenH2H});

  /// Displays the [ResultsSheet] modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    CloudMatch match, {
    VoidCallback? onOpenH2H,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => ResultsSheet(match: match, onOpenH2H: onOpenH2H),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService.instance.currentUser?.uid ?? '';
    final summary = MatchSummary.fromMatch(match, myUid);
    final size = MediaQuery.sizeOf(context);

    return Container(
      height: size.height * 0.96,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: Column(
        children: [
          // ── Grabber & Header ──────────────────────────────────────────────
          _buildGrabber(),
          _buildTopBar(context),

          // ── Scrollable Recap Content ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),

                  // 1. Crowned Avatars Versus
                  ResultsHeaderVersus(summary: summary),
                  const SizedBox(height: 18.0),

                  // 2. Hero Verdict Banner
                  VerdictBanner.hero(
                    win: summary.didIWin ?? false,
                    line: summary.verdictLine,
                  ),
                  const SizedBox(height: 18.0),

                  // 3. Two Comparison Score Cards
                  ResultsComparisonCards(summary: summary),
                  const SizedBox(height: 20.0),

                  // 4. Game-Specific Analytics Body
                  _buildGameBody(myUid),
                  const SizedBox(height: 18.0),

                  // 5. Head-to-Head Peek Row
                  ResultsH2HPeekRow(
                    summary: summary,
                    onOpenH2H: onOpenH2H,
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),

          // ── Sticky Action Buttons ─────────────────────────────────────────
          ResultsFooterActions(match: match, myUid: myUid),
        ],
      ),
    );
  }

  Widget _buildGrabber() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
      child: Center(
        child: Container(
          width: 38.0,
          height: 4.0,
          decoration: BoxDecoration(
            color: const Color(0x5564748B),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final dateStr = _formatDate(
      match.updatedAt > 0 ? match.updatedAt : match.createdAt,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GameChip.fromMatch(match),
          Text(
            dateStr,
            style: UiFont.style(
              size: 12.0,
              weight: 600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF94A3B8),
              size: 22.0,
            ),
            splashRadius: 20.0,
          ),
        ],
      ),
    );
  }

  Widget _buildGameBody(String myUid) {
    if (match.isDarts) {
      return DartsResultsBody(match: match, myUid: myUid);
    }
    if (match.isArchery) {
      return ArcheryResultsBody(match: match, myUid: myUid);
    }
    return HoopsResultsBody(match: match, myUid: myUid);
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
