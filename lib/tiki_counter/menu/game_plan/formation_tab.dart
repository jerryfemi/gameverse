import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/menu/board/board_paint.dart';
import 'package:b_ball/tiki_counter/menu/board/formation_board.dart';
import 'package:b_ball/tiki_counter/menu/game_plan/plan_panel.dart';
import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';
import 'package:b_ball/tiki_counter/menu/widgets/menu_header.dart';
import 'package:b_ball/tiki_counter/menu/widgets/text_tabs.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';
import 'package:tiki_core/tactics/formation.dart';
import 'package:tiki_core/tactics/formations.dart';
import 'package:tiki_core/tactics/position.dart';
import 'package:tiki_core/tactics/roles.dart';

/// Pick a formation, flip between its shape with and without the ball,
/// and tap a disc to see its position and built-in movements.
class FormationTab extends StatefulWidget {
  final TikiSetup setup;
  final ValueChanged<TikiSetup> onChanged;

  const FormationTab({super.key, required this.setup, required this.onChanged});

  @override
  State<FormationTab> createState() => _FormationTabState();
}

class _FormationTabState extends State<FormationTab> {
  bool _withBall = true;
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    final s = widget.setup;
    final f = s.formation;
    final sel = _selected.clamp(0, f.spots.length - 1).toInt();
    final aspect = (s.mode.length + BoardGeometry.margin * 2) /
        (s.mode.width + BoardGeometry.margin * 2);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 170, child: _formations(s)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextTabs<bool>(
                options: const [true, false],
                selected: _withBall,
                label: (b) => b ? 'With the ball' : 'Without the ball',
                size: 15,
                onChanged: (b) => setState(() => _withBall = b),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: BoardBox(
                  aspect: aspect,
                  child: FormationBoard(
                    mode: s.mode,
                    formation: f,
                    withBall: _withBall,
                    selected: sel,
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(width: 240, child: _player(f.spots[sel])),
      ],
    );
  }

  Widget _formations(TikiSetup s) {
    final list = Formations.forMode(s.mode);
    return ListView(
      children: [
        for (final f in list)
          _FormationItem(
            formation: f,
            on: f.name == s.formation.name,
            onTap: () => widget.onChanged(s.withFormation(f)),
          ),
      ],
    );
  }

  Widget _player(FormationSpot spot) {
    final role = Roles.forPosition(spot.position);
    final moves = role.weights.entries
        .where((e) => e.value >= 1.0 && _moveWords.containsKey(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return PlanPanel(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${spot.number}', style: TikiText.display(size: 34, weight: 900)),
            Text(
              _positionName(spot.position),
              style: TikiText.display(size: 18, weight: 800),
            ),
            Text(
              'Role: ${role.name}',
              style: TikiText.body(size: 13, color: TikiPalette.slate),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Built-in movements'),
            for (final m in moves)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _moveWords[m.key]!,
                  style: TikiText.body(size: 13, color: Colors.white),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Choosing a different role per player comes next.',
              style: TikiText.body(size: 12, color: TikiPalette.slate),
            ),
          ],
        ),
      ),
    );
  }

  static String _positionName(Position p) => switch (p) {
    Position.keeper => 'Keeper',
    Position.centreBack => 'Centre back',
    Position.fullBack => 'Full back',
    Position.holdingMid => 'Holding midfielder',
    Position.centralMid => 'Central midfielder',
    Position.wideMid => 'Wide midfielder',
    Position.attackingMid => 'Attacking midfielder',
    Position.winger => 'Winger',
    Position.striker => 'Striker',
  };

  static const Map<BehaviourKind, String> _moveWords = {
    BehaviourKind.holdShape: 'Holds its spot in the shape',
    BehaviourKind.support: 'Comes close to offer a pass',
    BehaviourKind.runInBehind: 'Runs in behind the last defender',
    BehaviourKind.holdWidth: 'Holds the touchline for width',
    BehaviourKind.dropToReceive: 'Drops short to receive',
    BehaviourKind.cutInside: 'Cuts inside from wide',
    BehaviourKind.overlap: 'Overlaps round the outside',
    BehaviourKind.press: 'Presses the ball',
    BehaviourKind.cutLane: 'Blocks passing lanes',
    BehaviourKind.markMan: 'Marks an opponent',
    BehaviourKind.cover: 'Covers behind the press',
    BehaviourKind.trackRunner: 'Tracks runners',
  };
}

class _FormationItem extends StatelessWidget {
  final Formation formation;
  final bool on;
  final VoidCallback onTap;

  const _FormationItem({
    required this.formation,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formation.name,
                style: TikiText.display(
                  size: 20,
                  weight: 900,
                  color: on ? TikiPalette.cyan : Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formation.blurb,
                style: TikiText.body(size: 12, color: TikiPalette.slate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
