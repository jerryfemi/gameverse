import 'package:b_ball/paintball/paintball_constants.dart';

/// Protocol version for Paintball RTDB network matches.
const int kPaintballProtocolVersion = 1;

/// Rounding helper: rounds a double to [decimals] places.
double roundTo(double val, int decimals) {
  final factor = switch (decimals) {
    1 => 10.0,
    2 => 100.0,
    3 => 1000.0,
    _ => 1000.0,
  };
  return (val * factor).roundToDouble() / factor;
}

/// Computes the upper-body aim pose bucket from aimTurn (1: towards the
/// character's own left, 0: centre, -1: own right)
/// with hysteresis to avoid boundary flickering over the network.
int computeAimBucket(double aimTurn, int currentBucket) {
  const threshold = 0.30;
  const hysteresis = 0.05;

  if (currentBucket == 1) {
    // In the +1 pose: stay unless aimTurn drops below (threshold - hysteresis)
    if (aimTurn < threshold - hysteresis) {
      return aimTurn < -threshold ? -1 : 0;
    }
    return 1;
  } else if (currentBucket == -1) {
    // In the -1 pose: stay unless aimTurn rises above (-threshold + hysteresis)
    if (aimTurn > -threshold + hysteresis) {
      return aimTurn > threshold ? 1 : 0;
    }
    return -1;
  } else {
    // Currently center: enter side pose only when exceeding full threshold
    if (aimTurn > threshold) return 1;
    if (aimTurn < -threshold) return -1;
    return 0;
  }
}

// ─── Match Meta ─────────────────────────────────────────────────────────────

/// Status of the live match node in RTDB.
enum PaintballMatchNetStatus {
  /// Waiting for opponent/guest to join ('w').
  waiting('w'),

  /// Guest present and ready ('r').
  ready('r'),

  /// Duel is live or in shared intro ('l').
  live('l'),

  /// Duel completed ('d').
  done('d');

  final String code;
  const PaintballMatchNetStatus(this.code);

  static PaintballMatchNetStatus fromCode(String? c) => switch (c) {
        'w' => PaintballMatchNetStatus.waiting,
        'r' => PaintballMatchNetStatus.ready,
        'l' => PaintballMatchNetStatus.live,
        'd' => PaintballMatchNetStatus.done,
        _ => PaintballMatchNetStatus.waiting,
      };
}

/// Metadata packet at `/paintball/{matchId}/meta`.
class PaintballNetMeta {
  final String hostUid;
  final String? guestUid;
  final PaintballMatchNetStatus status;
  final int? startAtMs;
  final int version;

  const PaintballNetMeta({
    required this.hostUid,
    this.guestUid,
    required this.status,
    this.startAtMs,
    this.version = kPaintballProtocolVersion,
  });

  bool get isVersionCompatible => version == kPaintballProtocolVersion;

  Map<String, dynamic> toMap() => {
        'h': hostUid,
        if (guestUid != null) 'g': guestUid,
        'st': status.code,
        if (startAtMs != null) 'at': startAtMs,
        'v': version,
      };

  factory PaintballNetMeta.fromMap(Map<dynamic, dynamic> map) {
    return PaintballNetMeta(
      hostUid: (map['h'] as String?) ?? '',
      guestUid: map['g'] as String?,
      status: PaintballMatchNetStatus.fromCode(map['st'] as String?),
      startAtMs: (map['at'] as num?)?.toInt(),
      version: (map['v'] as num?)?.toInt() ?? 1,
    );
  }
}

// ─── Player State ───────────────────────────────────────────────────────────

/// Player state packet at `/paintball/{matchId}/p/{uid}`.
///
/// Written only on state change (never per frame). Overwritten in place.
class PaintballNetPlayerState {
  final int lane;
  final int stance; // 0: stand, 1: crouch, 2: duck
  final int ammo;
  final int hitsTaken;
  final int aimBucket; // -1: left, 0: center, 1: right
  final int slideFromLane; // -1 if stationary, or departure lane (0..4)
  final dynamic timestamp; // int server timestamp or ServerValue.timestamp
  final bool connected;

  const PaintballNetPlayerState({
    required this.lane,
    required this.stance,
    required this.ammo,
    required this.hitsTaken,
    required this.aimBucket,
    required this.slideFromLane,
    required this.timestamp,
    required this.connected,
  });

  PaintballStance get stanceEnum => switch (stance) {
        1 => PaintballStance.crouch,
        2 => PaintballStance.duck,
        _ => PaintballStance.stand,
      };

  Map<String, dynamic> toMap() => {
        'l': lane,
        's': stance,
        'a': ammo,
        'h': hitsTaken,
        'm': aimBucket,
        'sl': slideFromLane,
        't': timestamp,
        'c': connected,
      };

