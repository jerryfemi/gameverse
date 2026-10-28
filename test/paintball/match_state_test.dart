import 'package:flutter_test/flutter_test.dart';
import 'package:b_ball/paintball/paintball_constants.dart';
import 'package:b_ball/paintball/logic/match_state.dart';

void main() {
  group('PaintballPlayerState Actions & Transitions', () {
    late PaintballPlayerState player;

    setUp(() {
      player = PaintballPlayerState();
    });

    test('initial state matches starting defaults', () {
      expect(player.lane, PaintballK.defaultStartLane); // Lane 2
      expect(player.stance, PaintballStance.stand);
      expect(player.ammo, PaintballK.initialAmmo); // 5
      expect(player.hitsTaken, 0);
      expect(player.isSliding, isFalse);
      expect(player.canFire, isTrue);
    });

    test('trySlide() starts slide and finishes after slideDurationSeconds', () {
      final started = player.trySlide(1); // slide right to lane 3
      expect(started, isTrue);
      expect(player.isSliding, isTrue);
      expect(player.slideFromLane, 2);
      expect(player.slideToLane, 3);
      expect(player.canFire, isFalse); // Cannot fire while sliding

      // Halfway through slide
      player.tick(PaintballK.slideDurationSeconds * 0.5);
      expect(player.isSliding, isTrue);
      expect(player.slideProgress, closeTo(0.5, 0.01));

      // Complete slide
      player.tick(PaintballK.slideDurationSeconds * 0.5);
      expect(player.isSliding, isFalse);
      expect(player.lane, 3);
      expect(player.canFire, isTrue);
    });

    test('cannot slide past lane bounds (0 or 4)', () {
      player.lane = PaintballK.maxLane; // Lane 4
      expect(player.trySlide(1), isFalse);

      player.lane = PaintballK.minLane; // Lane 0
      expect(player.trySlide(-1), isFalse);
    });

    test('firing consumes ammo and tracks shotsFired', () {
      expect(player.tryFire(), isTrue);
      expect(player.ammo, 4);
      expect(player.shotsFired, 1);

      // Fire remaining ammo
      player.tryFire();
      player.tryFire();
      player.tryFire();
      player.tryFire();
      expect(player.ammo, 0);
      expect(player.canFire, isFalse);

      // Cannot fire with 0 ammo
      expect(player.tryFire(), isFalse);
      expect(player.shotsFired, 5);
    });

    test('reload loop awards +1 ammo every 0.4s ONLY while ducked', () {
      player.ammo = 2;

      // Standing does NOT reload
      player.tick(1.0);
      expect(player.ammo, 2);

      // Crouch does NOT reload
      player.tryChangeStance(PaintballStance.crouch);
      player.tick(1.0);
      expect(player.ammo, 2);

      // Duck DOES reload
      player.tryChangeStance(PaintballStance.duck);
      expect(player.canFire, isFalse); // Cannot fire while ducked

      // 0.4s elapsed -> +1 ammo
      player.tick(PaintballK.reloadIntervalPerBallSeconds);
      expect(player.ammo, 3);

      // Another 0.8s -> +2 ammo (total 5 = max)
      player.tick(PaintballK.reloadIntervalPerBallSeconds * 2);
      expect(player.ammo, 5);

      // Reaching max ammo stops incrementing
      player.tick(PaintballK.reloadIntervalPerBallSeconds);
      expect(player.ammo, 5);
    });

    test('taking damage increments hitsTaken and triggers invulnerability', () {
      expect(player.applyDamage(), isTrue);
      expect(player.hitsTaken, 1);
      expect(player.isInvulnerable, isTrue);

      // Immediate second hit is blocked by invulnerability
      expect(player.applyDamage(), isFalse);
      expect(player.hitsTaken, 1);

      // Advance past invulnerability window (1.0 s)
      player.tick(PaintballK.hitInvulnerabilitySeconds);
      expect(player.isInvulnerable, isFalse);

      // Second hit now applies
      expect(player.applyDamage(), isTrue);
      expect(player.hitsTaken, 2);

      // Third hit eliminates player
      player.tick(PaintballK.hitInvulnerabilitySeconds);
      expect(player.applyDamage(), isTrue);
      expect(player.hitsTaken, 3);
      expect(player.isEliminated, isTrue);
    });
  });

  group('PaintballMatchState Match Flow', () {
    late PaintballMatchState match;

    setUp(() {
      match = PaintballMatchState();
      match.startMatch();
    });

    test('intro phase transitions to countdown after 4.0 seconds', () {
      expect(match.phase, PaintballMatchPhase.intro);
      expect(match.introElapsed, 0.0);

      match.tick(2.5);
      expect(match.phase, PaintballMatchPhase.intro);
      expect(match.introElapsed, 2.5);

      match.tick(1.5);
      expect(match.phase, PaintballMatchPhase.countdown);
      expect(match.countdownRemaining, 3.0);
    });

    test('skipIntro() jumps straight to countdown', () {
      expect(match.phase, PaintballMatchPhase.intro);

      match.skipIntro();
      expect(match.phase, PaintballMatchPhase.countdown);
      expect(match.countdownRemaining, 3.0);
    });

    test('startMatch(skipIntro: true) starts directly in countdown', () {
      match.startMatch(skipIntro: true);
      expect(match.phase, PaintballMatchPhase.countdown);
      expect(match.countdownRemaining, 3.0);
    });

    test('countdown transitions to live combat after 3 seconds', () {
      match.skipIntro();
      expect(match.phase, PaintballMatchPhase.countdown);
      expect(match.countdownRemaining, 3.0);

      match.tick(1.5);
      expect(match.phase, PaintballMatchPhase.countdown);

      match.tick(1.5);
      expect(match.phase, PaintballMatchPhase.live);
      expect(match.countdownRemaining, 0.0);
    });

    void eliminate(PaintballPlayerState p) {
      for (var i = 0; i < PaintballK.hitsToWin; i++) {
        p.applyDamage();
        p.tick(PaintballK.hitInvulnerabilitySeconds);
      }
    }

    test('3 hits wins the round, then a break, then round 2', () {
      match.phase = PaintballMatchPhase.live;
      eliminate(match.opponent);

      match.tick(0.016);
      expect(match.phase, PaintballMatchPhase.roundOver);
      expect(match.roundWinner, PaintballWinner.you);
      expect(match.youRounds, 1);
      expect(match.roundHits.single, (3, 0));

      match.tick(PaintballK.roundBreakSeconds + 0.01);
      expect(match.phase, PaintballMatchPhase.countdown);
      expect(match.round, 2);
      expect(match.opponent.hitsTaken, 0); // fresh round
    });

    test('winning 2 rounds ends the match 2-0 (no round 3)', () {
      for (var r = 0; r < 2; r++) {
        match.phase = PaintballMatchPhase.live;
        eliminate(match.opponent);
        match.tick(0.016);
        if (match.phase == PaintballMatchPhase.roundOver) {
          match.tick(PaintballK.roundBreakSeconds + 0.01);
        }
      }
      expect(match.phase, PaintballMatchPhase.gameOver);
      expect(match.winner, PaintballWinner.you);
      expect(match.youRounds, 2);
      expect(match.round, 2);
    });

    test('1-1 goes to a deciding round 3', () {
      match.phase = PaintballMatchPhase.live;
      eliminate(match.opponent);
      match.tick(0.016);
      match.tick(PaintballK.roundBreakSeconds + 0.01);
      match.phase = PaintballMatchPhase.live;
      eliminate(match.you);
      match.tick(0.016);
      expect(match.phase, PaintballMatchPhase.roundOver);
      match.tick(PaintballK.roundBreakSeconds + 0.01);
      expect(match.round, 3);
      expect(match.isFinalRound, isTrue);
      match.phase = PaintballMatchPhase.live;
      eliminate(match.you);
      match.tick(0.016);
      expect(match.phase, PaintballMatchPhase.gameOver);
      expect(match.winner, PaintballWinner.opponent);
    });

    test('online: holds at the break until the host starts the next round', () {
      match.holdBetweenRounds = true;
      match.phase = PaintballMatchPhase.live;
      eliminate(match.opponent);
      match.tick(0.016);
      match.tick(10);
      expect(match.phase, PaintballMatchPhase.roundOver);
      // Host says it was actually the opponent's round.
      match.beginNextRound(countdownSeconds: 2.0, result: PaintballWinner.opponent);
      expect(match.round, 2);
      expect(match.youRounds, 0);
      expect(match.opponentRounds, 1);
      expect(match.countdownRemaining, 2.0);
    });

    test('timer expiration triggers sudden death if tied', () {
      match.phase = PaintballMatchPhase.live;
      match.timeRemaining = 0.5;

      // Both players have 1 hit taken
      match.you.applyDamage();
      match.opponent.applyDamage();

      match.tick(0.6);
      expect(match.phase, PaintballMatchPhase.suddenDeath);
    });

    test('timer expiration declares winner if scores differ', () {
      match.phase = PaintballMatchPhase.live;
      match.timeRemaining = 0.5;

      // Opponent took 2 hits, you took 1 hit
      match.you.applyDamage();
      match.opponent.applyDamage();
      match.opponent.tick(PaintballK.hitInvulnerabilitySeconds);
      match.opponent.applyDamage();

      match.tick(0.6);
      expect(match.phase, PaintballMatchPhase.roundOver);
      expect(match.roundWinner, PaintballWinner.you); // Fewer hits taken wins the round
    });
  });
}
