import 'dart:math' as math;

/// Plain maths helpers with no game knowledge.

/// Clamps a double without the `num` return type of `num.clamp`.
double clampD(double v, double lo, double hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

/// -1, 0 or 1.
double signD(double v) => v > 0 ? 1.0 : (v < 0 ? -1.0 : 0.0);

/// Squared distance from point P to the segment A→B.
double pointSegmentDist2(
  double px,
  double py,
  double ax,
  double ay,
  double bx,
  double by,
) {
  final abx = bx - ax;
  final aby = by - ay;
  final len2 = abx * abx + aby * aby;
  double t = 0.0;
  if (len2 > 1e-9) {
    t = clampD(((px - ax) * abx + (py - ay) * aby) / len2, 0.0, 1.0);
  }
  final cx = ax + abx * t;
  final cy = ay + aby * t;
  final dx = px - cx;
  final dy = py - cy;
  return dx * dx + dy * dy;
}

/// How far along A→B (0..1) the closest point to P is.
double projectOnSegment(
  double px,
  double py,
  double ax,
  double ay,
  double bx,
  double by,
) {
  final abx = bx - ax;
  final aby = by - ay;
  final len2 = abx * abx + aby * aby;
  if (len2 < 1e-9) return 0.0;
  return clampD(((px - ax) * abx + (py - ay) * aby) / len2, 0.0, 1.0);
}

/// Unsigned angle in radians between two direction vectors.
double angleBetween(double ax, double ay, double bx, double by) {
  final la = math.sqrt(ax * ax + ay * ay);
  final lb = math.sqrt(bx * bx + by * by);
  if (la < 1e-9 || lb < 1e-9) return math.pi;
  final c = clampD((ax * bx + ay * by) / (la * lb), -1.0, 1.0);
  return math.acos(c);
}

const double degToRad = math.pi / 180.0;
