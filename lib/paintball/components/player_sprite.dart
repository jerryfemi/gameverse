import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';

/// Animation clips baked into the paintball player atlases
/// (see PAINTBALL_SPRITES.md). Names match the atlas JSON `clips` keys.
enum PaintballClip {
  stand,
  standL,
  standR,
  fire,
  fireL,
  fireR,
  crouch,
  crouchL,
  crouchR,
  duck,
  slideLeft,
  slideRight,
  hit,
  death,
  win,
  walk;

  String get key => switch (this) {
        PaintballClip.standL => 'stand_l',
        PaintballClip.standR => 'stand_r',
        PaintballClip.fireL => 'fire_l',
        PaintballClip.fireR => 'fire_r',
        PaintballClip.crouchL => 'crouch_l',
        PaintballClip.crouchR => 'crouch_r',
        PaintballClip.slideLeft => 'slide_left',
        PaintballClip.slideRight => 'slide_right',
        PaintballClip.walk => 'walk',
        _ => name,
      };
}

/// One clip of an atlas, with every rectangle precomputed so rendering
/// allocates nothing.
class PaintballClipFrames {
  /// Source rectangles in the atlas image, one per frame.
  final List<Rect> src;

  /// Destination rectangle in atlas pixels, relative to the ground anchor
  /// (the point under the player's feet). Same for every frame of the clip.
  final Rect dst;

  final double fps;
  final bool loop;

  const PaintballClipFrames({
    required this.src,
    required this.dst,
    required this.fps,
    required this.loop,
  });

  int get frameCount => src.length;
  double get duration => frameCount / fps;
}

/// A loaded player atlas (`paintball_back` or `paintball_front`).
///
/// Each clip has its own cell size and a ground anchor, so frames from any
/// clip line up when drawn at the same ground point.
class PaintballPlayerAtlas {
  final Image image;
  final List<PaintballClipFrames> clips; // indexed by PaintballClip.index

  /// Height of the standing pose above the ground anchor, in atlas pixels.
  /// Used to scale the sprite to a target standing height on screen.
  final double standHeightPx;

  PaintballPlayerAtlas._(this.image, this.clips, this.standHeightPx);

  PaintballClipFrames clip(PaintballClip c) => clips[c.index];

  static final Images _images = Images(prefix: 'assets/');
  static final Map<String, Future<PaintballPlayerAtlas>> _cache = {};

  /// Loads `assets/paintball/<name>_atlas.webp` + `.json` once and caches it.
  static Future<PaintballPlayerAtlas> load(String name) =>
      _cache.putIfAbsent(name, () => _load(name));

  static Future<PaintballPlayerAtlas> _load(String name) async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/paintball/${name}_atlas.json'),
    ) as Map<String, dynamic>;
    final image = await _images.load('paintball/${json['image']}');
    final clipsJson = json['clips'] as Map<String, dynamic>;
    final framesJson = json['frames'] as Map<String, dynamic>;

    final clips = <PaintballClipFrames>[];
    for (final c in PaintballClip.values) {
      var key = c.key;
      var cj = clipsJson[key] as Map<String, dynamic>?;
      if (cj == null && c == PaintballClip.walk) {
        // Stand-in while the atlas has no walk clip (PAINTBALL_GEMINI_NEXT Task A)
        key = PaintballClip.slideLeft.key;
        cj = clipsJson[key] as Map<String, dynamic>?;
      }
      if (cj == null) {
        throw StateError('Missing clip key: $key');
      }
      final n = (cj['frames'] as num).toInt();
      final cw = (cj['cellWidth'] as num).toDouble();
      final ch = (cj['cellHeight'] as num).toDouble();
      final ax = (cj['anchorX'] as num).toDouble();
      final ay = (cj['anchorY'] as num).toDouble();
      final src = <Rect>[];
      for (var i = 0; i < n; i++) {
        final f = framesJson['p1_${key}_$i'] as Map<String, dynamic>;
        src.add(Rect.fromLTWH(
          (f['x'] as num).toDouble(),
          (f['y'] as num).toDouble(),
          (f['w'] as num).toDouble(),
          (f['h'] as num).toDouble(),
        ));
      }
      clips.add(PaintballClipFrames(
        src: List.unmodifiable(src),
        dst: Rect.fromLTWH(-ax, -ay, cw, ch),
        fps: (cj['fps'] as num).toDouble(),
        loop: cj['loop'] as bool,
      ));
    }
    // The stand clip's anchor sits at the feet; its anchorY is the standing
    // height plus a few pixels of crop padding.
    final standHeight = clips[PaintballClip.stand.index].dst.top.abs() - 4.0;
    return PaintballPlayerAtlas._(image, List.unmodifiable(clips), standHeight);
  }
}

