import 'dart:math' as math;

/// Seeded random numbers. **Never use `Random()` directly in the sim.**
///
/// Same seed + same inputs = same match. That makes bugs repeatable,
/// tests stable, and (later) previews and replays exact.
class Rng {
  final math.Random _r;

  Rng(int seed) : _r = math.Random(seed);

  /// 0 ≤ value < 1
  double next() => _r.nextDouble();

  double range(double lo, double hi) => lo + (hi - lo) * _r.nextDouble();

  bool chance(double p) => _r.nextDouble() < p;

  /// Rough bell curve around 0 (mostly between -1 and 1, rarely up to ±1.5).
  /// Sum of three uniforms: cheap and good enough for aim error.
  double bell() => (_r.nextDouble() + _r.nextDouble() + _r.nextDouble()) - 1.5;

  int nextInt(int max) => _r.nextInt(max);
}
