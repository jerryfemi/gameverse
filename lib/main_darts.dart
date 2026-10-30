import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:b_ball/darts/darts_constants.dart';
import 'package:b_ball/darts/darts_game_screen.dart';
import 'package:b_ball/game/audio/audio_engine.dart';

/// Standalone Darts: the real solo game screen (vs bot, pause menu,
/// practice mode, result card) without Firebase or the lobby.
///
///   flutter run -d chrome -t lib/main_darts.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(AudioEngine.init());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: DartsDevApp()));
}

class DartsDevApp extends StatelessWidget {
  const DartsDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => AudioEngine.unlockAudio(),
      onPointerUp: (_) => AudioEngine.unlockAudio(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: 'Darts',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(DartsK.surfaceDark),
          fontFamily: 'Roboto',
        ),
        home: const DartsGameScreen(),
      ),
    );
  }
}
