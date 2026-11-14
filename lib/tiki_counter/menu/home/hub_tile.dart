import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// A big home-screen entry: picture behind, a dark fade at the bottom so
/// the words read, title and one line underneath.
class HubTile extends StatelessWidget {
  final CustomPainter art;
  final String? eyebrow;
  final String title;
  final String line;
  final double titleSize;
  final Widget? action;
  final VoidCallback onTap;

  const HubTile({
    super.key,
    required this.art,
    required this.title,
    required this.line,
    required this.onTap,
    this.eyebrow,
    this.titleSize = 28,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: TikiPalette.frame,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: art),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0007100C), Color(0xE607100C)],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF1E2E26)),
                ),
              ),
              LayoutBuilder(builder: (context, box) => _words(box)),
            ],
          ),
        ),
      ),
    );
  }

  /// Small tiles (a phone) get tighter padding, a smaller title and one
  /// line; the title also shrinks to fit rather than wrap.
  Widget _words(BoxConstraints box) {
    final small = box.maxWidth < 240 || box.maxHeight < 150;
    final tiny = box.maxHeight < 110;
    final pad = small ? 14.0 : 22.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, small ? 10 : 18, pad, small ? 10 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (eyebrow != null && !tiny)
            Text(
              eyebrow!,
              style: TikiText.body(size: 12, weight: 700, color: TikiPalette.cyan),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: TikiText.display(
                size: small ? titleSize * 0.8 : titleSize,
                weight: 900,
              ),
            ),
          ),
          if (!tiny) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    line,
                    maxLines: box.maxHeight < 150 ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TikiText.body(size: small ? 12 : 13, color: const Color(0xFFCBD5E1)),
                  ),
                ),
                if (action != null) ...[const SizedBox(width: 10), action!],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
