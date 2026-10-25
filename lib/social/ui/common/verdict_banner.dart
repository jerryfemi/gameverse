import 'package:b_ball/game/ui/common/ui_font.dart';
import 'package:flutter/material.dart';

enum VerdictBannerStyle { tile, hero }

/// Dynamic victory / defeat banner supporting both compact tile rows
/// and high-impact hero headings for results sheets.
class VerdictBanner extends StatelessWidget {
  final bool win;
  final String line;
  final VerdictBannerStyle style;

  const VerdictBanner({
    super.key,
    required this.win,
    required this.line,
    this.style = VerdictBannerStyle.tile,
  });

  const VerdictBanner.tile({super.key, required this.win, required this.line})
    : style = VerdictBannerStyle.tile;

  const VerdictBanner.hero({super.key, required this.win, required this.line})
    : style = VerdictBannerStyle.hero;

  static const Color mintWin = Color(0xFF00FFCC);
  static const Color redLoss = Color(0xFFF87171);

  @override
  Widget build(BuildContext context) {
    if (style == VerdictBannerStyle.hero) {
      return _buildHero();
    }
    return _buildTile();
  }

  Widget _buildHero() {
    final titleColor = win ? mintWin : redLoss;
    final titleText = win ? 'YOU WON' : 'YOU LOST';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          titleText,
          textAlign: TextAlign.center,
          style: UiFont.style(
            size: 34.0,
            weight: 900,
            color: titleColor,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        if (line.isNotEmpty) ...[
          const SizedBox(height: 6.0),
          Text(
            line,
            textAlign: TextAlign.center,
            style: UiFont.style(
              size: 14.0,
              weight: 600,
              color: const Color(0xFFE2E8F0),
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTile() {
    final color = win ? mintWin : redLoss;
    final badgeWord = win ? 'VICTORY' : 'DEFEAT';
    final bgTint = win
        ? const Color(0x1A00FFCC) // ~10% mint
        : const Color(0x24EF4444); // ~14% red

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Text(
            badgeWord,
            style: UiFont.style(
              size: 16.0,
              weight: 900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          if (line.isNotEmpty) ...[
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiFont.style(
                  size: 13.0,
                  weight: 600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
