import 'package:tiki_core/preview/plan_preview.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Plain-English text for the game plan screen, written from the plan's
/// own choices so a custom plan is described correctly too.
abstract final class PlanWords {
  static String attack(AttackStyle a) => switch (a) {
    AttackStyle.possession => 'Possession',
    AttackStyle.direct => 'Direct',
    AttackStyle.overload => 'Overload',
    AttackStyle.wide => 'Wide',
  };

  static String afterWin(AfterWin a) => switch (a) {
    AfterWin.keep => 'Keep it',
    AfterWin.counter => 'Counter',
  };

  static String afterLoss(AfterLoss a) => switch (a) {
    AfterLoss.counterPress => 'Counter-press',
    AfterLoss.dropIntoShape => 'Drop into shape',
  };

  static String marking(Marking m) => switch (m) {
    Marking.zonal => 'Zonal',
    Marking.man => 'Man-to-man',
  };

  static String line(double h) => h < 0.3
      ? 'Low block'
      : (h < 0.65 ? 'Mid block' : 'High line');

  /// One-line heading for a moment.
  static String headline(TeamPlan p, PreviewMoment m) => switch (m) {
    PreviewMoment.attacking => attack(p.attack),
    PreviewMoment.defending => '${line(p.lineHeight)}, ${marking(p.marking).toLowerCase()}',
    PreviewMoment.gainingPossession => afterWin(p.afterWin),
    PreviewMoment.losingPossession => afterLoss(p.afterLoss),
  };

  /// Two or three sentences on what the team does in that moment.
  static String explain(TeamPlan p, PreviewMoment m) {
    switch (m) {
      case PreviewMoment.attacking:
        return switch (p.attack) {
          AttackStyle.possession =>
            'Short passes and close support. Teammates come near the ball '
                'to make triangles; few runs in behind.',
          AttackStyle.direct =>
            'Forward early. Runners go in behind the last defender and the '
                'ball goes over or through the line quickly.',
          AttackStyle.overload =>
            'Extra players crowd the side the ball is on for quick one-twos, '
                'then switch it to the free side.',
          AttackStyle.wide =>
            'Wide players hold the touchline to stretch the other team, and '
                'full backs overlap round the outside.',
        };
      case PreviewMoment.defending:
        final press = p.pressIntensity > 0.65
            ? 'The front players press high.'
            : (p.pressIntensity < 0.3
                  ? 'Nobody presses until the ball is close to goal.'
                  : 'The nearest player presses once the ball reaches midfield.');
        final mark = p.marking == Marking.man
            ? 'Each defender follows one opponent.'
            : 'Players guard spaces and shift together toward the ball.';
        return '${line(p.lineHeight)}: the back line stands '
            '${p.lineHeight > 0.65 ? 'near halfway' : (p.lineHeight < 0.3 ? 'deep, near the box' : 'in the middle of its half')}. '
            '$mark $press';
      case PreviewMoment.gainingPossession:
        return p.afterWin == AfterWin.keep
            ? 'For 3 seconds after winning the ball, the nearest players come '
                  'close for a safe first pass while the other team is still '
                  'out of shape.'
            : 'The moment the ball is won, forwards sprint in behind for an '
                  'early pass forward before the other team can get back.';
      case PreviewMoment.losingPossession:
        return p.afterLoss == AfterLoss.counterPress
            ? 'The nearest players sprint at the ball straight away to win it '
                  'back high up. If it is not won in about 3 seconds, the team '
                  'drops into its block.'
            : 'Everyone runs back into shape first. Nobody chases; the team '
                  'waits in its block for the next press trigger.';
    }
  }
}
