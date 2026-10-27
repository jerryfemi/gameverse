import 'package:b_ball/paintball/paintball_constants.dart';

/// Deterministic 2.5D ballistic trajectory solver for a paintball.
///
/// Models a smooth 400 ms arc from shooter muzzle $(x_0, y_0, z=0)$ to the
/// far target coordinate $(x_1, y_1, z=1)$.
///
/// Designed with zero runtime allocations so that Flame components and network
/// listeners can evaluate positions at 60–120 fps without triggering GC pauses.
class BallTrajectory {
  // ─── Trajectory Boundary Coordinates ─────────────────────────────────────
  double startX = 0.0;
  double startY = 0.0;
  double targetX = 0.0;
  double targetY = 0.0;

  /// Maximum upward arc bulge in pixels (screen space: up is negative Y).
  double arcHeight = 45.0;

  /// Starting scale at launch (near camera).
  double startScale = PaintballK.ballStartScale;

  /// Ending scale at impact (far plane).
  double endScale = PaintballK.ballEndScale;

  // ─── Timing Parameters ────────────────────────────────────────────────────
  /// Total flight duration in seconds (default 0.40 s).
  double durationSeconds = PaintballK.ballFlightSeconds;

  /// Launch timestamp in milliseconds (synced server timestamp or local elapsed).
  int launchTimestampMs = 0;

  // ─── Evaluated Current State (Zero Allocation Cache) ──────────────────────
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;
  double scale = 1.0;
  double progress = 0.0;
  bool isCompleted = false;

  /// Initializes or resets the trajectory for a new shot.
  void setup({
    required double startX,
    required double startY,
    required double targetX,
    required double targetY,
    double? arcHeight,
    double? startScale,
    double? endScale,
    double durationSeconds = PaintballK.ballFlightSeconds,
    int launchTimestampMs = 0,
  }) {
    this.startX = startX;
    this.startY = startY;
    this.targetX = targetX;
    this.targetY = targetY;
    this.arcHeight = arcHeight ?? 45.0;
    this.startScale = startScale ?? PaintballK.ballStartScale;
    this.endScale = endScale ?? PaintballK.ballEndScale;
    this.durationSeconds = durationSeconds;
    this.launchTimestampMs = launchTimestampMs;

    progress = 0.0;
    x = startX;
    y = startY;
    z = 0.0;
    scale = this.startScale;
    isCompleted = false;
  }

  /// Evaluates trajectory position given normalized [t] in range [0.0, 1.0].
  ///
  /// Updates [x], [y], [z], [scale], [progress], and [isCompleted] in-place.
  void evaluate(double t) {
    final clamped = t.clamp(0.0, 1.0);
    progress = clamped;

    // Linear horizontal interpolation
    x = startX + (targetX - startX) * clamped;

    // Parabolic vertical arc: 4 * h * t * (1 - t) peaks at t = 0.5 with height h.
    // In screen coordinates, subtracting arcHeight pulls the ball visually upward.
    final arcOffset = 4.0 * arcHeight * clamped * (1.0 - clamped);
    final linearY = startY + (targetY - startY) * clamped;
    y = linearY - arcOffset;

    // Linear depth (0.0 near -> 1.0 far)
    z = clamped;

    // Perspective scale reduction
    scale = startScale + (endScale - startScale) * clamped;

    isCompleted = clamped >= 1.0;
  }

  /// Steps forward by elapsed time in seconds.
  void update(double dt) {
    if (isCompleted || durationSeconds <= 0.0) {
      isCompleted = true;
      return;
    }
    final nextProgress = progress + (dt / durationSeconds);
    evaluate(nextProgress);
  }

  /// Evaluates trajectory based on an absolute millisecond timestamp.
  ///
  /// Useful for network-synchronized shots where [currentTimestampMs] is synced
  /// with Firebase Realtime Database server offset.
  void syncToTimestamp(int currentTimestampMs) {
    if (launchTimestampMs <= 0) return;
    final elapsedMs = currentTimestampMs - launchTimestampMs;
    final totalMs = (durationSeconds * 1000).toInt();
    if (totalMs <= 0) {
      evaluate(1.0);
      return;
    }
    final t = elapsedMs / totalMs;
    evaluate(t);
  }

  /// Calculates the peak height achieved during flight (at t = 0.5).
  double get peakY {
    final midLinearY = (startY + targetY) * 0.5;
    return midLinearY - arcHeight;
  }
}
