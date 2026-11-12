import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/record/club_record.dart';
import 'package:tiki_core/record/record_entry.dart';

/// One line on the hub: W–D–L, unbeaten run and the last five results.
/// Tap opens the full record.
class RecordStrip extends StatelessWidget {
  final ClubRecord record;
  final VoidCallback onTap;

  const RecordStrip({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = record.total;
    final empty = t.played == 0;
    return Semantics(
      button: true,
      label: 'Club record',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Text(
              'RECORD',
              style: TikiText.body(size: 11, weight: 700, color: TikiPalette.slate),
            ),
            const SizedBox(width: 14),
            if (empty)
              Text(
                'Play your first match to start your record',
                style: TikiText.body(size: 13, color: TikiPalette.slate),
              )
            else ...[
              _num('${t.won}', 'W'),
              _num('${t.drawn}', 'D'),
              _num('${t.lost}', 'L'),
              const SizedBox(width: 6),
              Text(
                'Unbeaten ${record.unbeatenNow}',
                style: TikiText.body(size: 13, color: const Color(0xFFCBD5E1)),
              ),
              const SizedBox(width: 16),
              for (final e in record.recent.take(5).toList().reversed) ResultDot(e.result),
            ],
            const Spacer(),
            Text(
              'Full record ›',
              style: TikiText.body(size: 13, weight: 700, color: TikiPalette.cyan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(String n, String l) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: n, style: TikiText.display(size: 16, weight: 900)),
          TextSpan(
            text: ' $l',
            style: TikiText.body(size: 12, color: TikiPalette.slate),
          ),
        ],
      ),
    ),
  );
}

/// A small W / D / L square.
class ResultDot extends StatelessWidget {
  final MatchResult result;

  const ResultDot(this.result, {super.key});

  @override
  Widget build(BuildContext context) {
    final (letter, color) = switch (result) {
      MatchResult.win => ('W', const Color(0xFF22C55E)),
      MatchResult.draw => ('D', TikiPalette.slate),
      MatchResult.loss => ('L', const Color(0xFFEF4444)),
    };
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(letter, style: TikiText.display(size: 11, weight: 900, color: color)),
    );
  }
}
