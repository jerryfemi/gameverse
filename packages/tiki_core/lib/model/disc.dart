import 'package:tiki_core/core/vec2.dart';
import 'package:tiki_core/model/side.dart';

enum Role { keeper, defender, midfielder, forward }

/// One player pellet. Plain state: no logic lives here.
class Disc {
  /// Index into `MatchState.discs` (home first, then away).
  final int id;
  final Side side;
  final int number;
  final Role role;

  /// Index of this disc's spot in its team's formation.
  final int slot;

  final Vec2 pos = Vec2();
  final Vec2 vel = Vec2();

  /// Position at the start of the last sim step (for smooth drawing).
  final Vec2 prev = Vec2();

  /// Direction the disc faces (unit length). The ball sits in front of it.
  final Vec2 facing = Vec2(1.0, 0.0);

  // ── Set by the team brain (5 Hz) for discs the player isn't steering ──
  /// Where the brain wants this disc to go.
  final Vec2 target = Vec2();

  /// 0..1 = fraction of run speed, above 1 = sprint.
  double urgency = 0.6;

  /// Short label of the current job, shown in the debug overlay.
  String job = '';

  /// Seconds left before the brain may switch this disc to another job
  /// (see `brain/job_picker.dart`).
  double commitTimer = 0.0;

  // ── Set each tick by the command applier for the controlled disc ──────
  /// True when a controller (stick/bot) drives this disc directly.
  bool manual = false;

  /// Holding DASH this tick.
  bool dashing = false;

  /// Velocity the controller asks for (used when [manual]).
  final Vec2 desiredVel = Vec2();

  // ── Timers (seconds, count down to 0) ─────────────────────────────────
  double stunTimer = 0.0;
  double tackleCooldown = 0.0;
  double pickupCooldown = 0.0;

  Disc({
    required this.id,
    required this.side,
    required this.number,
    required this.role,
    required this.slot,
  });

  bool get isKeeper => role == Role.keeper;
}
