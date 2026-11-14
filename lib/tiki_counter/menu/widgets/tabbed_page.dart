import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/ui/layout/page_shape.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// A menu page with tabs (Game plan, Lab). Where the tabs go depends on
/// the screen ([PageShape]):
/// - wide: header on top, tabs down the left, the tab's page beside them;
/// - compact (phone sideways): back, title and tabs share one row, so the
///   page underneath gets almost the whole height;
/// - stacked (phone upright): header, then the tabs in a row, then the page.
///
/// [extra] is a second set of choices (Game plan's game mode); [action] is
/// one button at the far right (Game plan's "Test vs bot").
class TabbedPage<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final List<T> tabs;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onTab;
  final Widget body;
  final Widget? extra;
  final Widget? action;
  final double sideTabsWidth;

  const TabbedPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.tabs,
    required this.selected,
    required this.label,
    required this.onTab,
    required this.body,
    this.subtitle,
    this.extra,
    this.action,
    this.sideTabsWidth = 130,
  });

  @override
  Widget build(BuildContext context) {
    final shape = PageShape.of(context);
    return SafeArea(
      child: Padding(
        padding: shape.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._top(shape),
            SizedBox(height: shape.gap),
            Expanded(child: _main(shape)),
          ],
        ),
      ),
    );
  }

  TextTabs<T> _rowTabs() => TextTabs<T>(
    options: tabs,
    selected: selected,
    label: label,
    onChanged: onTab,
    size: 15,
  );

  List<Widget> _top(PageShape shape) => switch (shape.kind) {
    PageKind.wide => [
      MenuHeader(
        title: title,
        subtitle: subtitle,
        onBack: onBack,
        trailing: _trailing(),
      ),
    ],
    PageKind.compact => [
      Row(
        children: [
          MenuIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Text(title, style: TikiText.display(size: shape.titleSize, weight: 900)),
          const SizedBox(width: 20),
          Expanded(child: _rowTabs()),
          if (extra != null) ...[const SizedBox(width: 14), extra!],
          if (action != null) ...[const SizedBox(width: 14), action!],
        ],
      ),
    ],
    PageKind.stacked => [
      MenuHeader(title: title, onBack: onBack, trailing: action),
      const SizedBox(height: 8),
      _rowTabs(),
      if (extra != null) Align(alignment: Alignment.centerLeft, child: extra),
    ],
  };

  Widget _main(PageShape shape) {
    if (!shape.wide) return body;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: sideTabsWidth,
          child: SideTabs<T>(
            options: tabs,
            selected: selected,
            label: label,
            onChanged: onTab,
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget? _trailing() {
    if (extra == null && action == null) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?extra,
        if (extra != null && action != null) const SizedBox(width: 22),
        ?action,
      ],
    );
  }
}
