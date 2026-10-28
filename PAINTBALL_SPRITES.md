# Paintball player sprites (28 Oct)

Files in `assets/paintball/` (already listed in pubspec):
- `paintball_back_atlas.webp/.json`: your player, camera behind and above.
- `paintball_front_atlas.webp/.json`: the opponent, camera in front, near eye level.
- `CREDITS.md`: CC BY 4.0 credit for Jungle Jim's model. It must be shown in-game.

## Clips
| clip | source (Mixamo) | frames | loop |
|---|---|---|---|
| stand | Rifle Aiming Idle | 8 | yes |
| fire | Firing Rifle | 4 | no |
| crouch | Idle Crouching Aiming | 8 | yes |
| duck | Sword And Shield Crouch Idle + spine/head bent forward (head ~57 cm vs 102 cm in crouch) | 8 | yes |
| slide_left / slide_right | Crouch Walk Strafe Left/Right, kept in place | 8 | yes |
| hit | Hit Reaction | 6 | no |
| death | Death From Front Headshot | 10 | no |
| win | Cheering | 8 | yes |

## JSON (differs from glb2sprite output)
- Frame keys: `p1_<clip>_<i>`; one row per clip.
- **Each clip has its own cell size** (`clips.<clip>.cellWidth/cellHeight`), all at the same scale (tallest non-death clip = 384 px).
- `clips.<clip>.anchorX/anchorY` = the ground point under the player, in that clip's cell pixels. Draw each frame with its anchor at the player's screen position (Flame: `Anchor(anchorX / cellWidth, anchorY / cellHeight)`) and every clip lines up.
- `fps` = frames ÷ source seconds; the game can override, e.g. slides at 0.35 s.

## Who does what
Claude wires these sprites into `player_sprite.dart`. Gemini: leave that file's rendering to Claude.

## Pipeline
Mixamo would not accept the CC skeleton, so the T-pose mesh was exported without bones or marker (`Downloads/realistic-paintball-player-animated/paintball_player_mixamo.zip`) and auto-rigged. The marker (GLB `Object_19`) is skinned 100% to `mixamorigRightHand` using its bind-pose offset. Rendered headless with three.js 0.160 (warm key + #38BDF8 rim).

## In the game (28 Oct)
- `components/player_sprite.dart` loads the atlases through `PaintballPlayerAtlas.load()` (cached) and draws with `drawImageRect` from precomputed rects: no allocations per frame.
- The component's `position` is the **ground point** under the feet; `standHeight` is the on-screen height of the standing pose. Stance poses come from the sprites, not from moving the sprite down.
- Clip priority: death > win > hit (0.6 s, on `hitsTaken` going up) > slide (left/right picked from the on-screen direction) > fire (0.25 s, on `shotsFired` going up, standing only) > stand/crouch/duck. A red flicker shows invulnerability.
- Heights now match the sprites. `PaintballK.tyreCoverHeight = 0.55`: stand is exposed 0.55–1.0, crouch 0.55–0.72, duck never. The far tyre's top is drawn at that height; the reticle's `aimY` is a fraction of the standing opponent's height above their feet; the bot's aim at you uses the same scale.
- Layout constants: `farGroundY 0.52`, `oppStandHeight 0.13`, `nearGroundY 0.97`, `youStandHeight 0.40` (fractions of screen height). Tune these after seeing it on a phone.
