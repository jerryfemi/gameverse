import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:tiki_core/control/human_input.dart';
import 'package:tiki_core/model/intent.dart';

/// Desktop controls. Wraps the match and writes key presses into the same
/// [HumanInput] the touch buttons use.
///
/// | key             | with the ball        | without the ball |
/// |-----------------|----------------------|------------------|
/// | W A S D / arrows| move (and aim)       | move             |
/// | Space           | dash                 | press            |
/// | J               | pass (hold = power)  | tackle           |
/// | K               | through ball         | switch (+ direction keys = that way) |
/// | L               | shoot                | 2nd man (hold)   |
/// | U               | lob                  | —                |
/// | Esc / P         | pause                | pause            |
class KeyboardControls extends StatefulWidget {
  final HumanInput input;

  /// Read at the moment a key goes down: attack keys or defence keys.
  final bool Function() attacking;
  final VoidCallback onPause;

  /// Called on the first key press (the screen hides the touch buttons).
  final VoidCallback onKeyboardUsed;
  final Widget child;

  const KeyboardControls({
    super.key,
    required this.input,
    required this.attacking,
    required this.onPause,
    required this.onKeyboardUsed,
    required this.child,
  });

  @override
  State<KeyboardControls> createState() => _KeyboardControlsState();
}

class _KeyboardControlsState extends State<KeyboardControls> {
  final FocusNode _focus = FocusNode(debugLabel: 'tiki-keyboard');

  static final _up = {LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp};
  static final _down = {LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown};
  static final _left = {LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft};
  static final _right = {
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.arrowRight,
  };

  HumanInput get _in => widget.input;

  @override
  void dispose() {
    _focus.dispose();
    _in.releaseAll();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is KeyRepeatEvent) return KeyEventResult.handled;
    final down = e is KeyDownEvent;
    final key = e.logicalKey;

    if (_isMoveKey(key)) {
      _updateStick();
    } else if (key == LogicalKeyboardKey.space) {
      _in.dashHeld = down;
    } else if (key == LogicalKeyboardKey.keyJ) {
      if (down) {
        _pressJ();
      } else {
        _releaseCharge(ActionKind.pass);
      }
    } else if (key == LogicalKeyboardKey.keyK) {
      if (down) {
        _pressK();
      } else {
        _releaseCharge(ActionKind.through);
      }
    } else if (key == LogicalKeyboardKey.keyL) {
      if (down) {
        _pressL();
      } else {
        _releaseL();
      }
    } else if (key == LogicalKeyboardKey.keyU) {
      if (down && widget.attacking()) {
        _in.beginCharge(ActionKind.lob);
      } else if (!down) {
        _releaseCharge(ActionKind.lob);
      }
    } else if (down &&
        (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP)) {
      widget.onPause();
    } else {
      return KeyEventResult.ignored;
    }
    if (down) widget.onKeyboardUsed();
    return KeyEventResult.handled;
  }

  void _pressJ() {
    if (widget.attacking()) {
      _in.beginCharge(ActionKind.pass);
    } else {
      _in.tap(ActionKind.tackle);
    }
  }

  void _pressK() {
    if (widget.attacking()) {
      _in.beginCharge(ActionKind.through);
      return;
    }
    // Switch: toward the held direction, or the suggested player.
    final x = _in.stickX;
    final y = _in.stickY;
    if (x == 0.0 && y == 0.0) {
      _in.requestSwitch(SwitchKind.candidate);
    } else if (x.abs() >= y.abs()) {
      _in.requestSwitch(x > 0 ? SwitchKind.right : SwitchKind.left);
    } else {
      _in.requestSwitch(y > 0 ? SwitchKind.down : SwitchKind.up);
    }
  }

  void _pressL() {
    if (widget.attacking()) {
      _in.beginCharge(ActionKind.shoot);
    } else {
      _in.secondManHeld = true;
    }
  }

  void _releaseL() {
    _in.secondManHeld = false;
    _releaseCharge(ActionKind.shoot);
  }

  /// Fires only if this key's kick is the one charging (possession may have
  /// changed while the key was held).
  void _releaseCharge(ActionKind kind) {
    if (_in.charging == kind) _in.releaseCharge();
  }

  bool _isMoveKey(LogicalKeyboardKey k) =>
      _up.contains(k) ||
      _down.contains(k) ||
      _left.contains(k) ||
      _right.contains(k);

  /// Stick from every movement key held right now (diagonals normalised).
  void _updateStick() {
    final held = HardwareKeyboard.instance.logicalKeysPressed;
    var x = 0.0;
    var y = 0.0;
    if (held.any(_left.contains)) x -= 1.0;
    if (held.any(_right.contains)) x += 1.0;
    if (held.any(_up.contains)) y -= 1.0;
    if (held.any(_down.contains)) y += 1.0;
    if (x != 0.0 && y != 0.0) {
      x *= 0.7071;
      y *= 0.7071;
    }
    _in.stickX = x;
    _in.stickY = y;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
