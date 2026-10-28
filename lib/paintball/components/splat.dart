import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

import 'package:b_ball/paintball/paintball_constants.dart';

/// One paint splat decal on a tyre stack or character.
///
/// Drawn from `assets/paintball/paintball_splats.webp`: 4 shapes x 2 colours
/// (pink row 0, blue row 1). Each cell is 128 x 176 with the impact point at
/// (64, 62); the drips run down the extra height below.
class SplatDecal {
  double x = 0.0;
  double y = 0.0;
  double radius = 12.0;
  double opacity = 1.0;
  double lifetime = 0.0;
  double age = 0.0;
  bool isActive = false;

  /// True for splats on your side (your tyres / your body); they move with the
  /// near layer instead of the far one.
  bool isNear = false;

  /// Index into the splat sheet's source rects (row * 4 + shape).
  int cell = 0;

  /// Mirror horizontally for variety (drips must stay pointing down).
  bool flip = false;
}

/// Canvas component that manages and renders pooled paint splats.
class SplatCanvasComponent extends Component {
  static const int maxSplats = 32;

  static const double _cellW = 128.0;
  static const double _cellH = 176.0;
  static const double _impactX = 64.0;
  static const double _impactY = 62.0;

  /// Radius of the main blob in the sheet, px.
  static const double _blobRadius = 26.0;

  /// How long a splat stays before fading (seconds), and the fade length.
  static const double _lifetime = 14.0;
  static const double _fadeSeconds = 2.0;

  /// Quick "pop" when the ball bursts: grows from 70% over 90 ms.
  static const double _popSeconds = 0.09;

  final List<SplatDecal> _splats = List.generate(maxSplats, (_) => SplatDecal());
  int _nextIndex = 0;
  final math.Random _rng = math.Random();

  static final Images _images = Images(prefix: 'assets/');
  Image? _sheet;

  // Precomputed once; no allocation while rendering.
  final List<Rect> _src = List.generate(
    8,
    (i) => Rect.fromLTWH((i % 4) * _cellW, (i ~/ 4) * _cellH, _cellW, _cellH),
    growable: false,
  );
  static const Rect _dstLocal = Rect.fromLTWH(-_impactX, -_impactY, _cellW, _cellH);

  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _fadePaint = Paint()..filterQuality = FilterQuality.medium;

  final int drawPriority;
  double cameraPanOffset = 0.0;
  double cameraDipOffset = 0.0;

  SplatCanvasComponent({this.drawPriority = 45});

  @override
  int get priority => drawPriority;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sheet = await _images.load('paintball/paintball_splats.webp');
  }

  /// Spawns a new splat centred on (x, y), in unshifted layer coordinates.
  void addSplat({
    required double x,
    required double y,
    required Color color,
    double radius = 12.0,
    bool near = false,
  }) {
    final s = _splats[_nextIndex];
    s
      ..x = x
      ..y = y
      ..radius = radius
      ..isNear = near
      ..opacity = 1.0
      ..lifetime = _lifetime
      ..age = 0.0
      ..isActive = true
      ..flip = _rng.nextBool();
    // Blue team colour uses row 1; everything else (pink) row 0.
    final row = color.b > color.r ? 1 : 0;
    s.cell = row * 4 + _rng.nextInt(4);
    _nextIndex = (_nextIndex + 1) % maxSplats;
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final s in _splats) {
      if (!s.isActive) continue;
      s.age += dt;
      s.lifetime -= dt;
      if (s.lifetime <= 0.0) {
        s.isActive = false;
      } else if (s.lifetime < _fadeSeconds) {
        s.opacity = s.lifetime / _fadeSeconds;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final sheet = _sheet;
    if (sheet == null) return;

    final farX = cameraPanOffset * PaintballK.parallaxFarTires;
    final farY = -cameraDipOffset * PaintballK.parallaxFarTiresY;
    final nearX = cameraPanOffset;
    final nearY = -cameraDipOffset;

    for (final s in _splats) {
      if (!s.isActive) continue;

      final pop = s.age >= _popSeconds ? 1.0 : 0.7 + 0.3 * (s.age / _popSeconds);
      final scale = (s.radius / _blobRadius) * pop;

      final Paint paint;
      if (s.opacity < 1.0) {
        _fadePaint.color = Color.fromRGBO(255, 255, 255, s.opacity);
        paint = _fadePaint;
      } else {
        paint = _paint;
      }

      canvas.save();
      canvas.translate(
        s.x + (s.isNear ? nearX : farX),
        s.y + (s.isNear ? nearY : farY),
      );
      canvas.scale(s.flip ? -scale : scale, scale);
      canvas.drawImageRect(sheet, _src[s.cell], _dstLocal, paint);
      canvas.restore();
    }
  }

  void clear() {
    for (final s in _splats) {
      s.isActive = false;
    }
  }
}
