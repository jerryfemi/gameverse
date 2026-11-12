import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/brain/patterns/library.dart';
import 'package:tiki_core/brain/patterns/pattern.dart';
import 'package:tiki_core/brain/perception/team_view.dart';
import 'package:tiki_core/model/disc.dart';

/// Starts patterns when their trigger is true, hands out the parts, feeds
/// the parts' moves to the brain, and ends them.
///
/// A pattern ends when time runs out, the ball is lost, or the ball
/// reaches one of its parts (counted as "pattern runs found").
class PatternDirector {
  final List<Pattern> library;
  final Map<String, double> _cooldown = {};

  Pattern? _active;
  final List<int> _partDiscs = [];
  int _startCarrier = -1;
  double _time = 0.0;
  TeamView? _view;

  PatternDirector({List<Pattern>? library})
    : library = library ?? PatternLibrary.all;

  String? get activeLabel => _active?.label;

  void update(TeamView v, double dt) {
    _view = v;
    for (final k in _cooldown.keys.toList()) {
      _cooldown[k] = _cooldown[k]! - dt;
    }
    final active = _active;
    if (active != null) {
      _time += dt;
      final carrier = v.carrier;
      final reachedPart = carrier != null &&
          carrier.id != _startCarrier &&
          _partDiscs.contains(carrier.id);
      if (reachedPart) v.team.stats.patternRuns++;
      if (reachedPart || !v.weHaveBall || _time > active.duration) _end();
      return;
    }
    final carrier = v.carrier;
    if (!v.weHaveBall || carrier == null || v.s.setPiece != null) return;
    for (final p in library) {
      if (!p.allowedFor(v.team.plan)) continue;
      if ((_cooldown[p.id] ?? 0.0) > 0.0) continue;
      if (!p.trigger(v, carrier)) continue;
      if (_start(v, p, carrier)) return;
    }
  }

  bool _start(TeamView v, Pattern p, Disc carrier) {
    final taken = <int>{};
    final picks = <int>[];
    for (final part in p.parts) {
      final d = part.pick(v, carrier, taken);
      if (d == null) return false;
      taken.add(d.id);
      picks.add(d.id);
    }
    _active = p;
    _partDiscs
      ..clear()
      ..addAll(picks);
    _startCarrier = carrier.id;
    _time = 0.0;
    _cooldown[p.id] = p.cooldown;
    return true;
  }

  void _end() {
    _active = null;
    _partDiscs.clear();
  }

  /// The move for [d] if it plays a part in the running pattern.
  Candidate? candidateFor(Disc d) {
    final p = _active;
    final v = _view;
    final carrier = v?.carrier;
    if (p == null || v == null || carrier == null) return null;
    final i = _partDiscs.indexOf(d.id);
    if (i < 0 || d.id == carrier.id) return null;
    final part = p.parts[i];
    final at = part.move(v, carrier, d);
    if (at == null) return null;
    return patternCandidate(p, part, at.x, at.y);
  }
}