/// Coarse body outlines for every frame of every pose, from the FRONT view
/// (`assets/paintball/paintball_front_mask.json`, 8 px blocks). Hits are judged
/// the way the shooter sees the target: from the front.
class PaintballBodyMask {
  final PaintballPlayerAtlas front;
  final int block;
  final List<int> _cols; // per clip
  final List<int> _rows; // per clip
  /// [clip][frame][row] bitmask, bit i = block column i.
  final List<List<List<int>>> _bits;

  PaintballBodyMask._(this.front, this.block, this._cols, this._rows, this._bits);

  static Future<PaintballBodyMask>? _future;
  static Future<PaintballBodyMask> load() => _future ??= _load();

  static Future<PaintballBodyMask> _load() async {
    final front = await PaintballPlayerAtlas.load('paintball_front');
    final j = jsonDecode(
      await rootBundle.loadString('assets/paintball/paintball_front_mask.json'),
    ) as Map<String, dynamic>;
    final clips = j['clips'] as Map<String, dynamic>;
    final cols = <int>[], rows = <int>[];
    final bits = <List<List<int>>>[];
    for (final c in PaintballClip.values) {
      var cj = clips[c.key] as Map<String, dynamic>?;
      if (cj == null && c == PaintballClip.walk) cj = clips[PaintballClip.slideLeft.key] as Map<String, dynamic>?;
      if (cj == null) throw StateError('Missing mask clip: ${c.key}');
      cols.add((cj['cols'] as num).toInt());
      rows.add((cj['rows'] as num).toInt());
      bits.add(List.unmodifiable((cj['frames'] as List).map((f) => List<int>.unmodifiable(
            (f as List).map((r) => int.parse(r as String, radix: 16))))));
    }
    return PaintballBodyMask._(front, (j['block'] as num).toInt(), cols, rows, List.unmodifiable(bits));
  }

  /// True if the point ([dx], [y]) in standing heights from the feet
  /// (dx > 0 = right as the shooter sees it, y up) is on the body in
  /// [clip] / [frame]. Allocation-free.
  bool test(PaintballClip clip, int frame, double dx, double y) {
    final c = front.clip(clip);
    final f = _bits[clip.index];
    if (f.isEmpty) return false;
    final fr = f[frame.clamp(0, f.length - 1)];
    final stand = front.standHeightPx;
    final px = -c.dst.left + dx * stand;
    final py = -c.dst.top - y * stand;
    if (px < 0 || py < 0) return false;
    final col = px ~/ block, row = py ~/ block;
    if (col >= _cols[clip.index] || row >= _rows[clip.index]) return false;
    return (fr[row] >> col) & 1 == 1;
  }
}

/// One paint mark stuck on a player's body (front-view stand units).
class _BodySplat {
  double dx = 0, y = 0, age = 0;
  int cell = 0;
  bool flip = false;
  bool active = false;
}

/// Renders the local player (back view, foreground) or the opponent
/// (front view, far side) from the pre-rendered atlases.
///
/// Positioning contract (set by [PaintballGame]):
/// - [position] is the **ground point** under the player's feet, in screen px,
///   before camera parallax.
/// - [standHeight] is the on-screen height of the standing pose in px.
///
/// The stance poses (crouch, duck) are baked into the sprites, so the
/// component never moves the sprite down to fake a stance.
class PaintballPlayerComponent extends PositionComponent with HasGameReference {
  final bool isOpponent;
  final PaintballPlayerState state;

  double cameraPanOffset = 0.0;
  double cameraDipOffset = 0.0;

