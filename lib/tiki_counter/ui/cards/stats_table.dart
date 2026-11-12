import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/model/match_state.dart';
import 'package:b_ball/tiki_counter/model/match_stats.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// Home vs away numbers for the half-time and full-time cards.
class StatsTable extends StatelessWidget {
  final MatchState state;

  const StatsTable({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final h = state.home.stats;
    final a = state.away.stats;
    final total = h.possessionSeconds + a.possessionSeconds;
    final hp = total <= 0 ? 50 : (h.possessionSeconds * 100 / total).round();
    final rows = <(String, String, String)>[
      ('Possession', '$hp%', '${100 - hp}%'),
      ('Shots', '${h.shots}', '${a.shots}'),
      ('Shots on target', '${h.shotsOnTarget}', '${a.shotsOnTarget}'),
      ('Passes', _passes(h), _passes(a)),
      ('Pass accuracy', '${h.passAccuracy()}%', '${a.passAccuracy()}%'),
      ('Interceptions', '${h.interceptions}', '${a.interceptions}'),
      ('Tackles won', '${h.tacklesWon}', '${a.tacklesWon}'),
      ('Saves', '${h.saves}', '${a.saves}'),
      if (state.mode.offside) ('Offsides', '${h.offsides}', '${a.offsides}'),
    ];
    return Column(
      children: [
        _header(),
        const SizedBox(height: 6),
        for (final r in rows) _row(r.$1, r.$2, r.$3),
      ],
    );
  }

  String _passes(TeamStats t) => '${t.passesCompleted}/${t.passesTried}';

  Widget _header() => Row(
    children: [
      Expanded(
        child: Text('HOME', style: TikiText.display(size: 12, weight: 600)),
      ),
      Text(
        '${state.home.score} – ${state.away.score}',
        style: TikiText.display(size: 18),
      ),
      Expanded(
        child: Text(
          'AWAY',
          textAlign: TextAlign.right,
          style: TikiText.display(
            size: 12,
            weight: 600,
            color: TikiPalette.amber,
          ),
        ),
      ),
    ],
  );

  Widget _row(String label, String home, String away) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF1F2E27))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(home, style: TikiText.display(size: 14)),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TikiText.body(size: 12),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            away,
            textAlign: TextAlign.right,
            style: TikiText.display(size: 14),
          ),
        ),
      ],
    ),
  );
}
