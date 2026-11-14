import 'dart:async';

import 'package:flutter/services.dart';

/// Native builds: sideways for a match, any way up for the menus.
void requestLandscape() {
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  );
}

void releaseLandscape() {
  unawaited(SystemChrome.setPreferredOrientations(const []));
}
