import 'package:tiki_core/record/club_record.dart';
import 'package:tiki_core/record/record_entry.dart';

import 'harness.dart';

RecordEntry _match(int gf, int ga, {String style = 'Tiki-taka', String level = 'Easy'}) =>
    RecordEntry(
      playedAt: 0,
      mode: '5v5',
      botLevel: level,
      playstyle: style,
      formation: '2-1-1',
      opponentName: 'Harbour Rovers',
      opponentCode: 'HRV',
      goalsFor: gf,
      goalsAgainst: ga,
      possession: 60,
      passAccuracy: 70,
      shots: 5,
      patternRuns: 1,
    );

void recordChecks() {
  check('club record adds up results, streaks and best win', () {
    final c = ClubRecord()
      ..add(_match(2, 0))
      ..add(_match(1, 1))
      ..add(_match(4, 1))
      ..add(_match(0, 3, level: 'Hard'))
      ..add(_match(3, 2));
    expectEqual(c.total.played, 5, 'played');
    expectEqual(c.total.won, 3, 'won');
    expectEqual(c.total.drawn, 1, 'drawn');
    expectEqual(c.total.lost, 1, 'lost');
    expectEqual(c.cleanSheets, 1, 'clean sheets');
    expectEqual(c.unbeatenBest, 3, 'longest unbeaten');
    expectEqual(c.unbeatenNow, 1, 'unbeaten now');
    expectEqual(c.bestWin!.goalsFor, 4, 'best win');
    expectEqual(c.byLevel['Hard']!.lost, 1, 'hard losses');
    expectEqual(c.recent.first.goalsFor, 3, 'newest first');
  });

  check('club record survives saving and loading', () {
    final c = ClubRecord();
    for (var n = 0; n < 14; n++) {
      c.add(_match(n % 3, 1, style: n.isEven ? 'Gegenpress' : 'Low block'));
    }
    final back = ClubRecord.fromJson(c.toJson());
    expectEqual(back.total.played, 14, 'played');
    expectEqual(back.recent.length, ClubRecord.keepRecent, 'only the last 10 kept');
    expectEqual(back.byPlaystyle['Gegenpress']!.played, 7, 'by playstyle');
    expectEqual(back.averagePassAccuracy, 70, 'average pass accuracy');
    expectEqual(back.unbeatenBest, c.unbeatenBest, 'unbeaten best');
  });
}
