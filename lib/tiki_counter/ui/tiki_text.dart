import 'package:flutter/painting.dart';

import 'package:b_ball/game/ui/common/ui_font.dart';

/// Text styles for Tiki Counter screens.
///
/// - [display]: Archivo (the app's headline font) for titles, scores,
///   button labels and numbers.
/// - [body]: Inter (via the app's [UiFont]) for everything else.
abstract final class TikiText {
  static TextStyle display({
    required double size,
    double weight = 700,
    Color color = const Color(0xFFFFFFFF),
    double letterSpacing = 0.6,
  }) {
    return TextStyle(
      fontFamily: 'Archivo',
      fontSize: size,
      fontWeight: weight >= 600 ? FontWeight.w700 : FontWeight.w500,
      fontVariations: [FontVariation('wght', weight)],
      color: color,
      letterSpacing: letterSpacing,
      height: 1.1,
    );
  }

  static TextStyle body({
    required double size,
    double weight = 500,
    Color color = const Color(0xFF9FB3A8),
  }) {
    return UiFont.style(size: size, weight: weight, color: color, height: 1.35);
  }
}
