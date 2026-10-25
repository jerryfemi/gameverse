import 'dart:math' as math;
import 'package:flutter/physics.dart';

/// Damping ratio 1.0 = no overshoot. Response ≈ settle speed in seconds.
SpringDescription spring({double response = 0.35, double dampingRatio = 1.0}) {
  final stiffness = math.pow(2 * math.pi / response, 2).toDouble();
  final damping = 4 * math.pi * dampingRatio / response;
  return SpringDescription(mass: 1, stiffness: stiffness, damping: damping);
}

const (double, double) kSnappy = (0.30, 1.0); // chips, peek card
const (double, double) kSheet = (0.35, 1.0); // panels, sheets
const (double, double) kFling = (0.35, 0.82); // only after a drag/fling release

extension SpringPairExt on (double, double) {
  double get response => $1;
  double get dampingRatio => $2;
  SpringDescription toDescription() => spring(response: $1, dampingRatio: $2);
}
