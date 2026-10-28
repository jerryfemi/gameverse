# Paintball arena renderer

Builds the background layers for a paintball arena (`assets/paintball/paintball_env_<arena>.*`).

The camera matches the game layout: 3.08 m high, horizon at 303 px of a 1000 px-tall frame,
focal length 1200 px, looking straight ahead. That's what puts the opponent's feet at 0.52h
(17 m away) and yours at 0.97h. Don't change it unless PaintballK's layout constants change.

1. `python tex.py` → grass.png, mud.png. `python sky.py` → sky.png. Also make macro.png (see env.html).
2. Put the prop GLBs next to env.html. Set out the scene in env.html (props at 19–28 m, |x| ≥ 5 m,
   so nothing clutters the space behind the opponent).
3. `npm i three@0.160.0 playwright`, then `node env.js` → ground_raw.png and props_raw.png.
4. Crop and export: ground = rows 303..1150 (RGBA), props = alpha bbox, sky as is. Write the JSON
   (see paintball_env_field.json) and add credits to CREDITS.md.

`PaintballBackdrop(arena: '<id>')` loads `paintball_env_<id>.json`.
