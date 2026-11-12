import 'dart:ui';

/// Tiki Counter colours (from the "PannaVerse Tactics Board" design canvas).
/// Shared by the Flame board and the Flutter HUD.
abstract final class TikiPalette {
  // Board
  static const Color background = Color(0xFF0A100D);
  static const Color frame = Color(0xFF0D1813);
  static const Color frameBorder = Color(0xFF1F2E27);
  static const Color pitch = Color(0xFF16402F);
  static const Color stripe = Color(0xFF174532);
  static const Color chalk = Color(0x8CE8F0EA); // #E8F0EA at 55 %
  static const Color chalkSolid = Color(0xFFE8F0EA);

  // Home discs: bone
  static const Color homeFill = Color(0xFFF1EDE4);
  static const Color homeRim = Color(0xFFCBD5E1);
  static const Color homeEdge = Color(0xFF7C8796);
  static const Color homeText = Color(0xFF0F172A);

  // Away discs: amber
  static const Color awayFill = Color(0xFFF59E0B);
  static const Color awayRim = Color(0xFFB45309);
  static const Color awayEdge = Color(0xFF6B3A0A);
  static const Color awayText = Color(0xFF1A1206);

  // Ball
  static const Color ball = Color(0xFFFFFFFF);
  static const Color ballOutline = Color(0xFF0A100D);
  static const Color shadow = Color(0x73000000);

  // Accents
  static const Color cyan = Color(0xFF00FFCC);
  static const Color cyanGlow = Color(0x5900FFCC);
  static const Color amber = Color(0xFFF59E0B);
  static const Color slate = Color(0xFF94A3B8);
  static const Color mutedText = Color(0xFF9FB3A8);
  static const Color panel = Color(0xE6111C17);
  static const Color panelBorder = Color(0xFF2A3D33);
}
