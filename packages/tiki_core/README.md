# tiki_core

Tiki Counter's match engine: state, physics, rules, team brain, controllers.
Pure Dart — no Flutter, no Flame, no dependencies — so it runs anywhere,
including headless checks and (later) the online host.

The game app (`lib/tiki_counter/` in the repo root) draws it and feeds it
input. See `lib/tiki_counter/README.md` for the full code tour.

## Run the checks

```bash
cd packages/tiki_core
dart pub get                  # first time only; downloads nothing
dart run test/run_checks.dart
```

The checks use a tiny built-in harness (`test/harness.dart`) instead of
`package:test`, so they need no download. They play full bot-vs-bot
matches and print the score and stats (incl. pattern runs), which is handy
for balancing. `tactics_checks.dart` checks formations, that a high line
really defends higher than a low block, and that the overlap starts.
