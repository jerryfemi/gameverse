# PAINTBALL — Implementation Plan (GameVerse)

> **Read this whole file before writing any code.** Work phase by phase, in order.
> Finish each phase, run it, and confirm with the developer before starting the next.
> Every rule in the project instructions (Flutter Web + Flame, 60 fps, no allocations in
> `render()`/`update()`, no SnackBars, Riverpod + hooks, **never run `firebase deploy`**,
> **never delete completed matches**) applies here too.

---

## 0. What we're building

A **live 1v1 paintball duel**, in the spirit of GamePigeon's paintball, but in real time and better looking.

- Two players face each other across a field, each behind a row of **5 tyre stacks**.
- You see your own character **from behind** (third-person, over the shoulder). The opponent is far away, behind their tyres.
- **Left/right buttons** slide you to the neighbouring tyre stack.
- **Up/down buttons** switch stance: **stand** (can shoot, fully exposed), **crouch** (can peek and shoot, half exposed), **duck** (hidden behind the tyre, can't shoot).
- **Aiming:** drag on the **right half of the screen** to move a reticle across the far field. The camera pans gently with it. You don't have to slide to the opponent's lane to hit them; just aim there.
- **FIRE** shoots a paintball that flies for about 0.4 s. A hit is decided by where the opponent actually is **when the ball lands**, so ducking in time saves you.
- First to **3 hits** wins. Rounds are 60–90 seconds.

Reference image: `docs/images/paintball-prospect.png`, rendered from the real asset packs (Swat character = you, Worker = opponent, rifle from the gun pack).

---

## 1. The asset packs the developer has (all CC0, free for commercial use)

All are by **Quaternius** (quaternius.com). CC0 means no credit is required, but add a "Models by Quaternius" credit anyway.

### 1a. Ultimate Modular Men (Feb 2022)
Folder: `Downloads/Ultimate Modular Men- Feb 2022/`

| Folder | Use |
|---|---|
| `Individual Characters/glTF/*.gltf` | **Use these.** One self-contained file per character, rigged, with all 24 animations. The sprite renderer already loads glTF. |
| `Humanoid Rig/Individual Characters/FBX/*.fbx` | Same characters with **no animations**, on a standard humanoid rig. **Upload these to Mixamo** to get extra animations (crouch, kneel). |
| `Individual Characters/FBX`, `Blends`, `All together`, `Separate Skeletal Meshes…` | Not needed. |

**Characters (11):** Adventurer, Beach, Casual_2, Casual_Hoodie, Farmer, King, Punk, Spacesuit, Suit, **Swat**, **Worker**.
Recommended teams: **Swat** (blue team) vs **Worker** (orange team). Others can be unlockable skins later.

**Built-in animations (on every character):**
`Death, Gun_Shoot, HitRecieve, HitRecieve_2, Idle, Idle_Gun, Idle_Gun_Pointing, Idle_Gun_Shoot, Idle_Neutral, Idle_Sword, Interact, Kick_Left, Kick_Right, Punch_Left, Punch_Right, Roll, Run, Run_Back, Run_Left, Run_Right, Run_Shoot, Sword_Slash, Walk, Wave`

The ones we use:

| Game state | Animation |
|---|---|
| Standing idle, aiming | `Idle_Gun_Pointing` |
| Standing, firing | `Idle_Gun_Shoot` (or `Gun_Shoot`) |
| Sliding left / right | `Run_Left` / `Run_Right` |
| Got hit | `HitRecieve` |
| Final hit (lose) | `Death` |
| Win celebration | `Wave` |

**Missing:** crouch and duck. These come from Mixamo (section 2).

**glTF bone names:** three.js strips the dots, so `Wrist.R` becomes **`WristR`**. Each character also carries a built-in `Pistol` node; hide it when attaching the rifle.

### 1b. Animated FPS Guns (Jun 2018)
Folder: `Downloads/Animated FPS Guns - Jun 2018/`
6 guns in `FBX/`: **P90, Pistol, Revolver, Rifle, Shotgun, SniperRifle**. Each has its own animations:

| Gun | Animations |
|---|---|
| P90 | `Fire` 0.23 s, `Reload` 0.8 s |
| Pistol | `Fire`, `Slide`, `Reload` |
| Revolver | `Fire`, `Reload` 1.9 s |
| Rifle | `FireWOBullet`, `FireWBullet`, `Reload` |
| Shotgun | `FireWBullet`, `FireWOBullet`, `Reload` |
| SniperRifle | `FireWOBullet`, `FireWBullet`, `Reload` |

⚠️ **The colours are lost in the FBX/OBJ exports.** Every material loads white or grey. The material **names** survive, so we colour by name:

```
Metal → #3A3F47   Black → #1A1C20   Barrels → #2B2F35
DarkWood → #5B3A22   LightWood → #8A5A35
BulletOrange → #F97316   BulletYellow → #FACC15
Muzzle/Magazine/DarkerMetal → #2E3238 (fallback for any unknown name)
```

Default paintball marker: **Rifle** (it reads best at small sizes). Other guns can be cosmetics later.

---

## 2. Getting crouch/duck animations from Mixamo (developer does this, step by step)

Mixamo is free with a free Adobe account; no payment is needed.

1. Go to **mixamo.com** → sign up / sign in (free Adobe ID).
2. Click **Upload Character** → choose `Humanoid Rig/Individual Characters/FBX/Swat.fbx`.
   - Mixamo should detect the existing rig. If it asks for markers (chin, wrists, elbows, knees, groin), place them and continue.
3. In the **Animations** tab, search for and preview each of these:

   | Search for | Use as | Notes |
   |---|---|---|
   | `Crouch Idle` or `Rifle Crouch Idle` | **crouch** stance (half exposed) | pick one where the gun is held up |
   | `Crouching` / `Crouch to Stand` | transition (optional) | |
   | `Kneeling Idle` | alternative crouch | |
   | `Rifle Aiming Idle` | standing aim (if better than the pack's) | |
   | `Hit Reaction` | alternative hit | optional |

   For **duck** (fully hidden), use the crouch animation with the camera hiding them behind the tyre. If a deeper pose is needed, search `Take Cover` / `Cover Idle`.
4. For each animation:
   - Tick **In Place** (if offered) so the character doesn't drift.
   - Click **Download** → Format **FBX Binary**, Skin **With Skin**, 30 fps.
5. Repeat steps 2–4 for **Worker.fbx** (or reuse the Swat animations on the Worker if the sprite renderer supports retargeting; it's simpler to download for both).
6. Save the downloads to `Downloads/paintball-mixamo/<Character>/<Animation>.fbx`.

---

## 3. Sprite renderer upgrades (`tools/sprite_renderer.html`, also published as glb2sprite)

Today the renderer loads `.glb`/`.gltf`, renders a **static** model at one camera angle, with spin frames, tilt frames and an angle sweep. It outputs `<name>_atlas.png` + `<name>_atlas.json` in a zip.

Add the following, in this order:

### 3a. FBX loading
- Use `FBXLoader` from three.js (`three/examples/jsm/loaders/FBXLoader.js`), same three.js version as the page already uses.
- Accept `.fbx` in the file picker and drag-drop, alongside `.glb`/`.gltf`.
- For skinned meshes, **clone with `SkeletonUtils.clone()`**, never `object.clone()`. A plain clone keeps the original bones, so the clone renders at the wrong size and place. (We hit this exact bug making the prospect image.)

### 3b. Colour by material name
- A small editable table: material name → hex colour. Prefill with the gun palette from section 1b.
- On load, replace each material with `MeshStandardMaterial({color, roughness: .55, metalness: .3})` using that table; unknown names use the fallback.

### 3c. Animation frames (the big one)
- After loading, list every `AnimationClip` in the file (glTF `gltf.animations`, FBX `object.animations`).
- Also allow **loading extra animation FBX files** (from Mixamo) and applying their clips to the loaded character with an `AnimationMixer`. Mixamo bone names differ (`mixamorig:Hips` etc.), so add a **bone-name mapping** step: strip `mixamorig:` and map to the Quaternius names. If retargeting proves too hard, fall back to loading the Mixamo FBX **as the character itself** (it was exported "With Skin", so it includes the mesh).
- UI per clip: tick to include, **frame count** (default 8; 4 for short clips like `Gun_Shoot`), **loop** yes/no.
- Rendering: for each included clip, step `mixer.setTime(t)` across the clip's duration, render each frame into the atlas.
- **Same crop box for every frame of every clip** (union of all frames' bounding boxes), so nothing jitters when switching animations.

### 3d. Attach a prop to a bone
- "Attach model" picker: load a second file (the gun) and choose a bone from a dropdown (default `WristR`).
- Position / rotation / scale sliders for the attached prop, with a live preview, plus "Hide built-in node" (e.g. `Pistol`).
- **Easier alternative that worked for the prospect image:** instead of parenting to the bone, place the gun in world space every frame: scale it to ~0.8 m long, rotate it to the character's facing (long axis = z), and move its bounding-box centre to `hand position + 0.18 m forward`. Offer this as the "auto-hold" mode.

### 3e. Camera presets for this game
- **Back view** (your own character): camera behind and above, looking forward.
- **Front view** (opponent): camera in front, looking at them, small (they're far away).
- Use the same lighting preset for both (warm key light + `#38BDF8` rim light).

### 3f. Output
Atlas JSON frame keys: `<clip>_<i>`, e.g. `Idle_Gun_Pointing_0..7`, `Run_Left_0..7`, `crouch_0..7`. Add a top-level `"clips": {"Run_Left": {"frames": 8, "fps": 12, "loop": true}, ...}` so the game can build animations without hard-coding.

---

## 4. Sprites to produce

For **each team character (Swat, Worker)**, render two atlases:

| Atlas | Camera | Clips (frames) |
|---|---|---|
| `<char>_back` (you) | back view | `stand` = Idle_Gun_Pointing (8), `fire` = Idle_Gun_Shoot (4), `crouch` (8), `duck` (8), `slide_left` = Run_Left (8), `slide_right` = Run_Right (8), `hit` = HitRecieve (6), `death` (10), `win` = Wave (8) |
| `<char>_front` (opponent) | front view | same clips |

Plus:
- `paintball.png`: a small glossy ball, one per team colour (pink `#EC4899` and blue `#38BDF8`).
- `splat_*.png`: 3–4 splat decals per colour.
- **Tyre stacks:** don't use the procedural shapes from the prospect image. Find a CC0 tyre model (Quaternius, Kenney or Poly Pizza) and render a **single sprite of a 4-tyre stack** from the near angle and from the far angle.
- **Background:** one painted/rendered backdrop (sky, tree line, field), WebP, ≤ 1600 px tall.

Save as WebP under `assets/paintball/`.

---

## 5. Gameplay rules

### 5a. Layout
- Each side has **5 lanes** (tyre stacks), index `0..4` left to right from that player's view.
- Player state: `lane (0–4)`, `stance (stand | crouch | duck)`, `ammo (0–5)`, `hits taken (0–3)`.
- **Mirroring:** your lane 0 (far left from your view) faces the opponent's lane 4. Convert with `oppLaneOnMyScreen = 4 − oppLane`.

### 5b. Controls (portrait phone)

| Control | Where | Action |
|---|---|---|
| ◀ ▶ buttons | bottom-left | Slide to the neighbouring lane. Plays `slide_left`/`slide_right`, takes **0.35 s**, and you can't fire while sliding. |
| ▲ ▼ buttons | bottom-right, left of FIRE | Stance up/down: duck ↔ crouch ↔ stand. Each change takes **0.15 s**. |
| **Drag on the right half of the screen** | anywhere right of centre, above the buttons | Moves the **aim reticle** across the far field (relative drag, like a trackpad). The camera pans with it (see 5c). |
| **FIRE** | bottom-right | Fires at the reticle. Disabled while ducked, sliding or reloading. |

- Ammo: 5 balls. Reload happens automatically while **ducked** (one ball every 0.4 s) and only while ducked, so reloading forces you into cover.
- The reticle also has vertical movement (so you aim at head height vs. low), but snap-assist pulls it gently toward the opponent's body if within ~20 px.

### 5c. Camera pan
- The camera's look-at target follows the reticle horizontally, at most **±15%** of screen width, with a damped spring (ζ ≈ 1, ~250 ms settle).
- Pan is visual only: it shifts the backdrop and the far field by parallax (backdrop × 0.3, far tyres × 0.8, your own character × 1.0 stays put). This sells "aiming across the field" without changing lanes.

### 5d. Shots and hits
- On FIRE: send a shot event `{shooter, t0 (server-synced ms), aimX (−1..1 across the far field), aimY (0..1 height)}`.
- The ball flies on a slight arc for **400 ms** (constant; it makes the network timing fair and readable).
- **Hit check (on the target's device, at landing time `t0 + 400 ms`):**
  - Work out which lane `aimX` lands in, and the height `aimY`.
  - **Hit** if the target is in that lane **and** their stance exposes that height:
    - `stand`: exposed from 0.35 to 1.0
    - `crouch`: exposed from 0.55 to 0.8 (head and shoulders above the tyre)
    - `duck`: never exposed
  - Otherwise the ball hits the tyre or flies past → splat decal on the tyre, sound, no damage.
- The target reports `hit`/`miss` back. Both clients play the result.
- **Mid-slide:** a sliding player counts as being in **both** lanes (the one they left and the one they're entering) for the first half of the slide, then only the new lane.

### 5e. Match flow
- Countdown 3-2-1, then live play.
- First to **3 hits** wins. If the 90 s timer runs out, fewest hits taken wins; if tied, **sudden death** (next hit wins).
- On a hit: `hit` animation, paint splat on the character, short screen shake for the victim, 1 s invulnerability.
- Final hit: `death` for the loser, `win` for the winner, then the podium (reuse the shared results sheet: section 9).

---

## 6. Networking (live) — Firebase Realtime Database

**Do not use Firestore for live play.** Firestore bills every write; a live match sends dozens of writes per player. Use **Firebase Realtime Database (RTDB)** in the **same Firebase project** (add `firebase_database`). RTDB bills bandwidth, not operations, and these messages are tiny.

### 6a. Paths
```
/paintball/{matchId}/
   meta:    { hostUid, guestUid, status: waiting|live|done, startAt, winner }
   players/{uid}: { lane, stance, ammo, hits, ts }      // overwrite on every change
   shots/{pushId}: { by, t0, aimX, aimY }              // append-only
   results/{shotId}: { hit: bool, by: targetUid }       // written by the target
```
- Write `players/{uid}` **only when something changes** (lane, stance, ammo, hits), not every frame.
- Use `ServerValue.timestamp` + `.info/serverTimeOffset` to share a clock between both clients.
- `onDisconnect()`: set your player `{connected: false}`. If the opponent disconnects for > 10 s, they forfeit.

### 6b. Smoothing
- Remote player: when a new `lane` arrives, play the slide animation from the old lane to the new one (0.35 s). Never teleport.
- Remote stance: tween over 0.15 s.
- Lag above ~300 ms is hidden by the 400 ms ball flight. Above 600 ms, show a small "weak connection" dot (no SnackBar).

### 6c. Match record (Firestore, once)
- When the match ends, write **one** document to the normal `/matches/{matchId}` (game type `paintball`, players, hits, winner, duration, shots fired, accuracy) so it shows in history, results and head to head.
- **Never delete it.** Delete the RTDB live node after the match ends; it isn't the history.

### 6d. Security rules (RTDB)
- Only the two players can read/write `/paintball/{matchId}`.
- A player can only write their own `players/{uid}`.
- `results/{shotId}` can only be written by the target of that shot.

### 6e. Bot mode (solo, build this FIRST)
Same game with no network. The bot:
- Every 1.2–2.5 s picks: slide (30%), change stance (40%), shoot at your current lane (30%).
- Reaction delay of 250–450 ms before ducking from an incoming ball, with a 35% chance of not ducking (difficulty knob).

---

## 7. Code structure

Mirror `lib/darts/` and `lib/archery/`:

```
lib/paintball/
  paintball_constants.dart     // lanes, timings, exposure heights, colours
  paintball_game.dart          // FlameGame: world, camera pan, input routing
  components/
    backdrop.dart              // sky + trees + field, parallax layers (rasterised once)
    tyre_stack.dart            // sprite, near/far variants, splat decals
    player_sprite.dart         // SpriteAnimationGroupComponent, keyed by state
    paintball.dart             // ball in flight (arc), pooled; never allocate per shot
    reticle.dart
    splat.dart                 // decals, pooled
  logic/
    match_state.dart           // pure Dart: lanes, stance, ammo, hits, rules (unit-testable)
    hit_resolver.dart          // pure Dart: exposure check (unit-test this!)
    bot_brain.dart
  net/
    paintball_rtdb.dart        // RTDB paths, listeners, writes, onDisconnect
  ui/
    paintball_hud.dart         // hit pips, timer, ammo, buttons (Flutter overlay)
    paintball_controls.dart    // ◀ ▶ ▲ ▼ FIRE + right-half drag area
lib/main_paintball.dart        // entry like main_darts.dart
assets/paintball/              // atlases (WebP + JSON), backdrop, splats
```

- Player sprite states: `stand, fire, crouch, duck, slideLeft, slideRight, hit, death, win`. Build from the atlas JSON `clips` block.
- Depth order, back to front: backdrop → far tyres' back layer → **opponent** → far tyres' front layer → flying ball → near tyres → **your player** → HUD.
- Pool paintballs and splats (fixed arrays). Cache every `Paint`. No allocations in `update()`/`render()`.

---

## 8. HUD (follow the prospect image and the GameVerse obsidian style)

- **Top:** your pill on the left (avatar + 3 hit pips in `#38BDF8`), timer in the centre, opponent pill on the right (3 pips in `#F59E0B`). A pip empties when that player is hit.
- **Bottom-left:** 5 ammo pips (pink) above the ◀ ▶ buttons (58 px circles, obsidian `rgba(10,14,26,.8)`).
- **Bottom-right:** ▲ ▼ (50 px) stacked, then **FIRE** (86 px, `#EF4444`, white ring, glow when ready, dimmed when disabled).
- **Reticle:** red ring (34 px), turns solid when over the opponent's exposed body.
- Light haptic on FIRE and on taking a hit. Nothing else vibrates.
- Pause menu: reuse the shared GameVerse pause menu, in a live match **Restart becomes Forfeit**.

---

## 9. Results

Reuse the shared results sheet / podium from `SOCIAL_RESULTS_PLAN.md`. Paintball stats rows: **Hits**, **Shots fired**, **Accuracy**, **Times dodged** (balls that would have hit if you hadn't ducked), **Longest survival**.

---

## 10. Build order (each phase ends with a working, testable build)

1. **Sprites first (developer + sprite renderer).** Section 3 upgrades, then section 4 atlases. Until real atlases exist, use coloured rectangles for players so code isn't blocked.
2. **Static scene:** backdrop, 5 near + 5 far tyre stacks, your player sprite in lane 2, camera, depth order. 60 fps on a phone.
3. **Local controls:** ◀ ▶ slide with animation, ▲ ▼ stance, right-half drag reticle with camera pan.
4. **Shooting vs a dummy:** FIRE, ammo, reload-while-ducked, ball arc, `hit_resolver.dart` with unit tests, splats.
5. **Bot mode:** `bot_brain.dart`, match flow (3 hits, timer, sudden death), win/lose animations, results sheet. **This is a shippable solo game.**
6. **Live 1v1 over RTDB:** section 6, invites through the existing match code / friend challenge flow.
7. **Polish:** sounds (paintball pop, splat, hit grunt) through `AudioEngine` (flutter_soloud, preloaded), screen shake, a theme music track, cosmetics (other guns and characters).

---

## 11. Don't

- Don't use Firestore for anything per-frame or per-shot during a live match.
- Don't render 3D at runtime (no three_dart / flame_3d). Everything is pre-rendered sprites.
- Don't use `object.clone()` on skinned meshes; use `SkeletonUtils.clone()`.
- Don't teleport remote players; always animate the slide.
- Don't let the shooter's device decide hits; the **target** decides at landing time.
- Don't add 8-direction sprites; only back view (you) and front view (opponent) are needed.
- Don't use `audioplayers`/`just_audio`, SnackBars, or blur over the live game.
- Don't run `firebase deploy`. Give the developer the commands instead.
- Don't delete completed match records.
