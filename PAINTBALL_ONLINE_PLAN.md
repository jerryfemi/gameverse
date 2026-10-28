# Paintball: live 1v1 online plan (Realtime Database)

Status: plan, 28 Oct. Bot mode, sprites, arena, sounds, intro and the body-accurate hit test are done. This covers live 1v1.
Read with: `PAINTBALL_PLAN.md` §6, `PAINTBALL_SPRITES.md`, `claude/audio-architecture.md`, and the darts/archery online code (match codes, friend challenges, results sheet).

---

## 0. Ground rules
- **Live play runs on Firebase Realtime Database (RTDB)**, in the same Firebase project. Firestore is touched **once**, at the end, for history.
- The project is on the **free Spark plan**. RTDB does **not** bill per write on Spark; the limits are:
  | Spark RTDB limit | Our budget |
  |---|---|
  | **100 simultaneous connections** | **The real limit.** About 50 live matches at once. |
  | 10 GB/month downloaded | About 25–40 KB per player per match → 100k+ matches/month. |
  | 1 GB stored | Live nodes are deleted after each match → near zero. |
- **Connect only during a live match.** Bot mode, lobby, history and solo never open an RTDB connection.
- **Event-driven, never per frame.** Write only when something changes.
- **The target decides hits** at landing time, with the same `HitResolver.resolveBody` used in bot mode.
- Never run `firebase deploy` (give the developer the commands). **Never delete completed match records** in Firestore.
- No SnackBars: connection problems show in-card or as a small HUD dot.

---

## 1. Flow

```
Lobby → "Play a friend" (existing match-code / friend-challenge flow)
  host creates  /paintball/{matchId}/meta  (st: 'w')     ← goOnline()
  guest joins   meta.g = guestUid, st: 'r' (ready)        ← goOnline()
  both present  host sets st: 'l', at: serverTime + 3500 (shared start)
  both clients: intro (4.5 s, local) → 3-2-1 → live at `at + intro`
  ... live play ...
  end: winner decided → host writes Firestore /matches/{matchId} (once)
       → st: 'd' → both goOffline() → host removes /paintball/{matchId}
```
- **Shared start:** host writes `at` (server time). Both clients start the intro so that live play begins at `at + 4500 ms` on both. A late joiner whose intro would end after that skips ahead in the intro to stay in sync.
- **Rematch:** a new `matchId` (new node, same invite pair). The intro plays again (it always does).
- Reuse the shared GameVerse results sheet / podium (SOCIAL_RESULTS_PLAN.md), not the bot-mode card.

---

## 2. Data layout (`/paintball/{matchId}`)

Short keys keep every message around 50–100 bytes.

