import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'package:b_ball/models/cloud_match.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/net/paintball_clock.dart';
import 'package:b_ball/paintball/net/paintball_net_link.dart';
import 'package:b_ball/paintball/net/paintball_protocol.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/paintball_game.dart';
import 'package:b_ball/services/firestore_match_service.dart';

/// Where the live 1v1 is in its life, for the screen's overlays.
enum PaintballSessionStatus {
  connecting,
  waitingForOpponent,
  live,
  opponentReconnecting,
  finished,
  versionMismatch,
  error,
}

/// Live paintball 1v1 over Realtime Database (PAINTBALL_ONLINE_PLAN.md).
///
/// - Connects only for the duration of the match ([connect] / [dispose]).
/// - Writes on change only: player state, shots, the target's verdicts.
/// - Firestore is touched once, at the end, for history.
class PaintballSession implements PaintballNetLink {
  PaintballSession({
    required this.match,
    required this.myUid,
    required this.game,
  }) : isHost = match.player1.uid == myUid;

  /// RTDB instance of the project (default instance name).
  static const String databaseUrl =
      'https://game-arcade-bball-default-rtdb.firebaseio.com';

  /// Seconds the opponent may be gone before it counts as a forfeit.
  static const int forfeitAfterSeconds = 10;

  /// Lead time from "both in" to the shared start (server clock).
  static const int startLeadMs = 1500;

  final CloudMatch match;
  final String myUid;
  final PaintballGame game;
  final bool isHost;

  final PaintballClock clock = PaintballClock();
  final ValueNotifier<PaintballSessionStatus> status =
      ValueNotifier(PaintballSessionStatus.connecting);

  /// The opponent's uid once known (the host learns it when the guest joins).
  final ValueNotifier<String?> opponentUid = ValueNotifier(null);

