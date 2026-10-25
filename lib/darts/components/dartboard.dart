import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../darts_constants.dart';
import '../physics/dart_scoring.dart';
import '../scene/board_projection.dart';

/// Renders the regulation dartboard and hit-area flash.
///
/// The board face is the pre-rendered `assets/darts/board.png` (1536 px,
/// drawn to exactly the board's radius: its rings sit on the same
/// millimetre radii the scoring uses). If the image can't load, the board is
/// painted in code instead. Either way the hit flash is drawn on top.
///
/// Follows DARTS_PLAN.md Step 9:
/// - Recorded into a single [ui.Picture] on resize.
/// - GamePigeon-bright colors: true black and white singles, saturated
///   red/green doubles and trebles, bold white numbers on a black surround,
///   a metal rim and a soft drop shadow onto the wall.
/// - Precomputes paths for all 82 scoring areas at record time.
/// - `flashArea(DartHit)` flashes the hit bed pale blue for 450 ms.
/// - Zero allocations per frame in `render()`.
class Dartboard extends Component {
  final BoardProjection projection;

  ui.Picture? _boardPicture;

  /// Pre-rendered board face; null until loaded (or if missing).
  ui.Image? _boardImage;
  static const String boardImagePath = 'assets/darts/board.webp';

  /// The image's radius relative to the board's outer radius.
  static const double _imageRadiusFrac = 1.004;

  final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  // ─── 82 Precomputed Scoring Area Paths ─────────────────────────────────────
  final Map<String, Path> _flashPaths = <String, Path>{};
  Path? _activeFlashPath;
  double _flashTime = 0.0;
  static const double _flashDuration = 0.45; // 450 ms

  final Paint _flashPaint = Paint()..style = PaintingStyle.fill;

  // ─── Checkout Guidance Glow (Soft Gold Pulse) ──────────────────────────────
  final List<Path> _checkoutPaths = <Path>[];
  int? _activeCheckoutScore;
  double _glowTime = 0.0;

  final Paint _checkoutFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _checkoutStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Dartboard({required this.projection}) : super(priority: 1);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      final data = await rootBundle.load(boardImagePath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      _boardImage = (await codec.getNextFrame()).image;
      if (projection.screenWidth > 0.0) _recordBoard();
    } catch (_) {
      // No image: keep the painted board.
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recordBoard();
  }

  /// Triggers a visual flash on the specific scored board segment/bed.
  void flashArea(DartHit hit) {
    if (hit.isMiss) {
      _activeFlashPath = null;
      _flashTime = 0.0;
      return;
    }

    final String key = _flashKeyFor(hit);
    _activeFlashPath = _flashPaths[key];
    _flashTime = _flashDuration;
  }

  String _flashKeyFor(DartHit hit) {
    if (hit.isInnerBull) return 'bull_inner';
    if (hit.isBull) return 'bull_outer';
    if (hit.isDouble) return 'D${hit.segment}';
    if (hit.isTreble) return 'T${hit.segment}';
    if (hit.r > (DartsK.trebleInR + DartsK.trebleOutR) * 0.5) {
      return 'S${hit.segment}_outer';
    } else {
      return 'S${hit.segment}_inner';
    }
  }

  /// Sets the active checkout target score to highlight winning beds in soft gold.
  /// Pass null or 0 to clear.
  void setCheckoutTarget(int? remaining) {
    if (remaining == _activeCheckoutScore) return;
    _activeCheckoutScore = remaining;
    _rebuildCheckoutPaths();
  }

  /// Clears any active checkout bed highlights.
  void clearCheckoutTarget() => setCheckoutTarget(null);

