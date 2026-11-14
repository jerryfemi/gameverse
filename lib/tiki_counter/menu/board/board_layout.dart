import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_caption.dart';
import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/plan_panel.dart';
import 'package:b_ball/tiki_counter/ui/layout/page_shape.dart';
import 'package:tiki_core/model/game_mode.dart';

/// Lays out every board page (Playstyle, Tune, Formation, Patterns,
/// Scenarios) in the shape the screen needs ([PageShape]):
///
/// - wide: [lead] | [above] + caption + board + [below] | side panel
/// - compact (phone sideways): the caption and [below] move into the side
///   panel, so the board keeps the height;
/// - stacked (phone upright): one scrolling column — [leadStacked],
///   [above], caption, an upright board, [below], then the side panel.
///
/// The pages only hand over their pieces; none of them knows the screen.
class BoardLayout extends StatelessWidget {
  final GameMode mode;
  final Widget board;
  final Widget side;
  final List<Widget> above;
  final String? caption;
  final List<Widget> below;
  final double sideWidth;

  /// Side panel on the left of the board (Tune: the controls lead).
  final bool sideFirst;

  /// A list down the left on wide and compact screens …
  final Widget? lead;
  final double leadWidth;

  /// … and what replaces it at the top of a stacked page.
  final Widget? leadStacked;

  const BoardLayout({
    super.key,
    required this.mode,
    required this.board,
    required this.side,
    this.above = const [],
    this.caption,
    this.below = const [],
    this.sideWidth = 260,
    this.sideFirst = false,
    this.lead,
    this.leadWidth = 160,
    this.leadStacked,
  });

  @override
  Widget build(BuildContext context) {
    final shape = PageShape.of(context);
    return shape.stacked ? _stacked(shape) : _row(shape);
  }

  Widget _row(PageShape shape) {
    final compact = shape.compact;
    final boardColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in above) ...[w, const SizedBox(height: 8)],
        if (caption != null && !compact) ...[
          BoardCaption(caption!),
          const SizedBox(height: 8),
        ],
        Expanded(child: BoardBox(mode: mode, child: board)),
        if (!compact)
          for (final w in below) ...[const SizedBox(height: 12), w],
      ],
    );
    final panel = SizedBox(
      width: shape.side(sideWidth),
      child: PlanPanel(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact && caption != null) ...[
                BoardCaption(caption!, maxLines: 4),
                const SizedBox(height: 12),
              ],
              if (compact)
                for (final w in below) ...[w, const SizedBox(height: 12)],
              side,
            ],
          ),
        ),
      ),
    );
    final gap = SizedBox(width: compact ? 12 : 16);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lead != null) ...[
          SizedBox(width: shape.side(leadWidth), child: lead),
          gap,
        ],
        if (sideFirst) ...[panel, gap],
        Expanded(child: boardColumn),
        if (!sideFirst) ...[gap, panel],
      ],
    );
  }

  Widget _stacked(PageShape shape) {
    final upright = shape.uprightBoard;
    return LayoutBuilder(
      builder: (context, box) {
        // The board's own height for this width (+ BoardBox's padding),
        // but never more than ~60% of the screen.
        final natural = (box.maxWidth - 20) /
                BoardGeometry.aspectFor(mode, upright: upright) +
            20;
        final cap = shape.size.height * 0.6;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            if (leadStacked != null) ...[leadStacked!, const SizedBox(height: 10)],
            for (final w in above) ...[w, const SizedBox(height: 8)],
            if (caption != null) ...[
              BoardCaption(caption!, maxLines: 3),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: natural < cap ? natural : cap,
              child: BoardBox(mode: mode, upright: upright, child: board),
            ),
            for (final w in below) ...[const SizedBox(height: 12), w],
            const SizedBox(height: 12),
            PlanPanel(child: side),
          ],
        );
      },
    );
  }
}
