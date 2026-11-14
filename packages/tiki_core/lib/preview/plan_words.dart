import 'package:tiki_core/preview/preview_scene.dart';
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

  /// A brain job in plain words: "drop to receive" → "drops short to
  /// receive", "mark #7" → "marks their 7".
  static String move(String job) {
    final number = RegExp(r'#(\d+)').firstMatch(job)?.group(1);
    if (job.contains(':')) {
      final parts = job.split(':');
      return 'plays the ${parts[1].trim()} in the ${parts[0].trim()}';
    }
    if (job.startsWith('cut lane')) return 'blocks the pass to their $number';
    if (job.startsWith('mark')) return 'marks their $number';
    if (job.startsWith('track')) return 'tracks their $number';
    return switch (job) {
      'support' => 'comes close to offer a pass',
      'rest defence' => 'stays back to stop a counter',
      'hold far side' => 'holds the far touchline for a switch',
      'wait to run' => 'waits on the last line to run',
      'back to position' => 'jogs back to position',
      'run in behind' => 'runs in behind',
      'hold width' => 'holds the width',
      'drop to receive' => 'drops short to receive',
      'cut inside' => 'cuts inside',
      'overlap' => 'overlaps round the outside',
      'press' => 'presses the ball',
      'counter-press' => 'sprints at the ball',
      'second presser' => 'blocks the easy pass',
      'cover' => 'covers behind the press',
      'chase loose ball' => 'chases the loose ball',
      'drop into shape' => 'runs back into shape',
      'receive pass' => 'meets the pass',
      'keeper' || 'keeper claims' => 'keeps goal',
      _ when job.startsWith('shape') => 'holds his spot',
      _ => job,
    };
  }

  /// Where the ball is, for a team attacking to the right.
  static String where(double ballX, double halfLength) {
    if (ballX < -halfLength / 3) return 'in your half';
    if (ballX > halfLength / 3) return 'in their half';
    return 'in midfield';
  }

  /// "You have the ball in midfield. Watch: 9 drops short to receive,
  /// 7 runs in behind."
  static String caption(PreviewMoment m, double ballX, double halfLength,
      List<PreviewDisc> discs) {
    final w = where(ballX, halfLength);
    final opening = switch (m) {
      PreviewMoment.attacking => 'You have the ball $w.',
      PreviewMoment.defending => 'They have the ball $w.',
      PreviewMoment.gainingPossession => 'You just won the ball $w.',
      PreviewMoment.losingPossession => 'You just lost the ball $w.',
    };
    final movers = [
      for (final d in discs)
        if (d.moves && !d.keeper) d,
    ]..sort((a, b) => b.distanceSquared.compareTo(a.distanceSquared));
    if (movers.isEmpty) return '$opening Everyone holds their spot.';
    final watch = movers
        .take(2)
        .map((d) => '${d.number} ${move(d.job)}')
        .join(', ');
    return '$opening Watch: $watch.';
  }
}
