import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:b_ball/tiki_counter/theme/tiki_palette.dart';
import 'package:b_ball/tiki_counter/ui/tiki_counter_screen.dart';

/// Standalone Tiki Counter (no Firebase, no lobby): the quickest way to
/// work on the game.
///
///   flutter run -d chrome -t lib/main_tiki_counter.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TikiCounterDevApp());
}

class TikiCounterDevApp extends StatelessWidget {
  const TikiCounterDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiki Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: TikiPalette.background,
      ),
      home: const TikiCounterScreen(),
    );
  }
}
