import 'dart:math' as math;

import 'package:tiki_core/brain/candidate.dart';
import 'package:tiki_core/core/tunables.dart';
import 'package:tiki_core/model/disc.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Picks a disc's job from its candidates: highest (score × role weight)
/// wins — but a job the disc already committed to is kept unless the new
/// best is clearly better. That stops discs flickering between ideas.
abstract final class JobPicker {
  static void choose(
    Disc d,
    List<Candidate> candidates,
    RolePreset role,
    double dt,
  ) {
    Candidate? best;
    var bestScore = -double.infinity;
    Candidate? current;
    var currentScore = -double.infinity;
    for (final c in candidates) {
      final kind = c.kind;
      final w = kind == null ? 1.0 : role.weight(kind);
      if (w <= 0.0) continue;
      final score = c.score * w;
      if (c.job == d.job) {
        current = c;
        currentScore = score;
      }
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }
    if (best == null) return;

    d.commitTimer = math.max(0.0, d.commitTimer - dt);
    var pick = best;
    if (current != null &&
        d.commitTimer > 0.0 &&
        bestScore < currentScore + T.jobSwitchMargin) {
      pick = current; // stay committed
    } else if (pick.job != d.job) {
      d.commitTimer = pick.commit; // new job: commit to it
    }

    d.target.set(pick.x, pick.y);
    d.urgency = pick.urgency;
    d.job = pick.job;
  }
}