  void _rebuildCheckoutPaths() {
    _checkoutPaths.clear();
    final int? remaining = _activeCheckoutScore;
    if (remaining == null || remaining <= 0 || remaining > 60) return;

    // 1. Fat single beds: remaining is 1..20
    if (remaining <= 20) {
      final String outer = 'S${remaining}_outer';
      final String inner = 'S${remaining}_inner';
      if (_flashPaths.containsKey(outer)) _checkoutPaths.add(_flashPaths[outer]!);
      if (_flashPaths.containsKey(inner)) _checkoutPaths.add(_flashPaths[inner]!);
    }

    // 2. Double finish: remaining is even and <= 40
    if (remaining <= 40 && remaining % 2 == 0) {
      final int seg = remaining ~/ 2;
      final String dKey = 'D$seg';
      if (_flashPaths.containsKey(dKey) && !_checkoutPaths.contains(_flashPaths[dKey])) {
        _checkoutPaths.add(_flashPaths[dKey]!);
      }
    }

    // 3. Treble finish: remaining is divisible by 3 and 21..60
    if (remaining > 20 && remaining <= 60 && remaining % 3 == 0) {
      final int seg = remaining ~/ 3;
      final String tKey = 'T$seg';
      if (_flashPaths.containsKey(tKey) && !_checkoutPaths.contains(_flashPaths[tKey])) {
        _checkoutPaths.add(_flashPaths[tKey]!);
      }
    }

    // 4. Outer bull (25 pts)
    if (remaining == 25 && _flashPaths.containsKey('bull_outer')) {
      _checkoutPaths.add(_flashPaths['bull_outer']!);
    }

    // 5. Inner bull (50 pts)
    if (remaining == 50 && _flashPaths.containsKey('bull_inner')) {
      _checkoutPaths.add(_flashPaths['bull_inner']!);
    }
  }

