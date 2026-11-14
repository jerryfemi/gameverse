import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/home/club_badge.dart';
import 'package:b_ball/tiki_counter/menu/home/hub_tile.dart';
import 'package:b_ball/tiki_counter/menu/home/profile_button.dart';
import 'package:b_ball/tiki_counter/menu/home/record_strip.dart';
import 'package:b_ball/tiki_counter/menu/home/tile_art.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/layout/page_shape.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/record/club_record.dart';

/// Tiki Counter's home: your club at the top, then three big entries —
/// Kick off, Game plan and Lab — and your record along the bottom.
/// Sideways screens put Kick off on the left; a phone held upright puts it
/// across the top with the other two side by side underneath.
class HomeHub extends StatefulWidget {
  final TikiSetup setup;
  final ClubRecord record;
  final VoidCallback onKickOff;
  final VoidCallback onRecord;
  final VoidCallback onGamePlan;
  final VoidCallback onLab;
  final VoidCallback onClub;
  final VoidCallback onExit;

  const HomeHub({
    super.key,
    required this.setup,
    required this.record,
    required this.onKickOff,
    required this.onRecord,
    required this.onGamePlan,
    required this.onLab,
    required this.onClub,
    required this.onExit,
  });

  @override
  State<HomeHub> createState() => _HomeHubState();
}

class _HomeHubState extends State<HomeHub> with SingleTickerProviderStateMixin {
  late final AnimationController _ball = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  late final KickOffArt _kickArt = KickOffArt(_ball);
  final GamePlanArt _planArt = GamePlanArt();
  final LabArt _labArt = LabArt();

  @override
  void dispose() {
    _ball.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = PageShape.of(context);
    return SafeArea(
      child: Padding(
        padding: shape.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(shape),
            SizedBox(height: shape.gap),
            Expanded(child: shape.stacked ? _tilesUpright(shape) : _tilesSideways(shape)),
            SizedBox(height: shape.compact ? 8 : 14),
            RecordStrip(record: widget.record, onTap: widget.onRecord),
          ],
        ),
      ),
    );
  }

  /// Back · club · (wordmark on big screens) · profile.
  Widget _header(PageShape shape) {
    final small = !shape.wide;
    return Row(
      children: [
        MenuIconButton(
          icon: Icons.arrow_back_rounded,
          label: 'Back to games',
          onTap: widget.onExit,
        ),
        SizedBox(width: small ? 10 : 16),
        Expanded(child: _clubHeader(widget.setup, small: small)),
        if (shape.wide && shape.size.width >= 900) ...[
          Text(
            'TIKI COUNTER',
            style: TikiText.display(
              size: 13,
              weight: 900,
              color: const Color(0xFF5E7A6C),
              letterSpacing: 2.6,
            ),
          ),
          const SizedBox(width: 16),
        ],
        const SizedBox(width: 10),
        TikiProfileButton(size: small ? 38 : 44),
      ],
    );
  }

  /// Sideways: Kick off big on the left, Game plan and Lab stacked right.
  Widget _tilesSideways(PageShape shape) {
    final gap = shape.compact ? 12.0 : 16.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: _kickTile(shape.compact ? 38 : 48)),
        SizedBox(width: gap),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _planTile()),
              SizedBox(height: gap),
              Expanded(child: _labTile()),
            ],
          ),
        ),
      ],
    );
  }

  /// Upright: Kick off across the top, Game plan and Lab side by side
  /// underneath.
  Widget _tilesUpright(PageShape shape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _kickTile(40)),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _planTile()),
              const SizedBox(width: 12),
              Expanded(child: _labTile()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kickTile(double titleSize) {
    final s = widget.setup;
    return HubTile(
      art: _kickArt,
      eyebrow: 'PLAY',
      title: 'Kick off',
      titleSize: titleSize,
      line: '${s.clubCode} vs bot · ${s.level.name} · ${s.mode.label}',
      onTap: widget.onKickOff,
      action: _playNow(),
    );
  }

  Widget _planTile() {
    final s = widget.setup;
    return HubTile(
      art: _planArt,
      title: 'Game plan',
      line: '${s.formation.name} · ${s.plan.name}',
      onTap: widget.onGamePlan,
    );
  }

  Widget _labTile() => HubTile(
    art: _labArt,
    title: 'Lab',
    line: 'Watch bots, patterns, scenarios and drills.',
    onTap: widget.onLab,
  );

  Widget _clubHeader(TikiSetup s, {required bool small}) {
    return Semantics(
      button: true,
      label: 'Edit club',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClub,
        child: Row(
          children: [
            ClubBadge(code: s.clubCode, size: small ? 36 : 44),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.clubName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TikiText.display(size: small ? 18 : 22, weight: 900),
                  ),
                  Text(
                    '${s.clubCode} · Playstyle: ${s.plan.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TikiText.body(size: 12, color: TikiPalette.slate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playNow() => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: TikiPalette.cyan,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      'PLAY',
      style: TikiText.display(
        size: 15,
        weight: 900,
        color: const Color(0xFF06120E),
        letterSpacing: 1.4,
      ),
    ),
  );
}
