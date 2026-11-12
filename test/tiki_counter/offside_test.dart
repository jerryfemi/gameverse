import 'package:flutter_test/flutter_test.dart';

import 'package:b_ball/tiki_counter/model/game_mode.dart';
import 'package:b_ball/tiki_counter/sim/match_setup.dart';
import 'package:b_ball/tiki_counter/sim/rules/offside.dart';
import 'package:b_ball/tiki_counter/tactics/formations.dart';

void main() {
  test('attacker beyond the second-last defender is offside', () {
    final s = MatchSetup.create(
      mode: GameMode.sevenASide,
      homeFormation: Formations.sevenA231,
      awayFormation: Formations.sevenA231,
    );
    // Away defends the +x goal. Keeper deepest, one defender at x = 15.
    for (final d in s.away.discs) {
      d.pos.set(5.0, 0.0);
    }
    s.away.discs[0].pos.set(26.0, 0.0); // keeper
    s.away.discs[1].pos.set(15.0, -5.0); // second-last defender

    final passer = s.home.discs[4];
    passer.pos.set(0.0, 0.0);
    s.ball.pos.set(0.8, 0.0);
    final striker = s.home.discs[6];
    final level = s.home.discs[5];
    striker.pos.set(18.0, 3.0); // beyond the defender
    level.pos.set(14.0, -3.0); // behind the defender: onside

    final out = <int>{};
    Offside.snapshot(s, passer, out);
    expect(out.contains(striker.id), isTrue);
    expect(out.contains(level.id), isFalse);
  });

  test('nobody is offside in their own half', () {
    final s = MatchSetup.create(
      mode: GameMode.sevenASide,
      homeFormation: Formations.sevenA231,
      awayFormation: Formations.sevenA231,
    );
    for (final d in s.away.discs) {
      d.pos.set(-10.0, 0.0);
    }
    final passer = s.home.discs[1];
    passer.pos.set(-20.0, 0.0);
    s.ball.pos.set(-19.0, 0.0);
    s.home.discs[6].pos.set(-5.0, 0.0);
    final out = <int>{};
    Offside.snapshot(s, passer, out);
    expect(out, isEmpty);
  });
}
