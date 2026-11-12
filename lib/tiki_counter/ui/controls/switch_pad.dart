import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/tiki_counter/model/intent.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// SWITCH: tap = jump to the suggested player (grey triangle);
/// swipe up/down/left/right = the teammate in that direction.
class SwitchPad extends StatefulWidget {
  final double size;
  final ValueChanged<SwitchKind> onSwitch;

  const SwitchPad({super.key, required this.size, required this.onSwitch});

  @override
  State<SwitchPad> createState() => _SwitchPadState();
}

class _SwitchPadState extends State<SwitchPad> {
  /// Finger travel (px) that counts as a swipe rather than a tap.
  static const double swipeDistance = 22.0;

  int? _pointer;
  Offset _start = Offset.zero;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pointer = e.pointer;
      _start = e.localPosition;
    });
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    setState(() => _pointer = null);
    final d = e.localPosition - _start;
    if (d.distance < swipeDistance) {
      widget.onSwitch(SwitchKind.candidate);
    } else if (d.dx.abs() > d.dy.abs()) {
      widget.onSwitch(d.dx > 0 ? SwitchKind.right : SwitchKind.left);
    } else {
      widget.onSwitch(d.dy > 0 ? SwitchKind.down : SwitchKind.up);
    }
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) setState(() => _pointer = null);
  }

  @override
  Widget build(BuildContext context) {
    final held = _pointer != null;
    const c = TikiPalette.slate;
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: held ? c.withValues(alpha: 0.35) : const Color(0x590A100D),
          border: Border.all(color: c.withValues(alpha: 0.8), width: 2.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Align(
              alignment: Alignment.topCenter,
              child: Icon(Icons.keyboard_arrow_up_rounded, color: c, size: 16),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Icon(Icons.keyboard_arrow_down_rounded, color: c, size: 16),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.keyboard_arrow_left_rounded, color: c, size: 16),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.keyboard_arrow_right_rounded, color: c, size: 16),
            ),
            Text(
              'SWITCH',
              style: TikiText.display(size: widget.size * 0.13, color: c),
            ),
          ],
        ),
      ),
    );
  }
}
