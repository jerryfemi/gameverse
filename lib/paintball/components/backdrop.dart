import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:b_ball/paintball/paintball_constants.dart';

/// Pre-rendered paintball field (`assets/paintball/paintball_env_<arena>.json`).
///
/// Three images rendered from a 3D scene with a camera matched to the game's
/// layout (see PaintballK.farGroundY / oppStandHeight / nearGroundY /
/// youStandHeight), so the tyres and players stand on the rendered ground:
/// - **sky**: sky, clouds, hills, tree line. Moves like the old backdrop.
/// - **ground**: grass and worn mud under the lanes, drawn in horizontal strips.
///   Each strip moves at the rate of whatever stands at that screen height, so
///   it stays locked to both tyre rows as the camera pans and dips.
/// - **props**: netting, barrels, sandbags, pallets around the field.
///
/// Every rect is computed on resize; render() only translates and draws.
class PaintballBackdrop extends Component with HasGameReference {
  PaintballBackdrop({this.arena = 'field'});

  /// Arena id: loads `paintball_env_<arena>.json`. Other arenas (e.g. the
  /// London arches) are new layer sets with the same layout.
  final String arena;

  double cameraPanOffset = 0.0;
  double cameraDipOffset = 0.0;

  static const int _strips = 64;

  static final Images _images = Images(prefix: 'assets/');

  Image? _sky, _ground, _props;
  double _refH = 1000, _refW = 3200, _horizon = 303;
  double _groundY = 303, _propsY = 0, _propsGroundFrac = 0.465;

  // Layout cache (rebuilt when the screen size changes).
  double _lastW = -1, _lastH = -1;
  Rect _skySrc = Rect.zero, _skyDst = Rect.zero;
  Rect _propsSrc = Rect.zero, _propsDst = Rect.zero;
  final List<Rect> _stripSrc = List.filled(_strips, Rect.zero);
  final List<Rect> _stripDst = List.filled(_strips, Rect.zero);
  final List<double> _stripPanK = List.filled(_strips, 1.0);
  final List<double> _stripDipK = List.filled(_strips, 1.0);
  double _propsPanK = PaintballK.parallaxFarTires;
  double _propsDipK = PaintballK.parallaxFarTiresY;
  Rect _fillSky = Rect.zero, _fillGround = Rect.zero;

  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _skyFill = Paint()..color = const Color(0xFF7FB2E0);
  final Paint _grassFill = Paint()..color = const Color(0xFF4C7A30);

  @override
  int get priority => 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final j = jsonDecode(
      await rootBundle.loadString('assets/paintball/paintball_env_$arena.json'),
    ) as Map<String, dynamic>;
    _refH = (j['refHeight'] as num).toDouble();
    _refW = (j['width'] as num).toDouble();
    _horizon = (j['horizonY'] as num).toDouble();
    final g = j['ground'] as Map<String, dynamic>;
    final p = j['props'] as Map<String, dynamic>;
    _groundY = (g['y'] as num).toDouble();
    _propsY = (p['y'] as num).toDouble();
    _propsGroundFrac = (p['groundY'] as num).toDouble();
    final images = await Future.wait([
      _images.load('paintball/${(j['sky'] as Map)['image']}'),
      _images.load('paintball/${g['image']}'),
      _images.load('paintball/${p['image']}'),
    ]);
    _sky = images[0];
    _ground = images[1];
    _props = images[2];
  }

  /// Parallax rates for something standing at screen height [yFrac]
  /// (fraction of screen height). On flat ground the rate is linear in screen
  /// height, so this line through the far row (farGroundY -> parallaxFarTires)
  /// and your row (nearTyreGroundY -> 1.0) is exact for everything on it.
  static double panRateAt(double yFrac) => _line(yFrac, PaintballK.parallaxFarTires);
  static double dipRateAt(double yFrac) => _line(yFrac, PaintballK.parallaxFarTiresY);

  static double _line(double yFrac, double farRate) {
    const y0 = PaintballK.farGroundY, y1 = PaintballK.nearTyreGroundY;
    return farRate + (1.0 - farRate) * (yFrac - y0) / (y1 - y0);
  }

  void _layout(double w, double h) {
    _lastW = w;
    _lastH = h;
    final s = h / _refH;
    final x0 = w * 0.5 - _refW * 0.5 * s;
    final imgW = _refW * s;

    final sky = _sky!, ground = _ground!, props = _props!;
    _skySrc = Rect.fromLTWH(0, 0, sky.width.toDouble(), sky.height.toDouble());
    _skyDst = Rect.fromLTWH(x0, 0, imgW, sky.height * s);

    _propsSrc = Rect.fromLTWH(0, 0, props.width.toDouble(), props.height.toDouble());
    _propsDst = Rect.fromLTWH(x0, _propsY * s, imgW, props.height * s);
    _propsPanK = panRateAt(_propsGroundFrac);
    _propsDipK = dipRateAt(_propsGroundFrac);

    // Strips from the horizon down; each a hair taller so no seams show.
    final gh = ground.height.toDouble();
    final stripH = gh / _strips;
    for (var i = 0; i < _strips; i++) {
      final sy = i * stripH;
      _stripSrc[i] = Rect.fromLTWH(0, sy, ground.width.toDouble(), stripH + 1);
      _stripDst[i] = Rect.fromLTWH(x0, (_groundY + sy) * s, imgW, (stripH + 1) * s);
      final mid = (_groundY + sy + stripH * 0.5) / _refH;
      // Above the horizon nothing is on the ground; clamp to the horizon rate.
      final y = math.max(mid, _horizon / _refH);
      _stripPanK[i] = panRateAt(y);
      _stripDipK[i] = dipRateAt(y);
    }

    // Plain fills behind everything for windows wider than the images.
    _fillSky = Rect.fromLTWH(-w, -h, w * 3, h + _horizon * s);
    _fillGround = Rect.fromLTWH(-w, _horizon * s, w * 3, h * 2);
  }

  @override
  void render(Canvas canvas) {
    final sky = _sky, ground = _ground, props = _props;
    if (sky == null || ground == null || props == null) return;
    final size = game.size;
    if (size.x <= 0 || size.y <= 0) return;
    if (size.x != _lastW || size.y != _lastH) _layout(size.x, size.y);

    final pan = cameraPanOffset, dip = cameraDipOffset;

    canvas.drawRect(_fillSky, _skyFill);
    canvas.drawRect(_fillGround, _grassFill);

    // 1. Sky, hills, tree line.
    canvas.save();
    canvas.translate(pan * PaintballK.parallaxBackdrop, -dip * PaintballK.parallaxBackdropY);
    canvas.drawImageRect(sky, _skySrc, _skyDst, _paint);
    canvas.restore();

    // 2. Ground strips, far to near (nearer strips may overlap farther ones).
    for (var i = 0; i < _strips; i++) {
      canvas.save();
      canvas.translate(pan * _stripPanK[i], -dip * _stripDipK[i]);
      canvas.drawImageRect(ground, _stripSrc[i], _stripDst[i], _paint);
      canvas.restore();
    }

    // 3. Props around the field.
    canvas.save();
    canvas.translate(pan * _propsPanK, -dip * _propsDipK);
    canvas.drawImageRect(props, _propsSrc, _propsDst, _paint);
    canvas.restore();
  }
}
