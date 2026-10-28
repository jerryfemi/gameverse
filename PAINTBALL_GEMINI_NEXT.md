# Paintball: next tasks for Gemini (28 Oct)

Read first: PAINTBALL_PLAN.md, PAINTBALL_SPRITES.md, PAINTBALL_REVIEW_1.md. Rules: 60 fps, no allocations in render/update, no SnackBars, never run `firebase deploy`, never delete completed matches. Pull before editing: Claude changed paintball_game.dart, player_sprite.dart, backdrop.dart, splat.dart, the screen and the audio engine today.

Do NOT change: the sprite atlases or their JSON, tyre/env images, PaintballK layout constants (farGroundY, oppStandHeight, nearGroundY, youStandHeight, tyreCoverHeight, stageAspect, farLaneScale), or the hit rules. Claude will do the walk sprites and body-accurate hit tests later.

## Task A: arena intro (do first)
1. New phase `intro` before `countdown` in `match_state.dart` (bot mode and live). Rematch / Play Again skip it and go straight to countdown. A tap anywhere also skips it.
2. 0–2.5 s, overview: animate `cameraPanOffset` from `+0.9 × stageWidth` to 0 with ease-in-out (the env layers are about 3 screens wide, so the props come into view). Controls and the reticle are hidden.
3. 2.5–4.0 s, walk-in: you move from 0.25h below your ground point up to it; the opponent comes from 0.04h above his ground (by the netting) down to it. **For now use the `slide_left` clip as a stand-in walk**; Claude will add a real `walk` clip later (Rifle Walk is downloaded). Add `PaintballClip.walk` so it can be dropped in, falling back to slideLeft while the atlas has no `walk`.
4. Then 3-2-1 as today. Respect reduced motion (`MediaQuery.disableAnimationsOf`): skip straight to countdown.

## Task B: live 1v1 over Realtime Database (start with rules and the net layer)
- Add `firebase_database`. Same project (Spark plan). **Connect only during a live match**: call `FirebaseDatabase.instance.goOnline()` at match start and `goOffline()` at the end. Spark allows 100 simultaneous connections; bot mode and the lobby must never connect.
- `lib/paintball/net/paintball_rtdb.dart`, paths:
  - `/paintball/{matchId}/meta`: `{h: hostUid, g: guestUid, st: 'w'|'l'|'d', at: startAt}`
  - `/paintball/{matchId}/p/{uid}`: `{l: lane, s: stance index, a: ammo, h: hitsTaken, m: aim -1|0|1, t: ServerValue.timestamp}`. Overwrite **only when something changes**, never per frame. Both clients animate slides (0.35 s) and stance changes locally from these.
  - `/paintball/{matchId}/s/{pushId}`: `{b: uid, t: serverTime, x: aimX, y: aimY}`. Fire = one push.
  - `/paintball/{matchId}/r/{shotId}`: `{hit: bool}`, written **only by the target**, using `HitResolver.resolveFromShooterAim` at `t + 400 ms`.
- Server clock: `.info/serverTimeOffset`. `onDisconnect()` sets `p/{uid}/c: false`; more than 10 s away = forfeit. Show a small "weak connection" dot above 600 ms lag (no SnackBar).
- At the end, write ONE Firestore `/matches/{matchId}` doc (gameType `paintball`, players, hits, winner, duration, shots, accuracy); never delete it. Then remove the RTDB node.
- `database.rules.json`: only the two players can read/write `/paintball/{matchId}`; each writes only its own `p/{uid}`; `r/{shotId}` only by the shot's target. Put the rules in the repo; the developer deploys them.
- Invite flow: reuse the existing match code / friend challenge flow (see darts/archery online).
- Tests: message encode/decode, target-side resolution timing, forfeit timer.
