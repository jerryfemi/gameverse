import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/control/human_input.dart';
import 'package:b_ball/tiki_counter/ui/controls/control_cluster.dart';
import 'package:b_ball/tiki_counter/ui/controls/floating_joystick.dart';

/// Touch controls over the board: joystick area on the left, buttons on
/// the right. Lets go of every input when it disappears (half-time, pause).
class ControlsLayer extends StatefulWidget {
  final HumanInput input;
  final bool attacking;

  const ControlsLayer({
    super.key,
    required this.input,
    required this.attacking,
  });

  @override
  State<ControlsLayer> createState() => _ControlsLayerState();
}

class _ControlsLayerState extends State<ControlsLayer> {
  @override
  void dispose() {
    widget.input.releaseAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        Positioned(
          left: 0,
          bottom: 0,
          width: size.width * 0.45,
          height: size.height * 0.7,
          child: FloatingJoystick(input: widget.input),
        ),
        Positioned(
          right: 14 + pad.right,
          bottom: 12 + pad.bottom,
          child: ControlCluster(
            input: widget.input,
            attacking: widget.attacking,
          ),
        ),
      ],
    );
  }
}
