import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';

/// Saves [TikiSetup] on the device (one JSON string). Bump the key's
/// version if the shape ever changes in a way old saves can't read.
abstract final class SetupStore {
  static const String _key = 'tiki_counter.setup.v1';

  /// The saved setup, or null on a first launch (nothing saved yet).
  static Future<TikiSetup?> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final j = jsonDecode(raw);
      if (j is Map<String, Object?>) return TikiSetup.fromJson(j);
    } catch (_) {
      // A broken save never blocks the game: start fresh.
    }
    return null;
  }

  static Future<void> save(TikiSetup s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
  }
}
