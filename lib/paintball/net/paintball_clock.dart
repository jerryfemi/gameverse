/// Clock and latency synchronization for Paintball live 1v1 over RTDB.
///
/// Follows PAINTBALL_ONLINE_PLAN.md §3:
/// - Tracks server time offset from `/.info/serverTimeOffset`.
/// - Computes deterministic `serverNow` timestamps for shots and match clock.
/// - Calculates RTT and classifies connection quality (normal, amber, red).
class PaintballClock {
  /// Estimated server offset in milliseconds (`serverTime - localTime`).
  int offsetMs = 0;

  /// Smoothing factor for latency estimation (exponential moving average).
  double smoothedRttMs = 50.0;

  /// Returns current timestamp in server time milliseconds.
  int get serverNowMs => DateTime.now().millisecondsSinceEpoch + offsetMs;

  /// Updates the server time offset (e.g. from `/.info/serverTimeOffset` snapshot).
  void updateOffset(num? rawOffset) {
    if (rawOffset != null) {
      offsetMs = rawOffset.round();
    }
  }

  /// Converts a local [DateTime] to server time milliseconds.
  int toServerMs(DateTime local) => local.millisecondsSinceEpoch + offsetMs;

  /// Converts server time milliseconds to a local [DateTime].
  DateTime fromServerMs(int serverMs) =>
      DateTime.fromMillisecondsSinceEpoch(serverMs - offsetMs);

  /// Updates RTT estimate when an echo or packet acknowledgement arrives.
  void recordRtt(double sampleRttMs) {
    smoothedRttMs = (smoothedRttMs * 0.8) + (sampleRttMs * 0.2);
  }

  /// Connection latency rating according to §5 of the plan:
  /// - Normal: <= 300 ms (no dot)
  /// - Amber: 300..600 ms
  /// - Red: > 600 ms
  PaintballLatencyRating get latencyRating {
    if (smoothedRttMs > 600.0) return PaintballLatencyRating.red;
    if (smoothedRttMs > 300.0) return PaintballLatencyRating.amber;
    return PaintballLatencyRating.normal;
  }
}

/// Latency classification for the HUD lag indicator.
enum PaintballLatencyRating {
  /// < 300 ms: clean, no indicator shown.
  normal,

  /// 300–600 ms: amber warning dot by the match timer.
  amber,

  /// > 600 ms: red warning dot by the match timer.
  red,
}
