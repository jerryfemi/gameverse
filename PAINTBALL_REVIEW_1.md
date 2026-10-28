# Paintball: review 1 (28 Oct)

Scope: everything under `lib/paintball/`, `lib/main_paintball.dart`, the `/paintball` route and `test/paintball/`.
Plan reference: `PAINTBALL_PLAN.md`. Sprite reference: `PAINTBALL_SPRITES.md`.

## Where it stands

Plan phases 2–5 (static scene, local controls, shooting, bot mode) exist as a playable prototype with placeholder shapes. Phase 6 (live RTDB) and phase 7 (polish) are not started. The pure-Dart logic is solid and tested; most bugs are in the glue code in `paintball_game.dart`.

### Done and good
- `paintball_constants.dart`: one source of truth for lanes, timings, exposure heights, mirroring. Matches the plan.
- `match_state.dart`: lanes, stance, ammo, reload-while-ducked, invulnerability, 90 s clock, sudden death, stats (shots, hits, dodges, longest survival). Clean.
- `hit_resolver.dart`: lane + exposure check, mid-slide two-lane window, dodge stat. `resolveFromShooterAim` mirrors correctly and is unit tested.
- `ball_trajectory.dart`: allocation-free arc with a timestamp sync hook ready for networking.
- `bot_brain.dart`: plan §6e cadence (30/40/30), reaction delay 250–450 ms, 35% fail-to-duck, reload logic.
- Pools: 8 balls, 32 splats, allocated once.
- Tests: 26 tests across constants, resolver, match state, bot, trajectory.
- HUD, controls and results card follow the obsidian look; no SnackBars.

## Bugs (fix before sprites go in)

1. **Your shots resolve in the wrong lane.** `_handleBallLanding` passes `aimXToLane(reticle.aimX)`, a lane on *your* screen, to `resolveAtTargetLane`, then compares it with `match.opponent.lane`, a lane on *their* side. Only the centre lane lines up. The reticle lock-on mirrors correctly, so the reticle shows a lock while the hit misses. Fix: use `HitResolver.resolveFromShooterAim(shooterAimX: …)`.
2. **Your shot reads the reticle at landing, not at firing.** Moving the reticle during the 0.4 s flight changes where the shot counts. Store `aimX`/`aimY` (and the shooter) on the pooled `FlyingPaintball` at launch and use those at landing.
3. **Bot shots always resolve on your current lane.** The bot branch passes `targetLane: match.you.lane`, so sliding away never dodges. It should use the lane the shot was aimed at (`laneOnPlayerScreen`).
4. **Bot shot height is hard-coded to 0.65.** It ignores the bot's `aimY`. Store it on the ball and use it.
5. **You can act during the countdown and after game over.** `firePlayerShot`, `trySlide` and `tryChangeStance` don't check `match.phase`. Gate them on `live`/`suddenDeath`.
6. **Rematch leaves the old match running.** `onRematch` only calls `match.startMatch()`. Balls in flight, `_activeProjectiles`, splats, bot timers, reticle and camera keep their state, so a ball fired before rematch can hit in the new match. Add `PaintballGame.resetMatch()` that clears all of them.
7. **Incoming balls shrink as they approach you.** `ballStartScale 1.0` → `ballEndScale 0.28` is right for your shots but backwards for the bot's. Pass start and end scales per direction.
8. **The ball owner is detected by colour.** `isPlayerBall = ball.ballColor == pink` breaks as soon as team colours change. Store a `firedByYou` flag on the ball.
9. **Heavy haptic on taking a hit.** The project rules allow only light or medium. Use `mediumImpact`.
10. **Stance changes are instant.** Exposure switches the moment ▲/▼ is pressed, while the plan says 0.15 s. Either apply `pendingStance` when the timer ends, or accept instant and drop the unused fields. (Instant feels better for ducking; recommend keeping it instant for duck and 0.15 s going up.)

## Performance (60 fps rules)

- `FlyingPaintball.render` builds a new `Gradient.radial` shader every frame for every ball. Use a pre-rendered ball sprite, or cache one shader per colour and move it with `canvas.translate`.
- `player_sprite.dart` creates `Paint()` (`skinPaint`) inside render, and every component builds `Rect`/`RRect`/`Offset` per frame. Most of this goes away when sprites replace the placeholder shapes; tyres and the backdrop should become sprites too.
- Blur `MaskFilter` shadows on every tyre (10), the player and each ball are expensive on mobile GPUs. Bake shadows into the sprites.
- `SplatDecal.spawn` allocates `Offset`s per shot. That's minor, but pre-size the lists and store x/y doubles.
- HUD and controls rebuild on `Stream.periodic` at 10 and 20 Hz, so the whole overlay tree rebuilds even when nothing changes. Drive them from a `ValueNotifier` the game bumps only when ammo, hits, stance, lane, phase or the timer's second changes.
- `_activeProjectiles.add(IncomingProjectile(...))` allocates per shot. Pool it with the balls.

## Gaps against the plan

| Plan | Status |
|---|---|
| §4 sprites | Player atlases delivered (`assets/paintball/paintball_{back,front}_atlas`). Tyres, splats, ball and backdrop still placeholders. |
| §7 `player_sprite.dart` as `SpriteAnimationGroupComponent` built from the atlas `clips` block | Not started. Placeholder rectangles. (Claude will do this.) |
| Hit / death / win animations, paint splat on the character, screen shake for the victim | Not started. Only a red flash rectangle exists. |
| §5b snap-assist (pull reticle within ~20 px) | Constant exists, not used. |
| §5c camera pan ±15% | Uses ±28% plus lane tracking. Fine if it plays well, but it no longer matches the plan. |
| §6 live 1v1 on RTDB, `/matches` record, rules | Not started (no `net/` files). |
| §8 pause menu (Forfeit in live) | Not started. |
| §9 shared results sheet / podium | Custom `PaintballResultCard` instead of the shared one. Swap it before live play so history and head-to-head work. |
| §10.7 sounds | Uses `AudioEngine.playFloorBounce` as a placeholder pop. Needs real paintball pop, splat and hit sounds preloaded through `AudioEngine`. |
| Lobby card | `/paintball` is routed. Check it isn't linked from the lobby until bot mode is finished. |

## Smaller notes

- Depth order: balls (40) draw under the near tyres (50), so an incoming ball that hits your tyre vanishes behind it. Draw incoming balls above the near tyres.
- `main_paintball.dart` uses a plain `MaterialApp`, so the results card's `context.go('/')` throws in the dev harness. Guard it or use the router.
- `test/paintball/run_tests.dart` has no tests in it; delete it or make it a proper runner.
- Bot difficulty knobs exist but aren't exposed. An easy/normal/hard choice is a one-liner later.

## Suggested order

1. Bugs 1–8 (all in `paintball_game.dart`, one sitting), plus a test that fires at each lane and checks the right opponent lane is hit.
2. Sprites in (Claude): player animation component with anchors, then tyres, ball, splats, backdrop.
3. Hit/death/win flow and screen shake, sounds.
4. Swap in the shared results sheet, add the pause menu.
5. Live 1v1 over RTDB.
