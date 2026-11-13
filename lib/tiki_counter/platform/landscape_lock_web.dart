import 'dart:js_interop';

import 'package:flutter/foundation.dart';

extension type _Element(JSObject _) implements JSObject {
  external JSPromise<JSAny?>? requestFullscreen();
}

extension type _ScreenOrientation(JSObject _) implements JSObject {
  external JSPromise<JSAny?>? lock(JSString orientation);
}

@JS('document.documentElement')
external _Element? get _root;

@JS('document.fullscreenElement')
external JSObject? get _fullscreenElement;

@JS('screen.orientation')
external _ScreenOrientation? get _orientation;

/// Full screen first (Chrome only locks orientation in full screen), then
/// landscape. Failures (iPhone, desktop, user said no) are ignored.
void requestLandscape() {
  try {
    final root = _root;
    if (root != null && _fullscreenElement == null) {
      root.requestFullscreen()?.toDart.then((_) => _lock(), onError: (_) {});
    } else {
      _lock();
    }
  } catch (e) {
    debugPrint('[Tiki] full screen not available: $e');
  }
}

void _lock() {
  try {
    _orientation?.lock('landscape'.toJS)?.toDart.then((_) {}, onError: (_) {});
  } catch (e) {
    debugPrint('[Tiki] orientation lock not available: $e');
  }
}