```
meta:   { h: hostUid, g: guestUid, st: 'w'|'r'|'l'|'d', at: startMs, v: 1 }
p/{uid}:{ l: lane 0-4, s: stance 0 stand|1 crouch|2 duck, a: ammo 0-5,
          h: hitsTaken 0-3, m: aim -1|0|1, sl: slideFromLane|-1,
          t: ServerValue.timestamp, c: true }          // overwritten, never appended
s/{pushId}: { b: shooterUid, t: serverMs, x: aimX (-1..1, 3 dp), y: aimY (0..1.5, 3 dp) }
r/{shotId}: { k: 0 miss | 1 hit | 2 tyre | 3 invulnerable, x: dx stands (2 dp), y: aimY (2 dp) }
end:    { w: winnerUid|'tie', by: 'hits'|'time'|'forfeit' }
```
- `v` = protocol version; refuse mismatches with an in-card "update the app" state.
- `p/{uid}` is written **only on change**: slide start, stance change, ammo change (fire / reload tick), hit taken, aim bucket change (left/centre/right, with hysteresis so it doesn't flicker).
- `sl` lets the other side start the 0.35 s slide animation from the right lane, even if two quick slides arrive close together.
- `r/{shotId}` carries `dx/y` so the shooter can place the paint on the body exactly where the target saw it land.

---

## 3. Clocks and timing
- Read `/.info/serverTimeOffset` once at connect; `serverNow = DateTime.now().ms + offset`.
- **Shots:** the shooter pushes `s/{id}` with `t = serverNow`. Both clients animate the ball from `t` to `t + 400 ms` (`BallTrajectory.syncToTimestamp`), so a shot that arrives late starts part-way through its flight.
- **Resolution (target side):** when `serverNow ≥ t + 400`, the target runs `resolveBody` against **its own current pose and position** and writes `r/{id}`.
  - If the shot arrived after `t + 400` (lag over 400 ms), resolve immediately on arrival with the current pose. A small advantage to the target, kept simple and fair enough for casual play.
- **Shooter side:** shows the ball landing at `t + 400`. A local result is shown *only* after `r/{id}` arrives (usually under 150 ms): paint on the body for a hit, splat on the tyre, or nothing for a miss. Never guess a hit.
- **Remote movement:** on a new `p/{uid}.l`, play the slide from `sl` to `l` over 0.35 s; never teleport. Stance changes tween over 0.15 s. Both use the same `PaintballMatchState` timers as bot mode (`trySlide`, `tryChangeStance`), driven by remote events instead of the bot brain.

---

## 4. Who owns what
| Data | Written by | Read by |
|---|---|---|
| `meta` | host (guest only sets `g` and `st:'r'`) | both |
| `p/{uid}` | that player only | the other |
| `s/*` | the shooter | both |
| `r/{shotId}` | **the target of that shot only** | both |
| `end` | host | both |
| Firestore `/matches/{id}` | host, once | history, H2H |

- **Hits are counted from `r/*`**, not from `p.h`: each side applies `applyDamage()` when it sees a `k:1` for a shot at that player. `p.h` is a cross-check; on disagreement trust the target's `p.h`.
- **Match end:** whoever sees the 3rd hit (normally both within a frame) shows death/win. The **host** writes `end` and the Firestore record. If the host has left, the guest does it.
- **Timer:** both run the 90 s clock from the shared `at`. Sudden death per the bot-mode rules.

---

## 5. Connection handling
- `onDisconnect()` on `p/{uid}`: `{c: false}`. On connect, set `c: true`.
- Opponent `c: false` → pause their character in place with a small "reconnecting" pill (no SnackBar). After **10 s**, a forfeit: write `end {by:'forfeit'}` and the Firestore record.
- **Lag dot:** estimate RTT from `p` write echoes (`t` vs local send time). Show a small amber dot above 300 ms and red above 600 ms, top centre by the timer.
- App backgrounded (tab hidden) during a live match: keep the connection for 10 s, then treat it as a disconnect.
- **Always `goOffline()`** after the match, on leaving the screen, and on errors. That's the guard for the 100-connection limit.

---

## 6. Security rules (`database.rules.json`, developer deploys)
```json
{
  "rules": {
    "paintball": {
      "$m": {
        ".read": "auth != null && (data.child('meta/h').val() === auth.uid || data.child('meta/g').val() === auth.uid)",
        "meta": {
          ".write": "auth != null && (!data.exists() && newData.child('h').val() === auth.uid || data.child('h').val() === auth.uid || (data.child('g').val() === null && newData.child('g').val() === auth.uid))"
        },
        "p": { "$uid": { ".write": "auth != null && auth.uid === $uid && (root.child('paintball/'+$m+'/meta/h').val() === auth.uid || root.child('paintball/'+$m+'/meta/g').val() === auth.uid)" } },
        "s": { "$id": { ".write": "!data.exists() && newData.child('b').val() === auth.uid", ".validate": "newData.hasChildren(['b','t','x','y'])" } },
        "r": { "$id": { ".write": "!data.exists() && auth.uid !== root.child('paintball/'+$m+'/s/'+$id+'/b').val() && (root.child('paintball/'+$m+'/meta/h').val() === auth.uid || root.child('paintball/'+$m+'/meta/g').val() === auth.uid)" } },
        "end": { ".write": "root.child('paintball/'+$m+'/meta/h').val() === auth.uid || root.child('paintball/'+$m+'/meta/g').val() === auth.uid" }
      }
    }
  }
}
```
- The `.read` rule needs the `meta` node to exist first (host creates it). Test the rules in the emulator before deploying.
- Deploy command for the developer: `firebase deploy --only database`.

---

## 7. Bandwidth estimate (per 90 s match)
| Event | Count per player | Size |
|---|---|---|
| `p` updates (slides, stances, ammo, aim bucket) | ~80–110 | ~70 B |
| shots `s` | ~15–25 | ~80 B |
| results `r` | ~15–25 | ~40 B |
- About 12 KB of payload per player, ~25–40 KB with protocol and TLS overhead, received by the other player. The 10 GB/month limit allows 100,000+ matches.

---

## 8. Code structure
```
lib/paintball/net/
  paintball_rtdb.dart      // connect/goOnline/goOffline, paths, listeners, writes, onDisconnect
  paintball_protocol.dart  // pure Dart: encode/decode p, s, r, meta, end (unit-tested)
  paintball_clock.dart     // server offset, serverNow
  paintball_session.dart   // glue: local input → writes; remote events → match_state
lib/paintball/logic/
  opponent_driver.dart     // interface: BotDriver (existing bot_brain) | RemoteDriver (session)
```
- `PaintballGame` takes an `OpponentDriver`. Bot mode = `BotDriver`; online = `RemoteDriver`. The game, sprites, intro, hit test and HUD are shared, with no `if (online)` branches inside rendering.
- `firePlayerShot` → `session.sendShot(aimX, aimY)` (the local ball still flies immediately from `serverNow`).
- `_handleBallLanding` (online): if the target is **you**, resolve and write `r`. If the target is the opponent, wait for `r`.
- Routing: `/paintball` = bot; `/paintball/:matchId` = online (same screen, different driver).

---

## 9. Build order (each step testable)
1. **Protocol + clock** (pure Dart, tests): encode/decode, rounding, version check.
2. **Connect/disconnect discipline:** goOnline at match start, goOffline on every exit path. Test: the lobby never shows an RTDB socket in devtools.
3. **Meta handshake** with the existing invite flow: create, join, ready, shared `at`. Test in two browsers.
4. **Movement sync:** `p/{uid}`, remote slides and stances via `RemoteDriver`.
5. **Shots + target-side results**, paint placement from `r`.
6. **Match end:** `end`, results sheet, Firestore record (once, never deleted), RTDB cleanup.
7. **Disconnects:** reconnecting pill, 10 s forfeit, lag dot.
8. **Rules** in the emulator, then the developer deploys.

## 10. Tests
- Protocol round-trips; unknown version rejected.
- A shot resolved at `t + 400` uses the pose at that moment (fake clock).
- A late shot (> 400 ms) resolves on arrival.
- The `r` writer is always the target (session unit test with fake RTDB).
- Forfeit after 10 s without `c`.
- Hits counted once per `r` even if listeners fire twice.
- Two-browser manual checklist: invite, intro sync, slides, stance, shots both ways, hit paint, 3-hit end, rematch, close the tab mid-match → forfeit.

## 11. Don't
- Don't write positions or the aim every frame.
- Don't let the shooter decide hits.
- Don't keep RTDB connected outside a live match.
- Don't use Firestore during play.
- Don't delete the Firestore match record. Do delete the RTDB live node.
- Don't run `firebase deploy`.
