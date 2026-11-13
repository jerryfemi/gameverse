import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/home/club_badge.dart';
import 'package:b_ball/tiki_counter/menu/home/hub_tile.dart';
import 'package:b_ball/tiki_counter/menu/home/profile_button.dart';
import 'package:b_ball/tiki_counter/menu/home/record_strip.dart';
import 'package:b_ball/tiki_counter/menu/home/tile_art.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/record/club_record.dart';

/// Tiki Counter's home: your club at the top, then three big entries —
/// Kick off, Game plan and Lab.
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
    final s = widget.setup;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          children: [
            Row(
              children: [
                MenuIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back to games',
                  onTap: widget.onExit,
                ),
                const SizedBox(width: 16),
                Expanded(child: _clubHeader(s)),
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
                const TikiProfileButton(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: HubTile(
                      art: _kickArt,
                      eyebrow: 'PLAY',
                      title: 'Kick off',
                      titleSize: 48,
                      line: '${s.clubCode} vs bot · ${s.level.name} · ${s.mode.label}',
                      onTap: widget.onKickOff,
                      action: _playNow(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: HubTile(
                            art: _planArt,
                            title: 'Game plan',
                            line: '${s.formation.name} · ${s.plan.name}',
                            onTap: widget.onGamePlan,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: HubTile(
                            art: _labArt,
                            title: 'Lab',
                            line: 'Watch bots, patterns, scenarios and drills.',
                            onTap: widget.onLab,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RecordStrip(record: widget.record, onTap: widget.onRecord),
          ],
        ),
      ),
    );
  }

  Widget _clubHeader(TikiSetup s) {
    return Semantics(
      button: true,
      label: 'Edit club',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClub,
        child: Row(
          children: [
            ClubBadge(code: s.clubCode, size: 44),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.clubName,
                    overflow: TextOverflow.ellipsis,
                    style: TikiText.display(size: 22, weight: 900),
                  ),
                  Text(
                    '${s.clubCode} · Playstyle: ${s.plan.name}',
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
