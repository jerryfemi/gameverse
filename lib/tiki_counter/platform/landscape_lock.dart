import 'package:b_ball/tiki_counter/platform/landscape_lock_stub.dart'
    if (dart.library.js_interop) 'package:b_ball/tiki_counter/platform/landscape_lock_web.dart'
    as impl;

/// Asks the browser for full screen and a landscape lock. Only works when
/// called from a tap (browsers require a user gesture) and only where the
/// browser allows it: Android Chrome yes, iPhone Safari no (there the
/// "turn your phone" screen does the job). Never throws.
abstract final class LandscapeLock {
  static void request() => impl.requestLandscape();
}
