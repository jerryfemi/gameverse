# Tiki Counter

Real-time football on a coach's tactics board. Discs are players, the white
pellet is the ball. No dribbling: you move, pass and press.

Design docs (claude.ai project): `tactics-board-handoff.md` (rules, look,
decisions) and `tactics-architecture.md` (how the code is built).

## Run it

```bash
# Standalone (no Firebase, no lobby) — fastest for working on the game
flutter run -d chrome -t lib/main_tiki_counter.dart

# Inside GameVerse: /tiki-counter  (lobby tile shows "Coming soon" for now)
flutter run -d chrome

# Checks
flutter analyze lib/tiki_counter test/tiki_counter
flutter test test/tiki_counter
```

Tap **DBG** (top right) during a match to see every disc's target and job.

## Status: milestones 0–3 (first playable)

| # | What works |
|---|---|
| 0 | Board, discs, ball; fixed 60 Hz loop with smooth drawing; debug view; route + standalone entry |
| 1 | Ball physics (rolling friction, lobs, bounces); PASS / THROUGH / LOB / SHOOT with hold-for-power and occasional misses |
| 2 | Interceptions, tackles, loose balls, throw-ins, corners, goal kicks, goals, kick-offs, offside (7v7), 7-minute clock with half-time, stats |
| 3 | Floating joystick, eFootball-style buttons, PRESS/DASH (heavy touches on the ball), assisted + tap/swipe switching, bot opponent, watch-bots mode |

The team brain is a **placeholder** (hold a home spot, receive, chase,
keeper, 2nd man). Milestones 4–6 replace it with formations that shift,
scored behaviours and defensive dials.

## Folder map (and what each may import)

| Folder | Job | May import |
|---|---|---|
| `core/` | Maths, seeded random, every tuning number (`tunables.dart`) | nothing in the game |
| `model/` | Plain state: discs, ball, teams, intent, events. No logic | `core` |
| `tactics/` | Formations (data) | `core`, `model` |
| `sim/` | The rules of the world, one 1/60 s step | `core`, `model`, `tactics` |
| `brain/` | Targets for the discs you're not controlling | `core`, `model`, `sim` (read-only helpers) |
| `control/` | Who steers the controlled disc: human, bot; switching | `core`, `model`, `sim/rules/receivers` |
| `runner/` | One full tick in the right order | everything above |
| `render/` | Flame drawing + the HUD bridge (`hud_model.dart`). Reads state, never changes it | everything above |
| `ui/` | Flutter screens, HUD, touch controls | everything |
| `theme/` | Colours | — |

`core` → `ui` top to bottom: the first six folders are **pure Dart** (no
Flutter, no Flame), so tests can play whole matches with no screen.

## One tick, in order

1. **Controllers** fill each team's `Intent` (stick, buttons, or bot).
2. **SwitchSelector** picks the controlled disc (carrier → receiver →
   SWITCH request → best placed defender).
3. **TeamBrain** (5×/s) gives every other disc a `target` + `urgency`.
4. **MatchSim.step** — read it top to bottom in `sim/match_sim.dart`:
   apply intents → move discs → push apart → ball at the carrier's feet →
   hold set pieces → ball physics → pickups/interceptions → out of play →
   possession time.
5. **Render** draws discs between their last two positions (`alpha`).

## What you should now understand (M0–M3)

- **Discs never get moved by instructions.** Everything decides *where to
  go*; only `sim/physics/disc_motion.dart` moves anything.
- **Intent is the only door into the sim.** Human, bot and (later)
  network all fill the same object (`model/intent.dart`).
- **Ball ownership changes in one place**: `sim/rules/ball_control.dart`
  (`give` / `release`). Passing, tackles, heavy touches and restarts all
  use it.
- **Interception** (`sim/rules/possession.dart`): the closest disc gets
  one dice roll per kick; faster balls and balls passing further away are
  harder to stop. Teammates and slow balls are always controlled.
- **Offside** (`sim/rules/offside.dart`) is decided *at the pass* (who was
  beyond the second-last defender) and called only if one of them touches
  the ball first.
- **Same seed, same match** (`core/rng.dart`): tests rely on it.

## Known rough edges (on purpose, for later milestones)

- Set-piece takers jump to the spot instead of running to it.
- The ball passes through discs that fail to stop it (no deflection
  off bodies besides a small angle change).
- Ends don't swap at half-time.
- No audio yet; the lobby tile is marked "Coming soon".
- One formation per mode (5v5 2-1-1, 7v7 2-3-1) and one bot level.