  late final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: databaseUrl,
  );
  DatabaseReference get _root => _db.ref('paintball/${match.id}');

  final List<StreamSubscription<DatabaseEvent>> _subs = [];
  StreamSubscription<DatabaseEvent>? _oppSub;
  StreamSubscription<DatabaseEvent>? _oppShotSub;
  final Map<String, Object> _sent = <String, Object>{};
  final Set<String> _myShots = <String>{};
  final Set<String> _seenShots = <String>{};
  Timer? _forfeitTimer;
  bool _started = false;
  bool _finished = false;
  bool _disposed = false;

  String get _hostUid => match.player1.uid;

  /// Why the last connect failed (shown small in the error card).
  String? lastError;

  /// RETRY from the error card.
  Future<void> retry() async {
    if (_disposed) return;
    lastError = null;
    status.value = PaintballSessionStatus.connecting;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await connect();
  }

  // ─── Connect ──────────────────────────────────────────────────────────────

  Future<void> connect() async {
    try {
      _db.goOnline();
      final off = await _db.ref('.info/serverTimeOffset').onValue.first;
      clock.updateOffset(off.snapshot.value as num?);

      // Whoever arrives first creates the meta node; the other fills in.
      await _root.child('meta').runTransaction((cur) {
        final m = cur is Map ? Map<String, dynamic>.from(cur) : <String, dynamic>{};
        m['v'] = kPaintballProtocolVersion;
        m['h'] = _hostUid;
        if (isHost) {
          m['st'] ??= PaintballMatchNetStatus.waiting.code;
        } else {
          m['g'] = myUid;
          if (m['st'] == null || m['st'] == PaintballMatchNetStatus.waiting.code) {
            m['st'] = PaintballMatchNetStatus.ready.code;
          }
        }
        return Transaction.success(m);
      });

      final me = _root.child('p/$myUid');
      await me.onDisconnect().update({'c': false});
      game.net = this;
      sendState();

      _subs.add(_root.child('meta').onValue.listen(_onMeta));
      // Only what this player needs: the opponent's shots, and the verdicts
      // on our own shots (each is filed under its shooter).
      _subs.add(_root.child('r/$myUid').onChildAdded.listen(_onResult));
      _subs.add(_root.child('end').onValue.listen(_onEnd));

      final known = match.opponentPlayer(myUid)?.uid;
      if (known != null && known.isNotEmpty) _watchOpponent(known);
    } catch (e) {
      debugPrint('[PaintballSession] connect failed: $e');
      lastError = e.toString();
      if (!_disposed) status.value = PaintballSessionStatus.error;
    }
  }

  void _watchOpponent(String uid) {
    if (opponentUid.value == uid) return;
    opponentUid.value = uid;
    _oppSub?.cancel();
    _oppShotSub?.cancel();
    _oppSub = _root.child('p/$uid').onValue.listen(_onOpponentState);
    _oppShotSub = _root.child('s/$uid').onChildAdded.listen(_onShot);
  }

  // ─── Incoming ─────────────────────────────────────────────────────────────

  void _onMeta(DatabaseEvent e) {
    final v = e.snapshot.value;
    if (v is! Map) return;
    final meta = PaintballNetMeta.fromMap(v);
    if (!meta.isVersionCompatible) {
      status.value = PaintballSessionStatus.versionMismatch;
      return;
    }
    final guest = meta.guestUid;
    if (guest != null && guest != myUid) _watchOpponent(guest);
    if (!isHost) _watchOpponent(_hostUid);

    switch (meta.status) {
      case PaintballMatchNetStatus.waiting:
        if (!_started) status.value = PaintballSessionStatus.waitingForOpponent;
      case PaintballMatchNetStatus.ready:
        if (!_started) status.value = PaintballSessionStatus.waitingForOpponent;
        // Both in: the host sets the shared start.
        if (isHost && guest != null) {
          _root.child('meta').update({
            'st': PaintballMatchNetStatus.live.code,
            'at': clock.serverNowMs + startLeadMs,
          });
        }
      case PaintballMatchNetStatus.live:
        final at = meta.startAtMs;
        if (at != null && !_started) {
          _started = true;
          status.value = PaintballSessionStatus.live;
          final elapsed = (clock.serverNowMs - at) / 1000.0;
          if (elapsed >= 0) {
            game.startOnline(elapsed);
          } else {
            Timer(Duration(milliseconds: (-elapsed * 1000).round()), () {
              if (!_disposed) game.startOnline(0);
            });
          }
        }
      case PaintballMatchNetStatus.done:
        break;
    }
  }

  void _onOpponentState(DatabaseEvent e) {
    final v = e.snapshot.value;
    if (v is! Map) return;
    final st = PaintballNetPlayerState.fromMap(v);
    if (!st.connected) {
      if (_started && !_finished) {
        status.value = PaintballSessionStatus.opponentReconnecting;
        _forfeitTimer ??= Timer(const Duration(seconds: forfeitAfterSeconds), _claimForfeit);
      }
      return;
    }
    _forfeitTimer?.cancel();
    _forfeitTimer = null;
    if (status.value == PaintballSessionStatus.opponentReconnecting) {
      status.value = PaintballSessionStatus.live;
    }
    if (_started) game.applyRemoteState(st);
  }

  void _onShot(DatabaseEvent e) {
    final id = e.snapshot.key;
    final v = e.snapshot.value;
    if (id == null || v is! Map || !_seenShots.add(id)) return;
    final shot = PaintballNetShot.fromMap(id, v);
    if (!_started) return;
    final elapsed = ((clock.serverNowMs - shot.serverMs) / 1000.0)
        .clamp(0.0, PaintballK.ballFlightSeconds);
    game.applyRemoteShot(id, shot.aimX, shot.aimY, elapsed);
  }

  void _onResult(DatabaseEvent e) {
    final id = e.snapshot.key;
    final v = e.snapshot.value;
    if (id == null || v is! Map || !_myShots.contains(id)) return;
    game.applyRemoteResult(PaintballNetShotResult.fromMap(id, v));
  }

  void _onEnd(DatabaseEvent e) {
    final v = e.snapshot.value;
    if (v is! Map) return;
    final end = PaintballNetEnd.fromMap(v);
    if (end.reason == PaintballEndReason.forfeit && !end.isTie) {
      game.forceEnd(youWin: end.winnerUid == myUid);
    }
    _finish();
  }

  // ─── Outgoing (PaintballNetLink) ──────────────────────────────────────────

  @override
  void sendState() {
    if (_disposed) return;
    final you = game.match.you;
    // Ammo isn't sent: nobody sees the opponent's, and their shots imply it.
    final now = <String, Object>{
      'l': you.isSliding ? you.slideToLane : you.lane,
      's': you.stance.index,
      'h': you.hitsTaken,
      'm': game.aimBucket,
      'sl': you.isSliding ? you.slideFromLane : -1,
      'c': true,
    };
    final changed = <String, Object>{};
    now.forEach((k, v) {
      if (_sent[k] != v) changed[k] = v;
    });
    if (changed.isEmpty) return;
    _sent.addAll(changed);
    _root.child('p/$myUid').update(changed).catchError((Object e) {
      _sent.clear(); // resend everything next time
      debugPrint('[PaintballSession] state write failed: $e');
    });
  }

  @override
  String sendShot(double aimX, double aimY) {
    final ref = _root.child('s/$myUid').push();
    final id = ref.key!;
    _myShots.add(id);
    _seenShots.add(id);
    ref
        .set(PaintballNetShot(
          id: id,
          shooterUid: myUid,
          serverMs: clock.serverNowMs,
          aimX: aimX,
          aimY: aimY,
        ).toMap())
        .catchError((Object e) => debugPrint('[PaintballSession] shot failed: $e'));
    return id;
  }

  @override
  void sendResult(String shotId, PaintballHitOutcome outcome, double dx, double aimY) {
    final shooter = opponentUid.value;
    if (shooter == null) return;
    _root
        .child('r/$shooter/$shotId')
        .set(PaintballNetShotResult(
          shotId: shotId,
          outcome: PaintballNetHitOutcome.fromDomain(outcome),
          dx: dx,
          aimY: aimY,
        ).toMap())
        .catchError((Object e) => debugPrint('[PaintballSession] result failed: $e'));
  }

  @override
  void matchOver(PaintballWinner? winner) {
    // Each side records its own result in Firestore (permanent history).
    _submitResult();
    final w = switch (winner) {
      PaintballWinner.you => myUid,
      PaintballWinner.opponent => opponentUid.value ?? 'tie',
      _ => 'tie',
    };
    final reason = game.match.timeRemaining <= 0
        ? PaintballEndReason.time
        : PaintballEndReason.hits;
    if (isHost) {
      _root.child('end').set(PaintballNetEnd(winnerUid: w, reason: reason).toMap());
    }
    _finish();
  }

  /// You left a live match (lobby button, closed the screen): it's a forfeit.
  Future<void> forfeit() async {
    if (!_started || _finished) return;
    final opp = opponentUid.value;
    if (opp == null) return;
    _finished = true;
    try {
      await _root.child('end').set(
            PaintballNetEnd(winnerUid: opp, reason: PaintballEndReason.forfeit).toMap(),
          );
    } catch (_) {}
    await FirestoreMatchService.instance.forfeitMatch(
      matchId: match.id,
      forfeiterUid: myUid,
      winnerUid: opp,
    );
  }

  void _claimForfeit() {
    _forfeitTimer = null;
    final opp = opponentUid.value;
    if (_finished || opp == null) return;
    game.forceEnd(youWin: true);
    _root.child('end').set(
          PaintballNetEnd(winnerUid: myUid, reason: PaintballEndReason.forfeit).toMap(),
        );
    FirestoreMatchService.instance.claimForfeitVictory(
      matchId: match.id,
      winnerUid: myUid,
      forfeiterUid: opp,
    );
    _finish();
  }

  void _submitResult() {
    final m = game.match;
    FirestoreMatchService.instance.submitPaintballResult(
      matchId: match.id,
      uid: myUid,
      stats: RoundSummaryStats(
        roundIndex: 1,
        score: m.opponent.hitsTaken.clamp(0, PaintballK.hitsToWin),
        madeShots: m.you.shotsHit,
        totalShots: m.you.shotsFired,
        swishes: m.you.timesDodged,
        bestStreak: m.you.longestSurvivalSeconds.round(),
      ),
    );
  }

  /// Ends the live part: a few seconds for the last packets, then offline.
  /// The host removes the live node (the Firestore record stays forever).
  void _finish() {
    if (_disposed || status.value == PaintballSessionStatus.finished) return;
    _finished = true;
    _forfeitTimer?.cancel();
    status.value = PaintballSessionStatus.finished;
    // Either player clears the live node (whoever is still here), so it
    // doesn't linger when the host closes the tab early.
    Timer(const Duration(seconds: 4), _removeAndGoOffline);
  }

  bool _removed = false;

  Future<void> _removeAndGoOffline() async {
    if (!_removed) {
      _removed = true;
      try {
        await _root.remove().timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    _goOffline();
  }

  void _goOffline() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _oppSub?.cancel();
    _oppSub = null;
    _oppShotSub?.cancel();
    _oppShotSub = null;
    game.net = null;
    try {
      _db.goOffline();
    } catch (_) {}
  }

  /// Always called when the screen closes: never leave RTDB connected.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _forfeitTimer?.cancel();
    if (_finished) {
      // Leaving during the 4 s grace: clean up before disconnecting.
      _removeAndGoOffline();
    } else {
      _goOffline();
    }
    status.dispose();
    opponentUid.dispose();
  }
}