  void _recordBoard() {
    _boardPicture?.dispose();
    _flashPaths.clear();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas c = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, projection.screenWidth, projection.screenHeight),
    );

    final double cx = projection.boardCenterX;
    final double cy = projection.boardCenterY;
    final Offset center = Offset(cx, cy);
    final double mmToPx = projection.mmToPx;

    // Radii in screen pixels
    final double rInnerBull = DartsK.innerBullR * mmToPx;
    final double rOuterBull = DartsK.outerBullR * mmToPx;
    final double rTrebleIn = DartsK.trebleInR * mmToPx;
    final double rTrebleOut = DartsK.trebleOutR * mmToPx;
    final double rDoubleIn = DartsK.doubleInR * mmToPx;
    final double rDoubleOut = DartsK.doubleOutR * mmToPx;
    final double rBoard = DartsK.boardR * mmToPx;

    // Colors
    const Color colorBlackSingle = Color(0xFF141414);
    const Color colorCreamSingle = Color(0xFFF7F3E8);
    const Color colorRed = Color(0xFFE3262B);
    const Color colorGreen = Color(0xFF13A048);
    const Color colorSurround = Color(0xFF000000);
    const Color colorWire = Color(0xFFC9CED6);

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    // 0. Drop shadow on the wall (a soft offset gradient, no blur filter).
    final Offset shadowC = Offset(cx + rBoard * 0.035, cy + rBoard * 0.07);
    c.drawCircle(
      shadowC,
      rBoard * 1.12,
      Paint()
        ..shader = ui.Gradient.radial(
          shadowC,
          rBoard * 1.12,
          const [Color(0x99000000), Color(0x66000000), Color(0x00000000)],
          const [0.0, 0.86, 1.0],
        ),
    );

    // With the image, the painted board is only needed for its flash paths,
    // so it's drawn into a scratch canvas that is thrown away.
    final ui.Image? boardImage = _boardImage;
    final ui.PictureRecorder? scratch =
        boardImage != null ? ui.PictureRecorder() : null;
    final Canvas pc = scratch != null ? Canvas(scratch) : c;

    // 1. Pure black board surround / number ring
    fillPaint.color = colorSurround;
    pc.drawCircle(center, rBoard, fillPaint);

    // 2. 20 Radial segments & beds
    const double degToRad = math.pi / 180.0;
    const double sweepAngleRad = DartsK.segmentAngleDeg * degToRad; // 18 degrees

    for (int i = 0; i < DartsK.segmentOrder.length; i++) {
      final int segment = DartsK.segmentOrder[i];
      // Segment 20 (i=0) is centered at 12 o'clock (-90°): spans -99° to -81°
      final double startAngleRad = (-99.0 + (i * DartsK.segmentAngleDeg)) * degToRad;

      final bool isEven = i % 2 == 0;
      final Color singleColor = isEven ? colorBlackSingle : colorCreamSingle;
      final Color ringColor = isEven ? colorRed : colorGreen;

      // Bed 1: Outer double bed
      final Path doublePath = _buildAnnularSector(
        center,
        rDoubleIn,
        rDoubleOut,
        startAngleRad,
        sweepAngleRad,
      );
      fillPaint.color = ringColor;
      pc.drawPath(doublePath, fillPaint);
      _flashPaths['D$segment'] = doublePath;

      // Bed 2: Outer single bed (fat single)
      final Path outerSinglePath = _buildAnnularSector(
        center,
        rTrebleOut,
        rDoubleIn,
        startAngleRad,
        sweepAngleRad,
      );
      fillPaint.color = singleColor;
      pc.drawPath(outerSinglePath, fillPaint);
      _flashPaths['S${segment}_outer'] = outerSinglePath;

      // Bed 3: Treble bed
      final Path treblePath = _buildAnnularSector(
        center,
        rTrebleIn,
        rTrebleOut,
        startAngleRad,
        sweepAngleRad,
      );
      fillPaint.color = ringColor;
      pc.drawPath(treblePath, fillPaint);
      _flashPaths['T$segment'] = treblePath;

      // Bed 4: Inner single bed
      final Path innerSinglePath = _buildAnnularSector(
        center,
        rOuterBull,
        rTrebleIn,
        startAngleRad,
        sweepAngleRad,
      );
      fillPaint.color = singleColor;
      pc.drawPath(innerSinglePath, fillPaint);
      _flashPaths['S${segment}_inner'] = innerSinglePath;
    }

    // 3. Bulls
    // Outer bull: 25 pts (Green)
    final Path outerBullPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: rOuterBull))
      ..addOval(Rect.fromCircle(center: center, radius: rInnerBull))
      ..fillType = PathFillType.evenOdd;

    fillPaint.color = colorGreen;
    pc.drawCircle(center, rOuterBull, fillPaint);
    _flashPaths['bull_outer'] = outerBullPath;

    // Inner bull: 50 pts (Red)
    final Path innerBullPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: rInnerBull));
    fillPaint.color = colorRed;
    pc.drawCircle(center, rInnerBull, fillPaint);
    _flashPaths['bull_inner'] = innerBullPath;

    // 4. Thin silver spider wires
    final Paint wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = colorWire
      ..strokeWidth = math.max(1.2, rBoard * 0.006);

    // Concentric wire rings
    pc.drawCircle(center, rInnerBull, wirePaint);
    pc.drawCircle(center, rOuterBull, wirePaint);
    pc.drawCircle(center, rTrebleIn, wirePaint);
    pc.drawCircle(center, rTrebleOut, wirePaint);
    pc.drawCircle(center, rDoubleIn, wirePaint);
    pc.drawCircle(center, rDoubleOut, wirePaint);

    // 20 Radial wires
    for (int i = 0; i < DartsK.segmentOrder.length; i++) {
      final double wireAngleRad = (-99.0 + (i * DartsK.segmentAngleDeg)) * degToRad;
      final double cosA = math.cos(wireAngleRad);
      final double sinA = math.sin(wireAngleRad);

      pc.drawLine(
        Offset(cx + rOuterBull * cosA, cy + rOuterBull * sinA),
        Offset(cx + rDoubleOut * cosA, cy + rDoubleOut * sinA),
        wirePaint,
      );
    }

    // 5. White regulation numbers around the pure black surround
    _drawNumbers(pc, center, (rDoubleOut + rBoard) * 0.5, mmToPx);

    if (scratch != null && boardImage != null) {
      scratch.endRecording().dispose();
      c.drawImageRect(
        boardImage,
        Rect.fromLTWH(0, 0, boardImage.width.toDouble(), boardImage.height.toDouble()),
        Rect.fromCircle(center: center, radius: rBoard * _imageRadiusFrac),
        _imagePaint,
      );
    }

    _boardPicture = recorder.endRecording();
    _rebuildCheckoutPaths();
  }

  Path _buildAnnularSector(
    Offset center,
    double rIn,
    double rOut,
    double startAngleRad,
    double sweepAngleRad,
  ) {
    final Path path = Path();
    final Rect rectOut = Rect.fromCircle(center: center, radius: rOut);
    final Rect rectIn = Rect.fromCircle(center: center, radius: rIn);

    path.arcTo(rectOut, startAngleRad, sweepAngleRad, false);
    path.arcTo(rectIn, startAngleRad + sweepAngleRad, -sweepAngleRad, false);
    path.close();
    return path;
  }

  void _drawNumbers(Canvas c, Offset center, double numberRadiusPx, double mmToPx) {
    // Reduced from 34 mm to 24 mm for refined GamePigeon proportions
    final double fontSize = (24.0 * mmToPx).clamp(10.0, 32.0);
    const double degToRad = math.pi / 180.0;

    for (int i = 0; i < DartsK.segmentOrder.length; i++) {
      final int segment = DartsK.segmentOrder[i];
      final double angleRad = (-90.0 + (i * DartsK.segmentAngleDeg)) * degToRad;

      final double nx = center.dx + (numberRadiusPx * math.cos(angleRad));
      final double ny = center.dy + (numberRadiusPx * math.sin(angleRad));

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '$segment',
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(c, Offset(nx - (tp.width * 0.5), ny - (tp.height * 0.5)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_checkoutPaths.isNotEmpty) {
      _glowTime += dt;
      if (_glowTime > 1000.0) _glowTime -= 1000.0;
    }
    if (_flashTime > 0.0) {
      _flashTime = math.max(0.0, _flashTime - dt);
      if (_flashTime == 0.0) {
        _activeFlashPath = null;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Draw static recorded board picture
    if (_boardPicture != null) {
      canvas.drawPicture(_boardPicture!);
    }

    // 2. Draw soft breathing golden checkout glow on winning target bed(s)
    if (_checkoutPaths.isNotEmpty) {
      // Smooth sinusoidal breathing between 0.16 and 0.38 alpha
      final double pulse = 0.27 + 0.13 * math.sin(_glowTime * 3.5);
      _checkoutFillPaint.color = const Color(0xFFF59E0B).withValues(alpha: pulse);
      _checkoutStrokePaint
        ..color = const Color(0xFFFFD54F).withValues(alpha: (pulse + 0.15).clamp(0.0, 1.0))
        ..strokeWidth = math.max(1.5, projection.boardRadiusPx * 0.008);

      for (final Path path in _checkoutPaths) {
        canvas.drawPath(path, _checkoutFillPaint);
        canvas.drawPath(path, _checkoutStrokePaint);
      }
    }

    // 3. Draw hit-area flash overlay
    if (_flashTime > 0.0 && _activeFlashPath != null) {
      final double alpha = (_flashTime / _flashDuration).clamp(0.0, 1.0) * 0.7;
      _flashPaint.color = const Color(0xFFA9DCFF).withValues(alpha: alpha);
      canvas.drawPath(_activeFlashPath!, _flashPaint);
    }
  }

  @override
  void onRemove() {
    _boardPicture?.dispose();
    _boardPicture = null;
    _boardImage?.dispose();
    _boardImage = null;
    _flashPaths.clear();
    _checkoutPaths.clear();
    super.onRemove();
  }
}
