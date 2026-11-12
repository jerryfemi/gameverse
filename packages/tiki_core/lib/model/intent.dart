/// What a controller wants its team's controlled disc to do this tick.
///
/// Human buttons, the bot and (later) the network all fill the same
/// [Intent]. The sim never knows who filled it.
///
/// It's a plain mutable object (not a sealed class per action) because one
/// is reused every tick per team, and it's easy to send over the network.
enum ActionKind { none, pass, through, lob, shoot, tackle }

enum SwitchKind { none, candidate, up, down, left, right }

class Intent {
  /// Stick direction, screen axes (+x right, +y down), length 0..1.
  double moveX = 0.0;
  double moveY = 0.0;

  /// PRESS / DASH held.
  bool dash = false;

  /// 2ND MAN held: a teammate joins the press.
  bool secondMan = false;

  /// One-shot action this tick.
  ActionKind action = ActionKind.none;

  /// Aim for the action (usually the stick when the button was released).
  double aimX = 0.0;
  double aimY = 0.0;

  /// 0..1 from how long the button was held.
  double power = 0.5;

  /// One-shot switch request.
  SwitchKind switchTo = SwitchKind.none;

  /// Called after the sim used the one-shots.
  void clearOneShots() {
    action = ActionKind.none;
    switchTo = SwitchKind.none;
  }

  void reset() {
    moveX = 0.0;
    moveY = 0.0;
    dash = false;
    secondMan = false;
    aimX = 0.0;
    aimY = 0.0;
    power = 0.5;
    clearOneShots();
  }
}
