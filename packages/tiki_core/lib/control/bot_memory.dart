/// What a bot remembers between decisions (one per bot team).
class BotMemory {
  /// Seconds the current carrier has held the ball.
  double holdTime = 0.0;

  /// Seconds before the bot may consider shooting again. Set after it
  /// weighs a chance and decides not to shoot, so each chance gets one
  /// roll of the dice — not one every decision (8 per second).
  double shotLock = 0.0;
}
