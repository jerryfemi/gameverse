import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/tiki_counter/ui/tiki_text.dart';

/// A round, translucent match button (eFootball style): the pitch shows
/// through, and it fills with its colour only while held.
///
/// Uses raw pointer events (not taps) so it reacts instantly and works
/// while the other thumb is on the joystick.
class ActionButton extends StatefulWidget {
  final String label;
  final double size;
  final Color accent;
  final VoidCallback onDown;
  final VoidCallback? onUp;

  const ActionButton({
    super.key,
    required this.label,
    required this.size,
    required this.accent,
    required this.onDown,
    this.onUp,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  int? _pointer;

  bool get _held => _pointer != null;

  void _down(PointerDownEvent e) {
    if (_held) return;
    HapticFeedback.lightImpact();
    setState(() => _pointer = e.pointer);
    widget.onDown();
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    setState(() => _pointer = null);
    widget.onUp?.call();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.accent;
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _held ? a.withValues(alpha: 0.9) : const Color(0x590A100D),
          border: Border.all(
            color: a.withValues(alpha: _held ? 1.0 : 0.75),
            width: 2.0,
          ),
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TikiText.display(
            size: widget.size * 0.16,
            color: _held ? const Color(0xFF04241D) : a,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
