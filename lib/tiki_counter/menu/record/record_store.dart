import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiki_core/record/club_record.dart';

/// Keeps your [ClubRecord] on this device, one per account ([owner] is the
/// user id, or 'guest'). When the database is set up for 1v1 this is the
/// one class that moves to Firestore (`tiki_records/{uid}`); nothing else
/// in the game needs to change.
abstract final class RecordStore {
  static String _key(String owner) => 'tiki_counter.record.v1.$owner';

  static Future<ClubRecord> load(String owner) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(owner));
      if (raw == null) return ClubRecord();
      final j = jsonDecode(raw);
      if (j is Map<String, Object?>) return ClubRecord.fromJson(j);
    } catch (_) {
      // A broken save never blocks the game: start a fresh record.
    }
    return ClubRecord();
  }

  static Future<void> save(String owner, ClubRecord r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(owner), jsonEncode(r.toJson()));
  }
}
