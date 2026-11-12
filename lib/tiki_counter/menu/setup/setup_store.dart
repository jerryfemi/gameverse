import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:b_ball/tiki_counter/menu/setup/tiki_setup.dart';

/// Saves [TikiSetup] on the device (one JSON string). Bump the key's
/// version if the shape ever changes in a way old saves can't read.
abstract final class SetupStore {
  static const String _key = 'tiki_counter.setup.v1';

  static Future<TikiSetup> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return TikiSetup.initial;
      final j = jsonDecode(raw);
      if (j is Map<String, Object?>) return TikiSetup.fromJson(j);
    } catch (_) {
      // A broken save never blocks the game: start fresh.
    }
    return TikiSetup.initial;
  }

  static Future<void> save(TikiSetup s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
  }
}