  /// On-screen height of the standing pose, px.
  double standHeight = 100.0;

  /// Upper-body aim direction, set by the game every frame.
  /// Positive turns towards the character's own left, negative to their right;
  /// 1.0 is two lanes off straight ahead. The _l / _r poses are ~26° turns.
  double aimTurn = 0.0;

  /// |aimTurn| beyond this picks the turned pose.
  static const double _turnThreshold = 0.3;

  /// Set by the game when the match ends.
  bool showWin = false;
  bool showDeath = false;

  /// Set by the game during the intro walk-in sequence.
  bool isWalking = false;

  PaintballPlayerAtlas? _atlas;
  PaintballBodyMask? _mask;

  // ─── Paint stuck on the body (hits) ───────────────────────────────────────
  static const int _maxBodySplats = 4;
  static const double _bodySplatSeconds = 3.0;
  static const double _bodySplatFade = 1.0;
  /// Blob radius of a body mark, in standing heights.
  static const double _bodySplatRadius = 0.075;
  final List<_BodySplat> _bodySplats = List.generate(_maxBodySplats, (_) => _BodySplat(), growable: false);
  int _nextBodySplat = 0;
  int _activeBodySplats = 0;
  static final Images _fxImages = Images(prefix: 'assets/');
  Image? _splatSheet;
  // Blob part of each splat cell (no drips): 128 x 104 from the 128 x 176 cell.
  final List<Rect> _blobSrc = List.generate(
    8,
    (i) => Rect.fromLTWH((i % 4) * 128.0, (i ~/ 4) * 176.0, 128, 104),
    growable: false,
  );
  static const Rect _blobDst = Rect.fromLTWH(-64, -62, 128, 104);
  final Paint _layerPaint = Paint();
  static const Color _opaque = Color(0xFFFFFFFF);
  final Paint _bodySplatPaint = Paint()
    ..blendMode = BlendMode.srcATop
    ..filterQuality = FilterQuality.medium;
  final math.Random _rng = math.Random();

  /// Current pose and frame (what the body outline test uses).
  PaintballClip get currentClip => _clip;
  int get currentFrame {
    final a = _atlas;
    return a == null ? 0 : _frameIndex(a.clip(_clip));
  }

  /// Is front-view point ([dx], [y]) (standing heights from the feet) on this
  /// player's body right now? False until the outlines have loaded.
  bool bodyAt(double dx, double y) => _mask?.test(_clip, currentFrame, dx, y) ?? false;

  /// Same test for a standing pose (for the "times dodged" stat).
  bool standingBodyAt(double dx, double y) => _mask?.test(PaintballClip.stand, 0, dx, y) ?? false;

  /// Sticks a paint mark on the body at front-view ([dx], [y]). It moves with
  /// the player, only shows on their pixels, and fades after 3 s.
  /// [blue] picks the blue paint row, otherwise pink.
  void addBodySplat(double dx, double y, {required bool blue}) {
    final s = _bodySplats[_nextBodySplat];
    if (!s.active) _activeBodySplats++;
    s
      ..dx = dx
      ..y = y
      ..age = 0
      ..flip = _rng.nextBool()
      ..cell = (blue ? 4 : 0) + _rng.nextInt(4)
      ..active = true;
    _nextBodySplat = (_nextBodySplat + 1) % _maxBodySplats;
  }

  void clearBodySplats() {
    for (final s in _bodySplats) {
      s.active = false;
    }
    _activeBodySplats = 0;
  }

  PaintballClip _clip = PaintballClip.stand;
  double _clipTime = 0.0;

  // One-shot triggers, detected from state counters changing.
  int _lastHitsTaken = 0;
  int _lastShotsFired = 0;
  double _hitTimer = 0.0;
  double _fireTimer = 0.0;
  double _flashClock = 0.0;

  static const double _hitSeconds = 0.6;
  static const double _fireSeconds = 0.25;
  static const double _slideFps = 22.0;

  // ─── Pre-allocated Paints ─────────────────────────────────────────────────
  final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final Paint _flashPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = const ColorFilter.mode(Color(0x88EF4444), BlendMode.srcATop);
  final Paint _shadowPaint = Paint()..color = const Color(0x40000000);

