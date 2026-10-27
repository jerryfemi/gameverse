import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

/// One paint splat decal on a tire stack or character.
class SplatDecal {
  double x = 0.0;
  double y = 0.0;
  double radius = 12.0;
  Color color = const Color(0xFFEC4899);
  double opacity = 1.0;
  double lifetime = 12.0; // visible for 12 seconds
  bool isActive = false;

  final List<Offset> _dropletOffsets = [];
  final List<double> _dropletRadii = [];

  void spawn({
    required double x,
    required double y,
    required Color color,
    double radius = 12.0,
    math.Random? rng,
  }) {
    this.x = x;
    this.y = y;
    this.color = color;
    this.radius = radius;
    opacity = 1.0;
    lifetime = 12.0;
    isActive = true;

    final r = rng ?? math.Random();
    _dropletOffsets.clear();
    _dropletRadii.clear();

    final dropletCount = 4 + r.nextInt(3);
    for (int i = 0; i < dropletCount; i++) {
      final angle = r.nextDouble() * 2 * math.pi;
      final dist = radius * (1.1 + r.nextDouble() * 0.9);
      _dropletOffsets.add(Offset(math.cos(angle) * dist, math.sin(angle) * dist));
      _dropletRadii.add(radius * (0.2 + r.nextDouble() * 0.25));
    }
  }

  void update(double dt) {
    if (!isActive) return;
    lifetime -= dt;
    if (lifetime <= 0.0) {
      isActive = false;
      return;
    }
    // Fade out over last 2 seconds
    if (lifetime < 2.0) {
      opacity = (lifetime / 2.0).clamp(0.0, 1.0);
    }
  }

  void render(Canvas canvas, Paint paint) {
    if (!isActive || opacity <= 0.0) return;

    paint.color = color.withValues(alpha: opacity);
    // Center blob
    canvas.drawCircle(Offset(x, y), radius, paint);

    // Droplets
    for (int i = 0; i < _dropletOffsets.length; i++) {
      canvas.drawCircle(
        Offset(x + _dropletOffsets[i].dx, y + _dropletOffsets[i].dy),
        _dropletRadii[i],
        paint,
      );
    }
  }
}

/// Canvas component that manages and renders pooled paint splats.
class SplatCanvasComponent extends Component {
  static const int maxSplats = 32;
  final List<SplatDecal> _splats = List.generate(maxSplats, (_) => SplatDecal());
  int _nextIndex = 0;

  final Paint _splatPaint = Paint()..isAntiAlias = true;

  final int drawPriority;

  SplatCanvasComponent({this.drawPriority = 45});

  @override
  int get priority => drawPriority;

  /// Spawns a new splat at (x, y) with specified color.
  void addSplat({
    required double x,
    required double y,
    required Color color,
    double radius = 12.0,
  }) {
    _splats[_nextIndex].spawn(
      x: x,
      y: y,
      color: color,
      radius: radius,
    );
    _nextIndex = (_nextIndex + 1) % maxSplats;
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final splat in _splats) {
      if (splat.isActive) {
        splat.update(dt);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final splat in _splats) {
      if (splat.isActive) {
        splat.render(canvas, _splatPaint);
      }
    }
  }

  void clear() {
    for (final splat in _splats) {
      splat.isActive = false;
    }
  }
}
