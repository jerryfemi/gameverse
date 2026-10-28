import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';

/// What [PaintballGame] needs from a live 1v1 connection. Bot mode has none.
/// Implemented by PaintballSession (RTDB); a fake in tests.
abstract class PaintballNetLink {
  /// Publishes your shot; returns its id. The ball flies locally right away.
  String sendShot(double aimX, double aimY);

  /// You were the target of [shotId]: publish how it landed on you.
  void sendResult(String shotId, PaintballHitOutcome outcome, double dx, double aimY);

  /// Your lane, stance, ammo, hits or aim pose changed.
  void sendState();

  /// A round ended locally ([winner] from our side). The host announces the
  /// next round's shared start; the guest waits for it.
  void roundOver(int round, PaintballWinner? winner);

  /// The duel ended locally (3 hits, time, or forfeit).
  void matchOver(PaintballWinner? winner);
}