  /// Contact shadow, in atlas px relative to the ground anchor.
  Rect _shadowRect = Rect.zero;

  PaintballPlayerComponent({
    required this.isOpponent,
    required this.state,
  }) : super(priority: isOpponent ? 20 : 60);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final atlas = await PaintballPlayerAtlas.load(
      isOpponent ? 'paintball_front' : 'paintball_back',
    );
    _atlas = atlas;
    _mask = await PaintballBodyMask.load();
    _splatSheet = await _fxImages.load('paintball/paintball_splats.webp');
    final w = atlas.standHeightPx * 0.42;
    _shadowRect = Rect.fromCenter(
      center: Offset.zero,
      width: w,
      height: w * 0.22,
    );
    _lastHitsTaken = state.hitsTaken;
    _lastShotsFired = state.shotsFired;
  }

  /// Clears one-shot animations and end-of-match poses (rematch).
  void resetVisual() {
    showWin = false;
    showDeath = false;
    isWalking = false;
    _hitTimer = 0.0;
    _fireTimer = 0.0;
    _lastHitsTaken = state.hitsTaken;
    _lastShotsFired = state.shotsFired;
    clearBodySplats();
    _setClip(PaintballClip.stand);
  }

  /// Muzzle position on screen (before parallax), used to launch balls.
  /// [out] is written in place.
  void muzzle(Vector2 out) {
    final h = standHeight * _muzzleHeightFraction();
    out.setValues(
      position.x + standHeight * (isOpponent ? -0.06 : 0.12),
      position.y - h,
    );
  }

  double _muzzleHeightFraction() => switch (state.stance) {
        PaintballStance.stand => 0.82,
        PaintballStance.crouch => 0.58,
        PaintballStance.duck => 0.40,
      };

  void _setClip(PaintballClip c) {
    if (_clip == c) return;
    _clip = c;
    _clipTime = 0.0;
  }

  /// -1 = own right, 0 = straight, +1 = own left.
  int get _turnSide => aimTurn > _turnThreshold
      ? 1
      : (aimTurn < -_turnThreshold ? -1 : 0);

  PaintballClip _stanceClip() {
    final side = _turnSide;
    return switch (state.stance) {
      PaintballStance.stand => side > 0
          ? PaintballClip.standL
          : (side < 0 ? PaintballClip.standR : PaintballClip.stand),
      PaintballStance.crouch => side > 0
          ? PaintballClip.crouchL
          : (side < 0 ? PaintballClip.crouchR : PaintballClip.crouch),
      PaintballStance.duck => PaintballClip.duck,
    };
  }

  PaintballClip _fireClip() {
    final side = _turnSide;
    return side > 0
        ? PaintballClip.fireL
        : (side < 0 ? PaintballClip.fireR : PaintballClip.fire);
  }

  static bool _isFire(PaintballClip c) =>
      c == PaintballClip.fire || c == PaintballClip.fireL || c == PaintballClip.fireR;

  PaintballClip _slideClip() {
    // Your lanes run left→right on your screen. The opponent's lanes are
    // mirrored, so their lane +1 moves left on your screen.
    final laneDir = state.slideToLane - state.slideFromLane;
    final screenDir = isOpponent ? -laneDir : laneDir;
    // Back view: the character's left is screen-left.
    // Front view (facing you): the character's left is screen-right.
    final movingScreenLeft = screenDir < 0;
    if (isOpponent) {
      return movingScreenLeft ? PaintballClip.slideRight : PaintballClip.slideLeft;
    }
    return movingScreenLeft ? PaintballClip.slideLeft : PaintballClip.slideRight;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state.hitsTaken > _lastHitsTaken) {
      _hitTimer = _hitSeconds;
      _clipTime = 0.0;
    }
    _lastHitsTaken = state.hitsTaken;

    if (state.shotsFired > _lastShotsFired) {
      _fireTimer = _fireSeconds;
      if (_isFire(_clip)) _clipTime = 0.0;
    }
    _lastShotsFired = state.shotsFired;

    if (_hitTimer > 0.0) _hitTimer -= dt;
    if (_fireTimer > 0.0) _fireTimer -= dt;
    _flashClock += dt;

    final PaintballClip want;
    if (showDeath) {
      want = PaintballClip.death;
    } else if (showWin) {
      want = PaintballClip.win;
    } else if (isWalking) {
      want = PaintballClip.walk;
    } else if (_hitTimer > 0.0) {
      want = PaintballClip.hit;
    } else if (state.isSliding) {
      want = _slideClip();
    } else if (_fireTimer > 0.0 && state.stance != PaintballStance.duck) {
      // The fire clip is a standing pose; crouched shots keep the crouch pose.
      want = state.stance == PaintballStance.stand ? _fireClip() : _stanceClip();
    } else {
      want = _stanceClip();
    }
    _setClip(want);
    _clipTime += dt;

    if (_activeBodySplats > 0) {
      for (final s in _bodySplats) {
        if (!s.active) continue;
        s.age += dt;
        if (s.age >= _bodySplatSeconds) {
          s.active = false;
          _activeBodySplats--;
        }
      }
    }
  }

  int _frameIndex(PaintballClipFrames c) {
    final double fps = switch (_clip) {
      PaintballClip.slideLeft || PaintballClip.slideRight || PaintballClip.walk => _slideFps,
      PaintballClip.hit => c.frameCount / _hitSeconds,
      PaintballClip.fire || PaintballClip.fireL || PaintballClip.fireR => c.frameCount / _fireSeconds,
      _ => c.fps,
    };
    final i = (_clipTime * fps).floor();
    if (c.loop && _clip != PaintballClip.hit && !_isFire(_clip)) {
      return i % c.frameCount;
    }
    return i < c.frameCount ? i : c.frameCount - 1; // one-shots hold the last frame
  }

  @override
  void render(Canvas canvas) {
    final atlas = _atlas;
    if (atlas == null) return;

    final shiftX = cameraPanOffset * (isOpponent ? PaintballK.parallaxFarTires : 1.0);
    final shiftY = -cameraDipOffset * (isOpponent ? PaintballK.parallaxFarTiresY : 0.40);
    final scale = standHeight / atlas.standHeightPx;

    final c = atlas.clip(_clip);
    final frame = c.src[_frameIndex(c)];

    // Flicker while invulnerable after a hit (4 Hz).
    final flashing = state.isInvulnerable && ((_flashClock * 8.0).floor() & 1) == 0;

    canvas.save();
    // Flame has already translated the canvas to [position] (the ground point).
    canvas.translate(shiftX, shiftY);
    canvas.scale(scale);
    if (_clip != PaintballClip.death) {
      canvas.drawOval(_shadowRect, _shadowPaint);
    }
    final sheet = _splatSheet;
    if (_activeBodySplats > 0 && sheet != null) {
      // Draw the sprite into a layer, then paint marks with srcATop so they
      // only land on the player's own pixels.
      canvas.saveLayer(c.dst, _layerPaint);
      canvas.drawImageRect(atlas.image, frame, c.dst, flashing ? _flashPaint : _spritePaint);
      final stand = atlas.standHeightPx;
      final k = _bodySplatRadius * stand / 26.0; // 26 px = blob radius in the sheet
      // Marks are stored as the shooter sees them (front). Seen from behind,
      // left and right swap.
      final xSign = isOpponent ? 1.0 : -1.0;
      for (final s in _bodySplats) {
        if (!s.active) continue;
        final left = _bodySplatSeconds - s.age;
        if (left < _bodySplatFade) {
          _bodySplatPaint.color = Color.fromRGBO(255, 255, 255, left / _bodySplatFade);
        } else if (_bodySplatPaint.color != _opaque) {
          _bodySplatPaint.color = _opaque;
        }
        canvas.save();
        canvas.translate(xSign * s.dx * stand, -s.y * stand);
        canvas.scale(s.flip ? -k : k, k);
        canvas.drawImageRect(sheet, _blobSrc[s.cell], _blobDst, _bodySplatPaint);
        canvas.restore();
      }
      canvas.restore();
    } else {
      canvas.drawImageRect(atlas.image, frame, c.dst, flashing ? _flashPaint : _spritePaint);
    }
    canvas.restore();
  }
}
