import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/control/human_input.dart';
import 'package:b_ball/tiki_counter/model/intent.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/controls/action_button.dart';
import 'package:b_ball/tiki_counter/ui/controls/switch_pad.dart';

/// Right-hand buttons. Same five positions in attack and defence; only the
/// labels change with possession (eFootball layout):
///
/// | slot | attack  | defence       |
/// |------|---------|---------------|
/// | A    | DASH    | PRESS (+dash) |  ← same button, never swapped out
/// | B    | PASS    | TACKLE        |
/// | C    | SHOOT   | 2ND MAN       |
/// | D    | THROUGH | SWITCH        |
/// | E    | LOB     | —             |
///
/// PASS, THROUGH, LOB and SHOOT charge while held (power bar under your
/// disc) and fire on release, aimed with the joystick.
class ControlCluster extends StatefulWidget {
  final HumanInput input;
  final bool attacking;

  const ControlCluster({
    super.key,
    required this.input,
    required this.attacking,
  });

  static const double width = 280.0;
  static const double height = 210.0;

  @override
  State<ControlCluster> createState() => _ControlClusterState();
}

class _ControlClusterState extends State<ControlCluster> {
  HumanInput get _in => widget.input;

  @override
  void didUpdateWidget(ControlCluster old) {
    super.didUpdateWidget(old);
    if (old.attacking != widget.attacking) {
      // Buttons being swapped out can't report their finger lifting.
      _in.charging = null;
      _in.secondManHeld = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ControlCluster.width,
      height: ControlCluster.height,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: ActionButton(
              label: widget.attacking ? 'DASH' : 'PRESS',
              size: 86,
              accent: widget.attacking ? TikiPalette.chalkSolid : TikiPalette.cyan,
              onDown: () => _in.dashHeld = true,
              onUp: () => _in.dashHeld = false,
            ),
          ),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: widget.attacking ? _attack() : _defend(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attack() {
    return Stack(
      key: const ValueKey('attack'),
      children: [
        _slot(right: 98, bottom: 4, child: _charge('PASS', 78, TikiPalette.cyan, ActionKind.pass)),
        _slot(right: 12, bottom: 100, child: _charge('SHOOT', 66, TikiPalette.amber, ActionKind.shoot)),
        _slot(right: 94, bottom: 96, child: _charge('THROUGH', 66, TikiPalette.chalkSolid, ActionKind.through)),
        _slot(right: 188, bottom: 18, child: _charge('LOB', 56, TikiPalette.slate, ActionKind.lob)),
      ],
    );
  }

  Widget _defend() {
    return Stack(
      key: const ValueKey('defend'),
      children: [
        _slot(
          right: 98,
          bottom: 4,
          child: ActionButton(
            label: 'TACKLE',
            size: 78,
            accent: TikiPalette.amber,
            onDown: () => _in.tap(ActionKind.tackle),
          ),
        ),
        _slot(
          right: 12,
          bottom: 100,
          child: ActionButton(
            label: '2ND\nMAN',
            size: 66,
            accent: TikiPalette.chalkSolid,
            onDown: () => _in.secondManHeld = true,
            onUp: () => _in.secondManHeld = false,
          ),
        ),
        _slot(
          right: 92,
          bottom: 92,
          child: SwitchPad(size: 74, onSwitch: _in.requestSwitch),
        ),
      ],
    );
  }

  Widget _charge(String label, double size, Color accent, ActionKind kind) {
    return ActionButton(
      label: label,
      size: size,
      accent: accent,
      onDown: () => _in.beginCharge(kind),
      onUp: _in.releaseCharge,
    );
  }

  Widget _slot({
    required double right,
    required double bottom,
    required Widget child,
  }) => Positioned(right: right, bottom: bottom, child: child);
}
