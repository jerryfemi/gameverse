import 'dart:convert';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:b_ball/paintball/paintball_constants.dart';

/// One view of the pre-rendered 4-tyre stack (`assets/paintball/paintball_tyres_*.webp`).
class TyreStackSprite {
  final Image image;
  final Rect src;

  /// Image-pixel y of the top-front lip of the stack (the cover line).
  final double coverY;

  /// Image-pixel y where the front of the bottom tyre meets the ground.
  final double groundY;

  /// Image-pixel x of the stack's centre.
  final double centerX;

  const TyreStackSprite(this.image, this.src, this.coverY, this.groundY, this.centerX);

  double get width => src.width;
}

/// Loads both tyre-stack views once.
class TyreStackSprites {
  final TyreStackSprite near;
  final TyreStackSprite far;
  const TyreStackSprites(this.near, this.far);

  static final Images _images = Images(prefix: 'assets/');
  static Future<TyreStackSprites>? _future;

  static Future<TyreStackSprites> load() => _future ??= _load();

  static Future<TyreStackSprites> _load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/paintball/paintball_tyres.json'),
    ) as Map<String, dynamic>;
    Future<TyreStackSprite> view(String key) async {
      final j = json[key] as Map<String, dynamic>;
      final img = await _images.load('paintball/${j['image']}');
      return TyreStackSprite(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        (j['coverY'] as num).toDouble(),
        (j['groundY'] as num).toDouble(),
        (j['centerX'] as num).toDouble(),
      );
    }

    return TyreStackSprites(await view('near'), await view('far'));
  }
}

/// One 4-tyre defensive stack positioned in a specific lane.
///
/// Layout contract (set by [PaintballGame]): the component's box is
/// `position` (top-left) + `size`.
/// - **Far** stacks: the box top is the cover line and the box bottom is the
///   ground. The sprite is scaled so its top-front lip lands exactly on the
///   cover line, which is what [PaintballK.tyreCoverHeight] and the hit rules
///   assume.
/// - **Near** stacks: same contract; the visible top surface draws a little
///   above the box.
///
/// Odd lanes are mirrored so the five stacks don't look copy-pasted.
class TyreStackComponent extends PositionComponent with HasGameReference {
  final int lane;
  final bool isNear;
  double cameraPanOffset = 0.0;
  double cameraDipOffset = 0.0;

  TyreStackSprite? _sprite;

  // Destination rect, recomputed only when the box size changes.
  Rect _dst = Rect.zero;
  double _lastW = -1;
  double _lastH = -1;

  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _shadowPaint = Paint()..color = const Color(0x38000000);
  Rect _shadow = Rect.zero;

  TyreStackComponent({
    required this.lane,
    required this.isNear,
  }) : super(priority: isNear ? 50 : 25);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final sprites = await TyreStackSprites.load();
    _sprite = isNear ? sprites.near : sprites.far;
  }

  void _layout(TyreStackSprite s) {
    final w = size.x, h = size.y;
    _lastW = w;
    _lastH = h;
    final double scale;
    final double top;
    // Both views: the box top is the cover line and the box bottom is the
    // ground, so the stack is sized by height and never by lane width.
    scale = h / (s.groundY - s.coverY);
    top = -s.coverY * scale;
    final left = w * 0.5 - s.centerX * scale;
    _dst = Rect.fromLTWH(left, top, s.width * scale, s.src.height * scale);
    final sw = s.width * scale * 0.95;
    _shadow = Rect.fromCenter(center: Offset(w * 0.5, h), width: sw, height: sw * 0.16);
  }

  @override
  void render(Canvas canvas) {
    final s = _sprite;
    if (s == null) return;
    if (size.x != _lastW || size.y != _lastH) _layout(s);

    final shiftX = cameraPanOffset * (isNear ? 1.0 : PaintballK.parallaxFarTires);
    final shiftY = -cameraDipOffset * (isNear ? 1.0 : PaintballK.parallaxFarTiresY);

    canvas.save();
    canvas.translate(shiftX, shiftY);
    canvas.drawOval(_shadow, _shadowPaint);
    if (lane.isOdd) {
      // Mirror around the box centre for variety.
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(s.image, s.src, _dst, _paint);
    canvas.restore();
  }
}
