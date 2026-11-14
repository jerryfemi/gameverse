import 'package:flutter/widgets.dart';

/// The three shapes a Tiki Counter menu page can take. Every menu reads
/// its shape from here, so the rules live in one place.
///
/// - [wide]: laptop, desktop, tablet held sideways. Side tabs on the left,
///   side panels next to the board.
/// - [compact]: a phone held sideways (a short screen). The page tabs move
///   up into the header, titles get smaller and spacing tighter, so the
///   board keeps its height.
/// - [stacked]: a phone held upright, or a narrow window. One column that
///   scrolls; side panels go under the board and the board stands upright.
enum PageKind { wide, compact, stacked }

class PageShape {
  final PageKind kind;

  /// The whole screen, in logical pixels.
  final Size size;

  const PageShape._(this.kind, this.size);

  static PageShape of(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    final upright = s.height > s.width;
    final PageKind kind;
    if (s.width < 560 || (upright && s.width < 1000)) {
      kind = PageKind.stacked;
    } else if (s.height < 560) {
      kind = PageKind.compact;
    } else {
      kind = PageKind.wide;
    }
    return PageShape._(kind, s);
  }

  bool get wide => kind == PageKind.wide;
  bool get compact => kind == PageKind.compact;
  bool get stacked => kind == PageKind.stacked;

  /// Upright screens get an upright board (your goal at the bottom).
  bool get uprightBoard => stacked && size.height > size.width;

  /// Padding around the page, inside the safe area.
  EdgeInsets get padding => switch (kind) {
    PageKind.wide => const EdgeInsets.fromLTRB(24, 16, 24, 18),
    PageKind.compact => const EdgeInsets.fromLTRB(16, 8, 16, 10),
    PageKind.stacked => const EdgeInsets.fromLTRB(16, 12, 16, 16),
  };

  /// Space between big blocks.
  double get gap => wide ? 18 : 12;

  /// Page title size.
  double get titleSize => wide ? 24 : 20;

  /// A side panel that is [ideal] wide on a big screen.
  double side(double ideal) => compact ? ideal * 0.85 : ideal;
}
