import 'dart:math' as math;

/// A small 2D vector in metres (or any unit).
///
/// It is **mutable on purpose**: the simulation updates the same vectors
/// 60 times a second instead of creating new ones, so the garbage collector
/// never has to step in during a match (project rule: no allocation in hot
/// loops). Use [clone] only outside the per-tick code.
class Vec2 {
  double x;
  double y;

  Vec2([this.x = 0.0, this.y = 0.0]);

  Vec2 clone() => Vec2(x, y);

  void set(double nx, double ny) {
    x = nx;
    y = ny;
  }

  void setFrom(Vec2 o) {
    x = o.x;
    y = o.y;
  }

  void setZero() {
    x = 0.0;
    y = 0.0;
  }

  double get length => math.sqrt(x * x + y * y);

  double get length2 => x * x + y * y;

  double distTo(Vec2 o) {
    final dx = o.x - x;
    final dy = o.y - y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double dist2To(Vec2 o) {
    final dx = o.x - x;
    final dy = o.y - y;
    return dx * dx + dy * dy;
  }

  /// Makes the length 1 (leaves a zero vector alone).
  void normalize() {
    final l = length;
    if (l > 1e-9) {
      x /= l;
      y /= l;
    }
  }

  void scale(double s) {
    x *= s;
    y *= s;
  }

  void add(Vec2 o) {
    x += o.x;
    y += o.y;
  }

  /// `this += o * s`
  void addScaled(Vec2 o, double s) {
    x += o.x * s;
    y += o.y * s;
  }

  double dot(Vec2 o) => x * o.x + y * o.y;

  /// Rotates by [radians] (positive = counter-clockwise in maths axes).
  void rotate(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    final nx = x * c - y * s;
    y = x * s + y * c;
    x = nx;
  }

  bool get isFinite => x.isFinite && y.isFinite;

  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}
