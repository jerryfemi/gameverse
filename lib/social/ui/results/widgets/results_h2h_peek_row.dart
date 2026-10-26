import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:b_ball/social/models/match_summary.dart';
import 'package:b_ball/social/providers/social_providers.dart';
import 'package:b_ball/social/ui/in_game/h2h_card.dart';

/// Compact interactive Head-to-Head peek bar in [ResultsSheet],
/// displaying current series record and expanding the full H2H sheet on tap.
class ResultsH2HPeekRow extends ConsumerWidget {
  final MatchSummary summary;
  final VoidCallback? onOpenH2H;

  const ResultsH2HPeekRow({
    super.key,
    required this.summary,
    this.onOpenH2H,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h2h = ref.watch(headToHeadProvider(summary.opponent.uid));

    final String leadWord;
    if (h2h.myWins > h2h.theirWins) {
      leadWord = 'You lead ';
    } else if (h2h.theirWins > h2h.myWins) {
      leadWord = '${summary.opponent.name} leads ';
    } else {
      leadWord = 'Level ';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onOpenH2H != null) {
            onOpenH2H!();
          } else {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (sheetCtx) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: H2HCard.full(
                    myUid: summary.me.uid,
                    opponentUid: summary.opponent.uid,
                    opponentName: summary.opponent.name,
                    opponentAvatar: summary.opponent.avatar,
                    myAvatar: summary.me.avatar,
                    onCollapse: () => Navigator.of(sheetCtx).pop(),
                  ),
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFF1E2638), width: 1.0),
          ),
          child: Row(
            children: [
              Text(
                'HEAD TO HEAD',
                style: UiFont.style(
                  size: 11.0,
                  weight: 800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: UiFont.style(size: 12.0, weight: 700),
                    children: [
                      TextSpan(text: leadWord),
                      TextSpan(
                        text: '${h2h.myWins}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(text: ' – '),
                      TextSpan(
                        text: '${h2h.theirWins}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64748B),
                size: 18.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
