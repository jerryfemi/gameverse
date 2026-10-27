import 'dart:ui';
import 'package:flame/components.dart';
import 'package:b_ball/paintball/logic/ball_trajectory.dart';

/// Active in-flight paintball component driven by [BallTrajectory].
class FlyingPaintball extends Component {
  final BallTrajectory trajectory = BallTrajectory();
  Color ballColor = const Color(0xFFEC4899);
  double baseRadius = 8.0;

  bool isActive = false;
  void Function(FlyingPaintball ball)? onLanding;

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
    double baseRadius = 8.0,
    double arcHeight = 50.0,
    void Function(FlyingPaintball ball)? onLanding,
  }) {
    ballColor = color;
    this.baseRadius = baseRadius;
    this.onLanding = onLanding;
    isActive = true;

    trajectory.setup(
      startX: startX,
      startY: startY,
      targetX: targetX,
      targetY: targetY,
      arcHeight: arcHeight,
    );
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
