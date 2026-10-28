import 'package:flutter_test/flutter_test.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';
import 'package:b_ball/paintball/logic/bot_brain.dart';

void main() {
  group('PaintballBotBrain Autonomous Cadence', () {
    test('does not act before decision interval elapses', () {
      final botBrain = PaintballBotBrain(
        seed: 42,
        minDecisionInterval: 1.5,
        maxDecisionInterval: 1.5,
      );
      final bot = PaintballPlayerState();
      final opponent = PaintballPlayerState();

      // Tick 1.0s (less than 1.5s interval)
      final action = botBrain.tick(
        dt: 1.0,
        bot: bot,
        opponent: opponent,
      );
      expect(action, isNull);
    });

    test('generates valid BotAction when decision interval elapses', () {
      final botBrain = PaintballBotBrain(
        seed: 42,
        minDecisionInterval: 1.0,
        maxDecisionInterval: 1.0,
      );
      final bot = PaintballPlayerState();
      final opponent = PaintballPlayerState();

      // Tick 1.1s (interval reached)
      final action = botBrain.tick(
        dt: 1.1,
        bot: bot,
        opponent: opponent,
      );

      expect(action, isNotNull);
      expect(
        action is BotSlideAction ||
            action is BotStanceAction ||
            action is BotFireAction,
        isTrue,
      );
    });

    test('prioritizes ducking to reload when ammo is 0', () {
      final botBrain = PaintballBotBrain(
        seed: 99,
        minDecisionInterval: 0.5,
        maxDecisionInterval: 0.5,
      );
      final bot = PaintballPlayerState()..ammo = 0; // Empty ammo
      final opponent = PaintballPlayerState();

      final action = botBrain.tick(
        dt: 0.6,
        bot: bot,
        opponent: opponent,
      );

      expect(action, isA<BotStanceAction>());
      expect((action as BotStanceAction).stance, PaintballStance.duck);
    });
  });

  group('PaintballBotBrain Reactive Evasion', () {
    test('reacts and ducks from incoming lethal projectile in occupied lane', () {
      final botBrain = PaintballBotBrain(
        seed: 123,
        minReactionDelay: 0.30,
        maxReactionDelay: 0.30,
        failToDuckChance: 0.0, // 100% dodge success
      );
      final bot = PaintballPlayerState()..lane = 2..stance = PaintballStance.stand;
      final opponent = PaintballPlayerState();

      final incoming = [
        IncomingProjectile(
          targetLane: 2, // Aimed directly at bot's lane
          heightY: 0.65, // Lethal chest height
          flightTimeRemaining: 0.40,
        ),
      ];

      // Step 1: Detects threat, begins reaction delay (0.30s)
      var action = botBrain.tick(
        dt: 0.15,
        bot: bot,
        opponent: opponent,
        incomingProjectiles: incoming,
      );
      expect(action, isNull); // Still in reaction delay

      // Step 2: Reaction delay expires -> duck!
      action = botBrain.tick(
        dt: 0.20,
        bot: bot,
        opponent: opponent,
        incomingProjectiles: incoming,
      );

      expect(action, isA<BotStanceAction>());
      expect((action as BotStanceAction).stance, PaintballStance.duck);
    });

    test('ignores projectile aimed at a different lane', () {
      final botBrain = PaintballBotBrain(
        seed: 123,
        minReactionDelay: 0.30,
        maxReactionDelay: 0.30,
      );
      final bot = PaintballPlayerState()..lane = 1..stance = PaintballStance.stand;
      final opponent = PaintballPlayerState();

      final incoming = [
        IncomingProjectile(
          targetLane: 4, // Misses bot (in lane 1)
          heightY: 0.65,
          flightTimeRemaining: 0.40,
        ),
      ];

      // Tick through reaction window
      final action = botBrain.tick(
        dt: 0.40,
        bot: bot,
        opponent: opponent,
        incomingProjectiles: incoming,
      );

      // Does not trigger reactive ducking
      expect(action, isNull);
    });
  });
}
