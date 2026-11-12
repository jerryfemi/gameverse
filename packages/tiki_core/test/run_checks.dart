import 'dart:io';

import 'ball_physics_checks.dart';
import 'full_match_checks.dart';
import 'harness.dart';
import 'offside_checks.dart';
import 'passing_checks.dart';
import 'restarts_checks.dart';

/// Runs every engine check. From packages/tiki_core:
///
///   dart run test/run_checks.dart
void main() {
  print('Ball physics');
  ballPhysicsChecks();
  print('Passing');
  passingChecks();
  print('Restarts');
  restartsChecks();
  print('Offside');
  offsideChecks();
  print('Full matches (bots)');
  fullMatchChecks();
  exitCode = report() == 0 ? 0 : 1;
}
