import 'package:flutter/material.dart';

import '../../../game/ui/common/app_avatar.dart';

/// Wraps [AppAvatar] to render victory crowns, gold winner rings,
/// and online presence status dots per the GameVerse design spec.
class CrownAvatar extends StatelessWidget {
  final String avatar;
  final double size;
  final bool crowned;
  final bool isOnline;
  final Color sheetColor;
  final VoidCallback? onTap;

  const CrownAvatar({
    super.key,
    required this.avatar,
    this.size = 40.0,
    this.crowned = false,
    this.isOnline = false,
    this.sheetColor = const Color(0xFF0B1020),
    this.onTap,
  });

  static const Color goldColor = Color(0xFFFBBF24);
  static const Color onlineColor = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    // Crown dimensions proportional to avatar size
    final crownWidth = size * 0.44;
    final crownHeight = size * 0.28;
    // Overlap the top edge of the avatar by ~40% of crown height
    final crownTopOffset = -crownHeight * 0.60;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Base AppAvatar with optional winner gold ring & halo
          AppAvatar(
            avatar: avatar,
            size: size,
            borderColor: crowned ? goldColor : null,
            borderWidth: crowned ? 2.0 : 1.5,
            showGlow: crowned,
            glowColor: crowned ? goldColor.withValues(alpha: 0.35) : null,
            onTap: onTap,
          ),

          // Vector Crown centered over top border
          if (crowned)
            Positioned(
              top: crownTopOffset,
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size(crownWidth, crownHeight),
                  painter: _VectorCrownPainter(color: goldColor),
                ),
              ),
            ),

          // Online status dot at bottom right
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: onlineColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sheetColor,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Precision vector crown path with 3 peaks and gentle base curve.
class _VectorCrownPainter extends CustomPainter {
  final Color color;

  const _VectorCrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    // Start at bottom left
    path.moveTo(w * 0.12, h * 0.88);
    // Left peak
    path.lineTo(w * 0.04, h * 0.22);
    // Left valley
    path.lineTo(w * 0.32, h * 0.52);
    // Center peak (highest)
    path.lineTo(w * 0.50, 0.0);
    // Right valley
    path.lineTo(w * 0.68, h * 0.52);
    // Right peak
    path.lineTo(w * 0.96, h * 0.22);
    // Bottom right
    path.lineTo(w * 0.88, h * 0.88);
    // Bottom curve
    path.quadraticBezierTo(w * 0.50, h * 0.98, w * 0.12, h * 0.88);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VectorCrownPainter oldDelegate) =>
      oldDelegate.color != color;
}
