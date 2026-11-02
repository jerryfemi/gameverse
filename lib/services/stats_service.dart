import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily usage counters for the admin dashboard.
///
/// Firebase keeps no day-by-day history, so the game records it itself in
/// `stats_daily/{yyyy-MM-dd}` (UTC day):
///   activePlayers, newPlayers, matchesStarted, matchesCompleted,
///   matchesForfeited, soloRounds, updatedAt
///
/// Each player's own last-active day lives in `user_activity/{uid}`, so a
/// player is counted as active at most once per day (the Firestore rules
/// enforce this too).
///
/// Every call is fire-and-forget: stats must never slow down or break the
/// game, so errors are only logged.
class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  static const String _prefKeyActiveDay = 'stats_active_day';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Today's stats document id, in UTC so every player shares the same day.
  static String todayKey([DateTime? now]) {
    final d = (now ?? DateTime.now()).toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  DocumentReference<Map<String, dynamic>> _today() =>
      _db.collection('stats_daily').doc(todayKey());

  /// Counts [user] as active today (once per day), and as a new player if
  /// their account was created today. Costs at most 1 read + 1 batched write
  /// per player per day; every later call that day returns from the local
  /// cache with no network.
  Future<void> markActiveToday(User user) async {
    try {
      final today = todayKey();
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefKeyActiveDay) == '${user.uid}|$today') return;

      final activityRef = _db.collection('user_activity').doc(user.uid);
      final snap = await activityRef.get();
      final data = snap.data();
      if (data?['lastActiveDay'] == today) {
        await prefs.setString(_prefKeyActiveDay, '${user.uid}|$today');
        return;
      }

      final created = user.metadata.creationTime;
      final isNewPlayer = data?['firstSeenDay'] == null &&
          created != null &&
          // 24h window, so a player who signs up at 23:59 UTC and first
          // reaches this check after midnight still counts as new.
          DateTime.now().toUtc().difference(created.toUtc()) <
              const Duration(hours: 24);

      final batch = _db.batch();
      batch.set(activityRef, {
        'lastActiveDay': today,
        'firstSeenDay': data?['firstSeenDay'] ?? today,
      }, SetOptions(merge: true));
      batch.set(_today(), {
        'activePlayers': FieldValue.increment(1),
        if (isNewPlayer) 'newPlayers': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      await prefs.setString(_prefKeyActiveDay, '${user.uid}|$today');
    } catch (e) {
      debugPrint('[StatsService] markActiveToday failed: $e');
    }
  }

  /// A 1v1 match became active (the second player joined).
  void matchStarted() => _bump('matchesStarted');

  /// A 1v1 match finished normally (written by the client that concluded it).
  void matchCompleted() => _bump('matchesCompleted');

  /// A 1v1 match ended by forfeit (written by the client that set it).
  void matchForfeited() => _bump('matchesForfeited');

  /// A solo round ended.
  void soloRoundFinished() => _bump('soloRounds');

  void _bump(String field) {
    _today()
        .set({
          field: FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .catchError((Object e) {
          debugPrint('[StatsService] $field increment failed: $e');
        });
  }
}