  factory PaintballNetPlayerState.fromMap(Map<dynamic, dynamic> map) {
    return PaintballNetPlayerState(
      lane: (map['l'] as num?)?.toInt().clamp(0, 4) ?? PaintballK.defaultStartLane,
      stance: (map['s'] as num?)?.toInt().clamp(0, 2) ?? 0,
      ammo: (map['a'] as num?)?.toInt().clamp(0, PaintballK.maxAmmo) ?? PaintballK.initialAmmo,
      hitsTaken: (map['h'] as num?)?.toInt().clamp(0, PaintballK.hitsToWin) ?? 0,
      aimBucket: (map['m'] as num?)?.toInt().clamp(-1, 1) ?? 0,
      slideFromLane: (map['sl'] as num?)?.toInt().clamp(-1, 4) ?? -1,
      timestamp: map['t'],
      connected: (map['c'] as bool?) ?? true,
    );
  }
}

// ─── Shots ──────────────────────────────────────────────────────────────────

/// Shot launch packet at `/paintball/{matchId}/s/{pushId}`.
class PaintballNetShot {
  final String id;
  final String shooterUid;
  final int serverMs;
  final double aimX; // [-1.0, 1.0], 3 decimal places
  final double aimY; // [0.0, 1.5], 3 decimal places

  const PaintballNetShot({
    required this.id,
    required this.shooterUid,
    required this.serverMs,
    required this.aimX,
    required this.aimY,
  });

  Map<String, dynamic> toMap() => {
        'b': shooterUid,
        't': serverMs,
        'x': roundTo(aimX, 3),
        'y': roundTo(aimY, 3),
      };

  factory PaintballNetShot.fromMap(String id, Map<dynamic, dynamic> map) {
    return PaintballNetShot(
      id: id,
      shooterUid: (map['b'] as String?) ?? '',
      serverMs: (map['t'] as num?)?.toInt() ?? 0,
      aimX: (map['x'] as num?)?.toDouble() ?? 0.0,
      aimY: (map['y'] as num?)?.toDouble() ?? 0.65,
    );
  }
}

// ─── Shot Results ───────────────────────────────────────────────────────────

/// Hit resolution outcome written by the target at `/paintball/{matchId}/r/{shotId}`.
enum PaintballNetHitOutcome {
  miss(0),
  hit(1),
  tyre(2),
  invulnerable(3);

  final int code;
  const PaintballNetHitOutcome(this.code);

  static PaintballNetHitOutcome fromCode(int? c) => switch (c) {
        1 => PaintballNetHitOutcome.hit,
        2 => PaintballNetHitOutcome.tyre,
        3 => PaintballNetHitOutcome.invulnerable,
        _ => PaintballNetHitOutcome.miss,
      };

  static PaintballNetHitOutcome fromDomain(PaintballHitOutcome outcome) => switch (outcome) {
        PaintballHitOutcome.hitBody => PaintballNetHitOutcome.hit,
        PaintballHitOutcome.hitTire => PaintballNetHitOutcome.tyre,
        PaintballHitOutcome.invulnerable => PaintballNetHitOutcome.invulnerable,
        PaintballHitOutcome.missedLane => PaintballNetHitOutcome.miss,
      };
}

/// Target-side hit outcome packet at `/paintball/{matchId}/r/{shotId}`.
class PaintballNetShotResult {
  final String shotId;
  final PaintballNetHitOutcome outcome;
  final double dx; // Body relative dx in stands (2 decimal places)
  final double aimY; // Height in stands (2 decimal places)

  const PaintballNetShotResult({
    required this.shotId,
    required this.outcome,
    required this.dx,
    required this.aimY,
  });

  bool get isHit => outcome == PaintballNetHitOutcome.hit;

  Map<String, dynamic> toMap() => {
        'k': outcome.code,
        'x': roundTo(dx, 2),
        'y': roundTo(aimY, 2),
      };

  factory PaintballNetShotResult.fromMap(String shotId, Map<dynamic, dynamic> map) {
    return PaintballNetShotResult(
      shotId: shotId,
      outcome: PaintballNetHitOutcome.fromCode((map['k'] as num?)?.toInt()),
      dx: (map['x'] as num?)?.toDouble() ?? 0.0,
      aimY: (map['y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Match End ──────────────────────────────────────────────────────────────

/// Match termination reason.
enum PaintballEndReason {
  hits('hits'),
  time('time'),
  forfeit('forfeit');

  final String code;
  const PaintballEndReason(this.code);

  static PaintballEndReason fromCode(String? c) => switch (c) {
        'time' => PaintballEndReason.time,
        'forfeit' => PaintballEndReason.forfeit,
        _ => PaintballEndReason.hits,
      };
}

/// Match conclusion packet at `/paintball/{matchId}/end`.
class PaintballNetEnd {
  final String winnerUid; // winnerUid or 'tie'
  final PaintballEndReason reason;

  const PaintballNetEnd({
    required this.winnerUid,
    required this.reason,
  });

  bool get isTie => winnerUid == 'tie';

  Map<String, dynamic> toMap() => {
        'w': winnerUid,
        'by': reason.code,
      };

  factory PaintballNetEnd.fromMap(Map<dynamic, dynamic> map) {
    return PaintballNetEnd(
      winnerUid: (map['w'] as String?) ?? 'tie',
      reason: PaintballEndReason.fromCode(map['by'] as String?),
    );
  }
}
