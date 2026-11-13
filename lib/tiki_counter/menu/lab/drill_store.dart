import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Best (fastest) time per drill on this device, in seconds.
abstract final class DrillStore {
  static const String _key = 'tiki_counter.drills.v1';

  static Future<Map<String, double>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return {};
      final j = jsonDecode(raw);
      if (j is Map) {
        return {
          for (final e in j.entries)
            if (e.value is num) '${e.key}': (e.value as num).toDouble(),
        };
      }
    } catch (_) {
      // A broken save never blocks the game.
    }
    return {};
  }

  static Future<void> save(Map<String, double> best) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(best));
  }
}
