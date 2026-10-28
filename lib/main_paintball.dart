import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:b_ball/game/audio/audio_engine.dart';
import 'package:b_ball/paintball/paintball_game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(AudioEngine.init());

  // Portrait orientation for portrait smartphone paintball duel
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: PaintballDevApp(),
    ),
  );
}

/// Standalone Paintball Duel harness (PAINTBALL_PLAN.md §7).
///
/// Completely decoupled from Firebase, Firestore, and the main lobby.
/// Zero network requests and zero database writes.
class PaintballDevApp extends StatelessWidget {
  const PaintballDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => AudioEngine.unlockAudio(),
      onPointerUp: (_) => AudioEngine.unlockAudio(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: 'Paintball 1v1 Prototype',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF060913),
          fontFamily: 'Inter',
        ),
        home: const PaintballGameScreen(),
      ),
    );
  }
}
