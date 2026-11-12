import 'package:b_ball/tiki_counter/core/geometry.dart';
import 'package:b_ball/tiki_counter/core/tunables.dart';
import 'package:b_ball/tiki_counter/model/intent.dart';

/// The bridge between touch controls (Flutter widgets) and the game.
///
/// Widgets write here when fingers move; [HumanController] reads it once
/// per tick. Plain Dart, so tests can "press buttons" too.
class HumanInput {
  /// Joystick, screen axes, length 0..1.
  double stickX = 0.0;
  double stickY = 0.0;

  bool dashHeld = false;
  bool secondManHeld = false;

  /// Button being held to charge power (PASS, SHOOT…), or null.
  ActionKind? charging;
  double _chargeTime = 0.0;

  ActionKind _queued = ActionKind.none;
  double queuedAimX = 0.0;
  double queuedAimY = 0.0;
  double queuedPower = 0.5;

  SwitchKind _queuedSwitch = SwitchKind.none;

  /// 0..1 while charging, −1 otherwise (drawn under the controlled disc).
  double get chargeLevel => charging == null
      ? -1.0
      : clampD(_chargeTime / T.maxChargeSeconds, 0.0, 1.0);

  void beginCharge(ActionKind kind) {
    charging = kind;
    _chargeTime = 0.0;
  }

  /// Finger lifted: fire with the power built up.
  void releaseCharge() {
    final kind = charging;
    if (kind == null) return;
    _fire(kind, chargeLevel);
    charging = null;
  }

  /// Instant actions (TACKLE).
  void tap(ActionKind kind) => _fire(kind, 0.5);

  void requestSwitch(SwitchKind kind) => _queuedSwitch = kind;

  /// Called every frame by the game.
  void tick(double dt) {
    if (charging != null) _chargeTime += dt;
  }

  /// Read-and-clear, used by [HumanController].
  ActionKind takeAction() {
    final k = _queued;
    _queued = ActionKind.none;
    return k;
  }

  SwitchKind takeSwitch() {
    final k = _queuedSwitch;
    _queuedSwitch = SwitchKind.none;
    return k;
  }

  /// Let go of everything (pause, possession change, screen closed).
  void releaseAll() {
    stickX = 0.0;
    stickY = 0.0;
    dashHeld = false;
    secondManHeld = false;
    charging = null;
  }

  void _fire(ActionKind kind, double power) {
    _queued = kind;
    queuedAimX = stickX;
    queuedAimY = stickY;
    queuedPower = power;
  }
}
