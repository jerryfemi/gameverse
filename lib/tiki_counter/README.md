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
flutter analyze lib/tiki_counter packages/tiki_core
cd packages/tiki_core
dart run test/run_checks.dart      # engine checks, nothing to download
```

Desktop: play with the keyboard (WASD/arrows, J pass, K through, L shoot,
U lob, Space dash/press; defending J tackle, K switch, L 2nd man, Esc pause).
The touch buttons hide once you press a key and come back on a touch.

Tap **DBG** (top right) during a match to see every disc's target and job.

## Status: milestones 0–3 (first playable)

| # | What works |
|---|---|
| 0 | Board, discs, ball; fixed 60 Hz loop with smooth drawing; debug view; route + standalone entry |
| 1 | Ball physics (rolling friction, lobs, bounces); PASS / THROUGH / LOB / SHOOT with hold-for-power and occasional misses |
| 2 | Interceptions, tackles, loose balls, throw-ins, corners, goal kicks, goals, kick-offs, offside (7v7), 7-minute clock with half-time, stats |
| 3 | Floating joystick, eFootball-style buttons, PRESS/DASH (heavy touches on the ball), assisted + tap/swipe switching, bot opponent, watch-bots mode |

After the first playtest: keyboard controls, keeper dives further for
shots and stands off his line, bots shoot less and from closer, shots are
a little less accurate, two teammates come to offer a pass, and sounds
(kick, whistle, net, thud).

The team brain is a **placeholder** (hold a home spot, support the
carrier, receive, chase, keeper, 2nd man). Milestones 4–6 replace it with formations that shift,
scored behaviours and defensive dials.

## Where the code lives

The **engine** (rules, physics, AI, controllers) is its own pure-Dart
package in the repo: `packages/tiki_core/` (imported as
`package:tiki_core/...`). It has no Flutter and no `forge2d`, so its checks
run with plain `dart` and no C compiler. This folder (`lib/tiki_counter/`)
is only the **app side**: drawing, sounds, HUD and controls.

| Folder | Job | May import |
|---|---|---|
| `tiki_core/lib/core/` | Maths, seeded random, every tuning number (`tunables.dart`) | nothing in the game |
| `tiki_core/lib/model/` | Plain state: discs, ball, teams, intent, events. No logic | `core` |
| `tiki_core/lib/tactics/` | Formations (data) | `core`, `model` |
| `tiki_core/lib/sim/` | The rules of the world, one 1/60 s step | `core`, `model`, `tactics` |
| `tiki_core/lib/brain/` | Targets for the discs you're not controlling | `core`, `model`, `sim` (read-only helpers) |
| `tiki_core/lib/control/` | Who steers the controlled disc: human, bot; switching | `core`, `model`, `sim/rules/receivers` |
| `tiki_core/lib/runner/` | One full tick in the right order | everything above |
| `render/` (app) | Flame drawing + the HUD bridge (`hud_model.dart`). Reads state, never changes it | everything above |
| `ui/` (app) | Flutter screens, HUD, touch + keyboard controls | everything |
| `theme/` | Colours | — |

The engine package can't import Flutter even by accident: it has no
Flutter dependency. `render/tiki_sounds.dart` turns match events into
sounds; the engine never knows audio exists.

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
- The lobby tile is marked "Coming soon".
- One formation per mode (5v5 2-1-1, 7v7 2-3-1) and one bot level.
