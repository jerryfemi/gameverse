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
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (eyebrow != null)
                      Text(
                        eyebrow!,
                        style: TikiText.body(size: 12, weight: 700, color: TikiPalette.cyan),
                      ),
                    Text(title, style: TikiText.display(size: titleSize, weight: 900)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            line,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TikiText.body(size: 13, color: const Color(0xFFCBD5E1)),
                          ),
                        ),
                        ?action,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
