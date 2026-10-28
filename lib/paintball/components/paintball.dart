import 'dart:ui';
import 'package:flame/components.dart';
import 'package:b_ball/paintball/logic/ball_trajectory.dart';
import 'package:b_ball/paintball/paintball_constants.dart';

/// Active in-flight paintball component driven by [BallTrajectory].
class FlyingPaintball extends Component {
  final BallTrajectory trajectory = BallTrajectory();
  Color ballColor = const Color(0xFFEC4899);
  double baseRadius = 8.0;

  bool isActive = false;
  void Function(FlyingPaintball ball)? onLanding;

  // ─── Shot data captured at fire time (read by the target-side hit check) ──
  /// True if the local player fired this ball, false if the opponent did.
  bool firedByYou = true;

  /// Shooter's aim across the field on the shooter's own screen, -1..1.
  double aimX = 0.0;

  /// Online: the RTDB shot id this ball belongs to (null in bot mode).
  String? shotId;

  /// Shooter's aim height, 0 (ground) .. 1 (head).
  double aimY = 0.65;

  // ─── Pre-allocated Paints ─────────────────────────────────────────────────
  final Paint _ballPaint = Paint()..isAntiAlias = true;
  final Paint _specularPaint = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..isAntiAlias = true;

  final Paint _shadowPaint = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  FlyingPaintball({this.onLanding}) : super(priority: 40);

  void launch({
    required double startX,
    required double startY,
    required double targetX,
    required double targetY,
    required Color color,
    required bool firedByYou,
    required double aimX,
    required double aimY,
    double startScale = PaintballK.ballStartScale,
    double endScale = PaintballK.ballEndScale,
    double baseRadius = 8.0,
    double arcHeight = 50.0,
    String? shotId,
    double elapsed = 0.0,
  }) {
    this.shotId = shotId;
    ballColor = color;
    this.baseRadius = baseRadius;
    this.firedByYou = firedByYou;
    this.aimX = aimX;
    this.aimY = aimY;
    isActive = true;

    trajectory.setup(
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      arcHeight: arcHeight,
      startScale: startScale,
      endScale: endScale,
    );
    // A shot that arrived late over the network starts part-way through.
    if (elapsed > 0.0) trajectory.update(elapsed);
  }

  /// Removes the ball from play without resolving it (used on rematch).
  void cancel() {
    isActive = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;

    trajectory.update(dt);

    if (trajectory.isCompleted) {
      isActive = false;
      onLanding?.call(this);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    final cx = trajectory.x;
    final cy = trajectory.y;
    final r = baseRadius * trajectory.scale;

    // Subtle drop shadow below ball
    final shadowY = cy + (r * 1.5 * (1.0 - trajectory.z));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, shadowY),
        width: r * 1.6,
        height: r * 0.7,
      ),
      _shadowPaint,
    );

    // Ball glossy sphere
    _ballPaint.shader = Gradient.radial(
      Offset(cx - r * 0.3, cy - r * 0.3),
      r * 1.2,
      [
        const Color(0xFFFFFFFF),
        ballColor,
        ballColor.withValues(alpha: 0.85),
      ],
      const [0.0, 0.45, 1.0],
    );

    canvas.drawCircle(Offset(cx, cy), r, _ballPaint);

    // Specular highlight spot
    canvas.drawCircle(
      Offset(cx - r * 0.35, cy - r * 0.35),
      r * 0.28,
      _specularPaint,
    );
  }
}
