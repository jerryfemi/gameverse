import 'package:tiki_core/brain/patterns/library.dart';
import 'package:tiki_core/brain/patterns/pattern.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/brain/phase.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/model/game_mode.dart';
import 'package:tiki_core/model/side.dart';
import 'package:tiki_core/preview/preview_scene.dart';
import 'package:tiki_core/preview/staging.dart';
import 'package:tiki_core/sim/match_setup.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/position.dart';
import 'package:tiki_core/tactics/presets.dart';
import 'package:tiki_core/tactics/team_plan.dart';

/// Where a pattern demo starts and how the ball moves through it.
class _DemoSpec {
  /// Ball position as fractions of half-length / half-width (we attack +x).
  final double bx;
  final double by;

  /// Positions that should be on the ball when one is close.
  final Set<Position> carriers;

  /// The ball's route once the runs are made: 'carrier' or a part index.
  final List<Object> route;

  /// What the pattern is for, in one or two sentences.
  final String blurb;

  /// What each part does, in plain words (same order as the parts).
  final List<String> parts;

  const _DemoSpec({
    required this.bx,
    required this.by,
    required this.carriers,
    required this.route,
    required this.blurb,
    required this.parts,
  });
}

/// Plain-English text for a pattern, for the Lab.
class PatternInfo {
  final String title;
  final String blurb;

  /// "9 · dropper: comes short to pull his marker out", one per part.
  final List<String> roles;

  const PatternInfo(this.title, this.blurb, this.roles);
}

/// Shows a pattern on the board: the team set up where it usually starts,
/// each part played by whoever the pattern itself picks, and the ball
/// travelling along the pattern's passes. Opponents stand still.
abstract final class PatternPreview {
  static const Map<String, _DemoSpec> _specs = {
    'up_back_through': _DemoSpec(
      bx: -0.1,
      by: 0.05,
      carriers: {Position.holdingMid, Position.centralMid, Position.centreBack},
      route: [0, 'carrier', 1],
      blurb: 'Their back line marks your striker tightly. He comes short to '
          'lay the ball back, which drags his marker out; the pass goes '
          'through into the space he left.',
      parts: [
        'comes short and plays it back first time',
        'runs into the space behind for the through ball',
      ],
    ),
    'overlap': _DemoSpec(
      bx: 0.15,
      by: 0.55,
      carriers: {
        Position.wideMid,
        Position.winger,
        Position.attackingMid,
        Position.striker,
      },
      route: [0],
      blurb: 'The ball is wide. The player behind runs round the outside of '
          'the carrier while a teammate offers the inside pass, so the '
          'defender can only stop one.',
      parts: [
        'runs round the outside for the ball down the line',
        'offers the safe pass inside (the decoy)',
      ],
    ),
    'third_man': _DemoSpec(
      bx: -0.35,
      by: 0.15,
      carriers: {Position.centreBack, Position.holdingMid, Position.fullBack},
      route: [0, 1],
      blurb: 'From deep, a teammate ahead comes towards the ball as a wall. '
          'A third player runs beyond him and receives the lay-off going '
          'forward — the marker watches the wall, not the runner.',
      parts: [
        'comes towards the ball as the wall',
        'runs beyond the wall to receive the lay-off',
      ],
    ),
  };

  static const _DemoSpec _fallback = _DemoSpec(
    bx: 0.0,
    by: 0.0,
    carriers: {},
    route: [0, 1],
    blurb: '',
    parts: [],
  );

  static PatternInfo info(Pattern p) {
    final spec = _specs[p.id] ?? _fallback;
    final title = p.label.isEmpty
        ? p.id
        : p.label[0].toUpperCase() + p.label.substring(1);
    return PatternInfo(title, spec.blurb, [
      for (var i = 0; i < p.parts.length; i++)
        '${p.parts[i].name}: ${i < spec.parts.length ? spec.parts[i] : ''}',
    ]);
  }

  static List<Pattern> get all => PatternLibrary.all;

  static PreviewScene build({
    required GameMode mode,
    required Pattern pattern,
    Formation? formation,
    TeamPlan plan = Presets.balanced,
  }) {
    final spec = _specs[pattern.id] ?? _fallback;
    final s = MatchSetup.create(
      mode: mode,
      homeFormation: formation ?? Formations.defaultFor(mode),
      awayFormation: Formations.defaultFor(mode),
      homePlan: plan,
    );
    s.setPiece = null;
    final bx = spec.bx * mode.halfLength;
    final by = spec.by * mode.halfWidth;
    Staging.shape(s, Side.home, bx, by);
    final carrier = Staging.takeBall(
      s,
      Side.home,
      bx,
      by,
      prefer: (d) => spec.carriers
          .contains(s.home.formation.spots[d.slot].position),
    );

    // Each part: the pattern's own pick and move.
    final v = TeamView.build(s, Side.home, Phase.attacking);
    final taken = <int>{};
    final targets = <int, ({double x, double y})>{};
    final jobs = <int, String>{};
    final partDisc = <int, Disc>{};
    for (var i = 0; i < pattern.parts.length; i++) {
      final part = pattern.parts[i];
      final d = part.pick(v, carrier, taken);
      if (d == null) continue;
      final m = part.move(v, carrier, d);
      if (m == null) continue;
      taken.add(d.id);
      targets[d.id] = m;
      jobs[d.id] = '${pattern.label}: ${part.name}';
      partDisc[i] = d;
    }

    final discs = <PreviewDisc>[
      for (final d in s.discs)
        PreviewDisc(
          number: d.number,
          ours: d.side == Side.home,
          keeper: d.isKeeper,
          x: d.pos.x,
          y: d.pos.y,
          tx: targets[d.id]?.x ?? d.pos.x,
          ty: targets[d.id]?.y ?? d.pos.y,
          job: jobs[d.id] ?? '',
        ),
    ];

    final path = <BallStop>[];
    for (final step in spec.route) {
      if (step == 'carrier') {
        path.add((x: s.ball.pos.x, y: s.ball.pos.y));
      } else if (step is int && partDisc[step] != null) {
        final t = targets[partDisc[step]!.id]!;
        path.add((x: t.x, y: t.y));
      }
    }
    // A route that ends back at the carrier isn't a pattern: drop it.
    if (path.isNotEmpty && spec.route.last == 'carrier') path.removeLast();

    final names = [
      for (var i = 0; i < pattern.parts.length; i++)
        if (partDisc[i] != null) '${partDisc[i]!.number} ${pattern.parts[i].name}',
    ];
    return PreviewScene(
      mode,
      discs,
      s.ball.pos.x,
      s.ball.pos.y,
      carrier.number,
      ballPath: path,
      caption: names.isEmpty
          ? 'Nobody in this formation fits the pattern from here.'
          : '${carrier.number} on the ball. Watch: ${names.join(', ')}.',
    );
  }
}
