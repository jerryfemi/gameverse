import 'package:flutter/material.dart';

import 'package:b_ball/tiki_counter/control/human_input.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';

/// Joystick that appears where your thumb lands (left side of the screen).
/// Writes a −1..1 direction into [HumanInput.stickX]/[HumanInput.stickY].
class FloatingJoystick extends StatefulWidget {
  final HumanInput input;

  const FloatingJoystick({super.key, required this.input});

  @override
  State<FloatingJoystick> createState() => _FloatingJoystickState();
}

class _FloatingJoystickState extends State<FloatingJoystick> {
  static const double radius = 56.0;

  int? _pointer;
  Offset? _origin;
  Offset _knob = Offset.zero;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    setState(() {
      _origin = e.localPosition;
      _knob = Offset.zero;
    });
  }

  void _move(PointerMoveEvent e) {
    final origin = _origin;
    if (e.pointer != _pointer || origin == null) return;
    var d = e.localPosition - origin;
    if (d.distance > radius) d = d / d.distance * radius;
    widget.input.stickX = d.dx / radius;
    widget.input.stickY = d.dy / radius;
    setState(() => _knob = d);
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    widget.input.stickX = 0.0;
    widget.input.stickY = 0.0;
    setState(() {
      _origin = null;
      _knob = Offset.zero;
    });
  }

  @override
  void dispose() {
    widget.input.stickX = 0.0;
    widget.input.stickY = 0.0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: LayoutBuilder(
        builder: (context, box) {
          final rest = Offset(radius + 28.0, box.maxHeight - radius - 28.0);
          return CustomPaint(
            size: Size(box.maxWidth, box.maxHeight),
            painter: _JoystickPainter(
              origin: _origin ?? rest,
              knob: _knob,
              active: _origin != null,
            ),
          );
        },
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset origin;
  final Offset knob;
  final bool active;

  _JoystickPainter({
    required this.origin,
    required this.knob,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const r = _FloatingJoystickState.radius;
    final base = Paint()
      ..color = Color(active ? 0x660A100D : 0x330A100D);
    final ring = Paint()
      ..color = TikiPalette.chalkSolid.withValues(alpha: active ? 0.45 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final thumb = Paint()
      ..color = TikiPalette.chalkSolid.withValues(alpha: active ? 0.9 : 0.35);
    canvas.drawCircle(origin, r, base);
    canvas.drawCircle(origin, r, ring);
    canvas.drawCircle(origin + knob, 24.0, thumb);
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.origin != origin || old.knob != knob || old.active != active;
}
