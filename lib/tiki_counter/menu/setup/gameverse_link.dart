import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/services/stats_service.dart';

/// Tiki Counter's few touch points with the rest of GameVerse (account,
/// daily stats). Everything here is safe when Firebase isn't running:
/// it just does nothing.
abstract final class GameVerseLink {
  static bool get _firebase => Firebase.apps.isNotEmpty;

  /// The signed-in user, or null (no Firebase, or not signed in yet).
  static UserProfile? get user {
    if (!_firebase) return null;
    try {
      return AuthService.instance.currentUser;
    } catch (e) {
      debugPrint('[Tiki] no user: $e');
      return null;
    }
  }

  /// Whose record to load: the user id, or 'guest'.
  static String get recordOwner => user?.uid ?? 'guest';

  /// Calls [onUser] once, as soon as a signed-in user is known.
  static void whenUser(void Function(UserProfile u) onUser) {
    final now = user;
    if (now != null) return onUser(now);
    if (!_firebase) return;
    final notifier = AuthService.instance.currentUserNotifier;
    void listener() {
      final u = notifier.value;
      if (u == null) return;
      notifier.removeListener(listener);
      onUser(u);
    }

    notifier.addListener(listener);
  }

  /// Adds one finished solo match to the admin dashboard's daily count.
  static void soloMatchFinished() {
    if (_firebase) StatsService.instance.soloRoundFinished();
  }
}
