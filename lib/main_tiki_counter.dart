import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/firebase_options.dart';
import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/services/auth_service.dart';
import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_counter_screen.dart';

/// Standalone Tiki Counter (no lobby): the quickest way to work on the
/// game. Firebase and sign-in start the same way as the full app, so your
/// profile picture, profile sheet and record owner work here too. If
/// Firebase can't start (offline), the game still runs without them.
///
///   flutter run -d chrome -t lib/main_tiki_counter.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(AudioEngine.init());
  // No orientation lock here: the menus work either way up, and a match
  // locks itself sideways (LandscapeLock) when it starts.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    unawaited(AuthService.instance.initialize());
  } catch (e) {
    debugPrint('[Tiki] Firebase not started: $e');
  }
  runApp(const ProviderScope(child: TikiCounterDevApp()));
}

class TikiCounterDevApp extends StatelessWidget {
  const TikiCounterDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Browsers only allow sound after a user gesture.
    return Listener(
      onPointerDown: (_) => AudioEngine.unlockAudio(),
      onPointerUp: (_) => AudioEngine.unlockAudio(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: 'Tiki Counter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: TikiPalette.background,
        ),
        home: const TikiCounterScreen(),
      ),
    );
  }
}
