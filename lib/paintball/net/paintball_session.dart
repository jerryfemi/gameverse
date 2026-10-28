import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
  /// 25 s accommodates mobile cellular network handoffs and battery throttling.
  static const int forfeitAfterSeconds = 25;

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

  // ─── Ready room state (read by the screen's room card) ─────────────────

  /// The opponent has this match open right now.
  final ValueNotifier<bool> opponentHere = ValueNotifier(false);
  final ValueNotifier<bool> meReady = ValueNotifier(false);
  final ValueNotifier<bool> opponentReady = ValueNotifier(false);

  /// Server time the duel starts (both ready); null while waiting.
  final ValueNotifier<int?> startAt = ValueNotifier(null);

  /// Connected and set up (READY can be pressed).
  final ValueNotifier<bool> connected = ValueNotifier(false);

  /// Several connection attempts failed; still retrying in the background.
  final ValueNotifier<bool> struggling = ValueNotifier(false);

  /// Rematches both players agreed to: the room opens already READY.
  static final Set<String> autoReady = <String>{};

  int _attempts = 0;
  Timer? _startTimer;
  Timer? _retryTimer;
  PaintballNetMeta? _meta;

  // ─── Connect ──────────────────────────────────────────────────────────────

  /// Called when the room opens. Waits until the database connection is up
  /// and carries the sign-in, then sets up the room. Failures retry quietly.
  Future<void> connect() async {
    if (_disposed) return;
    try {
      _db.goOnline();
      // The sign-in token must reach the database before the first request,
      // or it's treated as anonymous and refused.
      await FirebaseAuth.instance.currentUser?.getIdToken();
      await _db
          .ref('.info/connected')
          .onValue
          .firstWhere((e) => e.snapshot.value == true)
          .timeout(const Duration(seconds: 8));
      final off = await _db.ref('.info/serverTimeOffset').onValue.first;
      clock.updateOffset(off.snapshot.value as num?);

      // Whoever arrives first creates the meta node; the other fills in.
      await _root.child('meta').runTransaction((cur) {
        final m = cur is Map ? Map<String, dynamic>.from(cur) : <String, dynamic>{};
        m['v'] = kPaintballProtocolVersion;
        m['h'] = _hostUid;
        m['st'] ??= PaintballMatchNetStatus.waiting.code;
        if (!isHost) m['g'] = myUid;
        return Transaction.success(m);
      });

      await _root.child('p/$myUid').onDisconnect().update({'c': false});
      await _root.child('rd/$myUid').onDisconnect().remove();
      game.net = this;
      _sent.clear();
      sendState();

      _subs.add(_root.child('meta').onValue.listen(_onMeta));
      _subs.add(_root.child('rd').onValue.listen(_onReady));
      // Only what this player needs: the opponent's shots, and the verdicts
      // on our own shots (each is filed under its shooter).
      _subs.add(_root.child('r/$myUid').onChildAdded.listen(_onResult));
      _subs.add(_root.child('end').onValue.listen(_onEnd));
      _subs.add(_root.child('rs').onChildAdded.listen(_onRoundStart));

      final known = match.opponentPlayer(myUid)?.uid;
      if (known != null && known.isNotEmpty) _watchOpponent(known);
      if (!isHost) _watchOpponent(_hostUid);

      _attempts = 0;
      struggling.value = false;
      connected.value = true;
      if (status.value == PaintballSessionStatus.connecting) {
        status.value = PaintballSessionStatus.waitingForOpponent;
      }
      if (autoReady.remove(match.id)) unawaited(setReady(true));
    } catch (e) {
      debugPrint('[PaintballSession] connect attempt failed: $e');
      if (_disposed) return;
      for (final s in _subs) {
        s.cancel();
      }
      _subs.clear();
      _attempts++;
      if (_attempts >= 3) struggling.value = true;
      final wait = Duration(milliseconds: (700 * _attempts).clamp(700, 5000));
      _retryTimer = Timer(wait, connect);
    }
  }

  /// READY toggle from the room card. Both ready starts the countdown.
  Future<void> setReady(bool ready) async {
    if (!connected.value || _started) return;
    meReady.value = ready; // instant feedback; the listener confirms
    try {
      final ref = _root.child('rd/$myUid');
      if (ready) {
        await ref.set(true);
      } else {
        await ref.remove();
      }
    } catch (e) {
      debugPrint('[PaintballSession] ready write failed: $e');
      meReady.value = !ready;
    }
  }

  void _onReady(DatabaseEvent e) {
    final v = e.snapshot.value;
    _rd = v is Map ? v : const {};
    _applyReady();
  }

  Map<dynamic, dynamic> _rd = const {};

  void _applyReady() {
    meReady.value = _rd[myUid] == true;
    final opp = opponentUid.value;
    opponentReady.value = opp != null && _rd[opp] == true;
    _hostCheckStart();
  }

  /// Host only: both ready → shared start 3.5 s out; someone un-readies or
  /// leaves before it → cancel back to waiting.
  void _hostCheckStart() {
    if (!isHost || _started || _disposed) return;
    final both = meReady.value && opponentReady.value && opponentHere.value;
    final meta = _meta;
    final counting = meta?.status == PaintballMatchNetStatus.live && meta?.startAtMs != null;
    if (both && !counting) {
      _root.child('meta').update({
        'st': PaintballMatchNetStatus.live.code,
        'at': clock.serverNowMs + 3500,
      });
    } else if (!both && counting && (meta!.startAtMs! > clock.serverNowMs)) {
      _root.child('meta').update({'st': PaintballMatchNetStatus.ready.code, 'at': null});
    }
  }

  void _watchOpponent(String uid) {
    if (opponentUid.value == uid) return;
    opponentUid.value = uid;
    _applyReady();
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
    _meta = meta;
    if (!meta.isVersionCompatible) {
      status.value = PaintballSessionStatus.versionMismatch;
      return;
    }
    final guest = meta.guestUid;
    if (guest != null && guest != myUid) _watchOpponent(guest);
    if (_started) return;

    final at = meta.startAtMs;
    if (meta.status == PaintballMatchNetStatus.live && at != null) {
      if (startAt.value != at) {
        startAt.value = at;
        _startTimer?.cancel();
        final wait = at - clock.serverNowMs;
        void go() {
          if (_disposed || _started) return;
          _started = true;
          _roundStartMs = at;
          status.value = PaintballSessionStatus.live;
          game.startOnline(((clock.serverNowMs - at) / 1000.0).clamp(0.0, 30.0));
        }
        if (wait <= 0) {
          go();
        } else {
          _startTimer = Timer(Duration(milliseconds: wait), go);
        }
      }
    } else {
      // Countdown cancelled (someone un-readied or left).
      _startTimer?.cancel();
      startAt.value = null;
    }
    _hostCheckStart();
  }

  void _onOpponentState(DatabaseEvent e) {
    final v = e.snapshot.value;
    if (v is! Map) return;
    final st = PaintballNetPlayerState.fromMap(v);
    opponentHere.value = st.connected;
    _hostCheckStart();
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
    // A ball fired in an earlier round never lands in this one.
    if (shot.serverMs < _roundStartMs) return;
    // Catch up on network lag, but never skip more than a third of the
    // flight: a ball that arrives late still visibly flies at you (the
    // target judges it where it lands, so nobody loses a dodge to lag).
    final elapsed = ((clock.serverNowMs - shot.serverMs) / 1000.0)
        .clamp(0.0, PaintballK.ballFlightSeconds / 3);
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
    } else if (!isHost) {
      // The host's verdict on the final round is the one both keep.
      game.match.settleFinalRound(_toWinner(end.winnerUid));
      _submitResult();
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
    // The guest waits briefly for the host's verdict so both records agree.
    if (isHost) {
      _submitResult();
    } else {
      Timer(const Duration(seconds: 3), _submitResult);
    }
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

  PaintballWinner _toWinner(String w) => w == myUid
      ? PaintballWinner.you
      : (w == 'tie' ? PaintballWinner.tie : PaintballWinner.opponent);

  String _toUid(PaintballWinner? w) => switch (w) {
        PaintballWinner.you => myUid,
        PaintballWinner.opponent => opponentUid.value ?? 'tie',
        _ => 'tie',
      };

  // ─── Rounds ───────────────────────────────────────────────────────────────

  /// Server time the current round went live (older shots are ignored).
  int _roundStartMs = 0;
  final Set<int> _roundsScheduled = <int>{};
  bool _submitted = false;

  @override
  void roundOver(int round, PaintballWinner? winner) {
    if (!isHost || _disposed) return;
    // Banner, then 3-2-1, then live for both at the same server moment.
    final at = clock.serverNowMs +
        ((PaintballK.roundBreakSeconds + 3.0) * 1000).round();
    _root.child('rs/$round').set({'w': _toUid(winner), 'at': at}).catchError(
        (Object e) => debugPrint('[PaintballSession] round start write failed: $e'));
  }

  void _onRoundStart(DatabaseEvent e) {
    final n = int.tryParse(e.snapshot.key ?? '');
    final v = e.snapshot.value;
    if (n == null || v is! Map || !_roundsScheduled.add(n)) return;
    final at = (v['at'] as num?)?.toInt();
    if (at == null) return;
    final result = _toWinner((v['w'] as String?) ?? 'tie');
    _roundStartMs = at;
    // Start the 3-2-1 three seconds before the shared moment.
    final wait = at - 3000 - clock.serverNowMs;
    void go() {
      if (_disposed) return;
      game.match.beginNextRound(
        countdownSeconds: (at - clock.serverNowMs) / 1000.0,
        result: result,
      );
    }
    if (wait <= 0) {
      go();
    } else {
      Timer(Duration(milliseconds: wait), go);
    }
  }

  void _submitResult() {
    if (_submitted) return;
    _submitted = true;
    final m = game.match;
    // Score = rounds won (the match outcome compares it); one summary per
    // round with the hits landed that round.
    final summaries = <RoundSummaryStats>[
      for (var r = 0; r < m.roundHits.length; r++)
        RoundSummaryStats(
          roundIndex: r + 1,
          score: m.roundHits[r].$1,
          madeShots: r == 0 ? m.you.shotsHit : 0,
          totalShots: r == 0 ? m.you.shotsFired : 0,
          swishes: r == 0 ? m.you.timesDodged : 0,
          bestStreak: r == 0 ? m.you.longestSurvivalSeconds.round() : 0,
        ),
    ];
    FirestoreMatchService.instance.submitPaintballResult(
      matchId: match.id,
      uid: myUid,
      roundsWon: m.youRounds.clamp(0, PaintballK.roundsToWin),
      rounds: summaries,
    );
  }

  /// Ends the live part: a few seconds for the last packets, then offline.
  /// The host removes the live node (the Firestore record stays forever).
  void _finish() {
    if (_disposed || status.value == PaintballSessionStatus.finished) return;
    _finished = true;
    _forfeitTimer?.cancel();
    status.value = PaintballSessionStatus.finished;
    // Either player clears the live node (whoever is still here). Wait
    // 15 seconds so a reconnecting opponent receives the end packet and
    // displays results rather than becoming stranded in an orphaned match.
    Timer(const Duration(seconds: 15), _removeAndGoOffline);
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
    _startTimer?.cancel();
    _retryTimer?.cancel();
    if (_finished) {
      // Leaving during the 4 s grace: clean up before disconnecting.
      _removeAndGoOffline();
    } else {
      _goOffline();
    }
    status.dispose();
    opponentUid.dispose();
    opponentHere.dispose();
    meReady.dispose();
    opponentReady.dispose();
    startAt.dispose();
    connected.dispose();
    struggling.dispose();
  }
}
