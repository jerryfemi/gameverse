import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/game_plan/plan_panel.dart';
import 'package:b_ball/tiki_counter/menu/home/record_strip.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/control/bot_level.dart';
import 'package:tiki_core/record/club_record.dart';
import 'package:tiki_core/record/record_entry.dart';

/// Your club's full record vs the bot: totals, best results, how each bot
/// level / playstyle / formation has gone, and the last 10 matches.
class RecordScreen extends StatelessWidget {
  final String clubName;
  final ClubRecord record;
  final VoidCallback onBack;

  const RecordScreen({
    super.key,
    required this.clubName,
    required this.record,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final r = record;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuHeader(title: 'Club record', subtitle: clubName, onBack: onBack),
            const SizedBox(height: 16),
            Expanded(
              child: r.total.played == 0
                  ? Center(
                      child: Text(
                        'No matches yet. Every match you play against the bot '
                        'is added here.',
                        textAlign: TextAlign.center,
                        style: TikiText.body(size: 15, color: TikiPalette.slate),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: _totals(r)),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: _splits(r)),
                        const SizedBox(width: 16),
                        Expanded(flex: 6, child: _recent(r)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totals(ClubRecord r) {
    final t = r.total;
    final best = r.bestWin;
    final style = r.bestPlaystyle();
    return PlanPanel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _big('${t.won}', 'WON'),
                _big('${t.drawn}', 'DRAWN'),
                _big('${t.lost}', 'LOST'),
              ],
            ),
            const SizedBox(height: 14),
            _line('Played', '${t.played}'),
            _line('Win rate', '${t.winRate}%'),
            _line('Goals', '${r.goalsFor} for · ${r.goalsAgainst} against'),
            _line('Clean sheets', '${r.cleanSheets}'),
            _line('Unbeaten run', '${r.unbeatenNow} now · ${r.unbeatenBest} best'),
            if (best != null)
              _line('Best win', '${best.goalsFor}–${best.goalsAgainst} vs ${best.opponentCode}'),
            _line('Pass accuracy', '${r.averagePassAccuracy}% average'),
            _line('Possession', '${r.averagePossession}% average'),
            _line('Pattern runs found', '${r.patternRuns}'),
            if (style != null) ...[
              const SizedBox(height: 12),
              Text(
                '${style.key} wins you ${style.value.winRate}%',
                style: TikiText.body(size: 14, weight: 700, color: TikiPalette.cyan),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _splits(ClubRecord r) {
    final levels = [
      for (final l in BotLevel.all)
        if (r.byLevel[l.name] != null) MapEntry(l.name, r.byLevel[l.name]!),
    ];
    final styles = r.byPlaystyle.entries.toList()
      ..sort((a, b) => b.value.played.compareTo(a.value.played));
    final forms = r.byFormation.entries.toList()
      ..sort((a, b) => b.value.played.compareTo(a.value.played));
    return PlanPanel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Against the bot'),
            for (final e in levels) _wdl(e.key, e.value),
            const SizedBox(height: 14),
            const SectionLabel('By playstyle'),
            for (final e in styles) _wdl(e.key, e.value),
            const SizedBox(height: 14),
            const SectionLabel('By formation'),
            for (final e in forms) _wdl(e.key, e.value),
          ],
        ),
      ),
    );
  }

  Widget _recent(ClubRecord r) {
    return PlanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Last 10 matches'),
          Expanded(
            child: ListView.separated(
              itemCount: r.recent.length,
              separatorBuilder: (_, _) => const Divider(height: 14, color: Color(0xFF1E2E26)),
              itemBuilder: (_, i) => _match(r.recent[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _match(RecordEntry e) {
    final d = DateTime.fromMillisecondsSinceEpoch(e.playedAt).toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ResultDot(e.result),
            const SizedBox(width: 6),
            Text('${e.goalsFor}–${e.goalsAgainst}', style: TikiText.display(size: 16, weight: 900)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'vs ${e.opponentName}',
                overflow: TextOverflow.ellipsis,
                style: TikiText.body(size: 13, color: Colors.white),
              ),
            ),
            Text(
              '${d.day} ${months[d.month - 1]}',
              style: TikiText.body(size: 12, color: TikiPalette.slate),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${e.mode} · ${e.botLevel} · ${e.playstyle} · ${e.formation}   '
          'Poss ${e.possession}% · Pass ${e.passAccuracy}% · Shots ${e.shots}',
          style: TikiText.body(size: 12, color: TikiPalette.slate),
        ),
      ],
    );
  }

  Widget _big(String n, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(n, style: TikiText.display(size: 34, weight: 900)),
        Text(label, style: TikiText.body(size: 11, weight: 700, color: TikiPalette.slate)),
      ],
    ),
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Text(label, style: TikiText.body(size: 13, color: TikiPalette.slate)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TikiText.body(size: 13, weight: 700, color: Colors.white),
          ),
        ),
      ],
    ),
  );

  Widget _wdl(String name, WdL w) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TikiText.body(size: 13, weight: 700, color: Colors.white),
          ),
        ),
        Text(
          '${w.won}W ${w.drawn}D ${w.lost}L',
          style: TikiText.body(size: 13, color: const Color(0xFFCBD5E1)),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '${w.winRate}%',
            textAlign: TextAlign.right,
            style: TikiText.body(size: 13, weight: 700, color: TikiPalette.cyan),
          ),
        ),
      ],
    ),
  );
}
