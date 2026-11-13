import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/match_state.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/preview/staging.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

enum DrillOutcome { running, passed, failed }

/// A short scored challenge in the Lab: a staged moment, a goal and a time
/// limit. The match engine runs as normal; the drill only sets the start
/// and judges the result. You are always home, attacking to the right.
class Drill {
  final String id;
  final String title;

  /// What you have to do, one line.
  final String goal;

  /// Why it matters, one line.
  final String lesson;
  final double timeLimit;
  final GameMode mode;

  /// How the bot plays in this drill.
  final TeamPlan opponentPlan;

  /// Puts the match into the drill's starting moment.
  final void Function(MatchState s) stage;

  /// Judges the drill after [t] seconds. Called every step.
  final DrillOutcome Function(MatchState s, double t, DrillStart start) judge;

  /// Shown when you fail, so you know why.
  final String Function(MatchState s, double t, DrillStart start) failReason;

  const Drill({
    required this.id,
    required this.title,
    required this.goal,
    required this.lesson,
    required this.timeLimit,
    required this.mode,
    required this.opponentPlan,
    required this.stage,
    required this.judge,
    required this.failReason,
  });
}

/// What the match looked like when the drill started (for judging).
class DrillStart {
  final int homeScore;
  final int awayScore;

  DrillStart(MatchState s) : homeScore = s.home.score, awayScore = s.away.score;
}

bool _homeHasIt(MatchState s) => s.owner?.side == Side.home;
bool _awayHasIt(MatchState s) => s.owner?.side == Side.away;

/// The ball stopped for a restart that goes to [side].
bool _restartFor(MatchState s, Side side) =>
    s.pending?.setPiece.team == side || s.setPiece?.team == side;

abstract final class Drills {
  /// Get out of your own half against a team pressing high.
  static final Drill breakThePress = Drill(
    id: 'break_the_press',
    title: 'Break the press',
    goal: 'Get the ball into their half within 12 seconds. Don\'t lose it.',
    lesson: 'Against a high press the free player is usually the one '
        'furthest from the ball. Move it quickly.',
    timeLimit: 12.0,
    mode: GameMode.fiveASide,
    opponentPlan: Presets.gegenpress,
    stage: (s) {
      final hl = s.mode.halfLength;
      final bx = -0.7 * hl;
      final by = 0.15 * s.mode.halfWidth;
      Staging.shape(s, Side.away, bx * 0.6, by); // they're pushed up high
      Staging.takeBall(s, Side.home, bx, by);
    },
    judge: (s, t, start) {
      if (_awayHasIt(s) || s.away.score > start.awayScore) {
        return DrillOutcome.failed;
      }
      if (_restartFor(s, Side.away)) return DrillOutcome.failed;
      if (_homeHasIt(s) && s.ball.pos.x > 0.0) return DrillOutcome.passed;
      return t > 12.0 ? DrillOutcome.failed : DrillOutcome.running;
    },
    failReason: (s, t, start) => t > 12.0
        ? 'Out of time — the ball needs to reach their half.'
        : 'They won the ball.',
  );

  /// Win the ball back fast after losing it.
  static final Drill winItBack = Drill(
    id: 'win_it_back',
    title: 'Win it back',
    goal: 'They have the ball in your half. Win it back within 8 seconds.',
    lesson: 'Press the carrier with DASH, let your teammates cut the passes, '
        'and TACKLE when you\'re close.',
    timeLimit: 8.0,
    mode: GameMode.fiveASide,
    opponentPlan: Presets.balanced,
    stage: (s) {
      final bx = -0.25 * s.mode.halfLength;
      final by = -0.1 * s.mode.halfWidth;
      Staging.shape(s, Side.home, bx + 6.0, by); // you were attacking
      Staging.takeBall(s, Side.away, bx, by);
    },
    judge: (s, t, start) {
      if (s.away.score > start.awayScore) return DrillOutcome.failed;
      if (_homeHasIt(s) || _restartFor(s, Side.home)) {
        return DrillOutcome.passed;
      }
      return t > 8.0 ? DrillOutcome.failed : DrillOutcome.running;
    },
    failReason: (s, t, start) => s.away.score > start.awayScore
        ? 'They scored.'
        : 'Out of time — they kept the ball.',
  );

  /// Score against a deep, compact defence.
  static final Drill unlockTheBlock = Drill(
    id: 'unlock_the_block',
    title: 'Unlock the low block',
    goal: 'Score within 25 seconds against a deep defence. Don\'t lose it.',
    lesson: 'Move the ball side to side until a gap opens, then go through '
        'it. Patterns like the overlap help.',
    timeLimit: 25.0,
    mode: GameMode.fiveASide,
    opponentPlan: Presets.lowBlock,
    stage: (s) {
      const bx = 0.0;
      final by = 0.1 * s.mode.halfWidth;
      Staging.shape(s, Side.home, bx, by);
      Staging.takeBall(s, Side.home, bx, by);
    },
    judge: (s, t, start) {
      if (s.home.score > start.homeScore) return DrillOutcome.passed;
      if (_awayHasIt(s) || _restartFor(s, Side.away)) {
        return DrillOutcome.failed;
      }
      return t > 25.0 ? DrillOutcome.failed : DrillOutcome.running;
    },
    failReason: (s, t, start) =>
        t > 25.0 ? 'Out of time.' : 'They won the ball.',
  );

  static final List<Drill> all = [breakThePress, winItBack, unlockTheBlock];

  /// Stages [d] on a freshly created match and clears the kick-off.
  /// Returns the snapshot the drill is judged against.
  static DrillStart start(MatchState s, Drill d) {
    s.pending = null;
    s.setPiece = null;
    d.stage(s);
    s.setPiece = null;
    s.events.clear();
    return DrillStart(s);
  }
}
