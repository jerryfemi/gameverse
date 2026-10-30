# Darts Practice Mode: Implementation Plan

> A free-throw practice mode so players can sharpen their aim before playing the bot or a friend.
> No timer, no opponent, no scoring rules, unlimited darts, **nothing saved**.
> All project rules still apply: 60 fps, no allocations in `render()`/`update()`, no SnackBars,
> Riverpod + hooks, and never run `firebase deploy`.

## 1. What the player gets
- Throw darts at the board with exactly the same controls, flight, sounds and score pop-ups as a normal match.
- After the **3rd dart lands**, wait **0.8 s** so they can see the grouping, then all three darts **pull out** (the existing stuck-dart pull/fade animation, `DartsK.dartPullFadeSec`) and the next set begins.
- **Tap the board** at any time after at least one dart has landed to clear early. Ignore taps while a dart is in flight.
- The HUD shows only:
  - the darts left in this set (the existing 3-dart indicator);
  - each dart's score as it lands (the existing count-up and ticks);
  - the **set total** after the 3rd dart (e.g. "60"; "180!" gets the existing big-score celebration if there is one).
- No round counter, no "LEFT" scores, no player badges, no bot, no turn switching, no podium.

## 2. What it does NOT do
- No Firestore reads or writes. No `/matches` document. No `shared_preferences`. Nothing persists.
- No bust or checkout rules (it isn't 301). Every dart simply scores what it hits.
- No timer, no end state. The player leaves through the pause menu.

## 3. Entry points
- **Lobby:** add a secondary **"Practice"** button on the Darts card, next to Play. Obsidian ghost style (`#1E2638` fill, white text), same height as Play.
- **Optional, nice to have:** when waiting on the opponent's turn in an online darts match, show a small "Practice while you wait" link that opens practice. Leaving practice returns to the match screen. Skip this if it complicates navigation.

## 4. Implementation
1. **Mode flag.** Add a `DartsMode { match, practice }` (or reuse an existing mode enum) and pass it into the darts game and screen. All practice branches check this flag; don't fork the game into a second class.
2. **Skip in practice mode:**
   - bot creation and bot turns;
   - turn handover and player switching;
   - 301 scoring, bust and checkout logic, round counting;
   - the result card and podium;
   - any Firestore or online code paths.
3. **Set handling:**
   - Keep a fixed pool of **3 stuck-dart components** for practice. Reuse them every set; never create new ones. Unlimited play must keep memory flat.
   - `onDartLanded`: score it (existing scorer), show the pop-up, increment `dartsThisSet`.
   - When `dartsThisSet == 3`: show the set total and start a **0.8 s** timer (a field counted down in `update()`, not a `Future.delayed`), then trigger the pull on all three, reset `dartsThisSet = 0`, and enable the next throw once the pull finishes.
   - **Tap to clear:** same pull, triggered immediately. Only allowed when `dartsThisSet > 0` and no dart is in flight.
   - Block new throws while darts are being pulled, so a dart can't land on a board that's being cleared.
4. **HUD:** hide the score badges, round pill and opponent UI in practice. Show a small top pill reading **"PRACTICE"** with the dart indicator, plus the set total near the board after the third dart (fades with the pull).
5. **Pause menu:** reuse the shared GameVerse pause menu. In practice mode show **Resume**, **Lobby**, and the sound settings. Hide Restart and Forfeit (there's nothing to restart).
6. **Audio:** the same SFX as a match. Use the darts theme music, following the user's music volume setting.

## 5. Acceptance checklist
- [ ] Practice opens from the lobby Darts card with no network calls (check DevTools Network tab: no Firestore traffic).
- [ ] 3 darts land, a 0.8 s pause, all 3 pull out, then throwing continues. Repeats indefinitely.
- [ ] Tapping the board with 1–2 darts in it clears them early; tapping while a dart flies does nothing.
- [ ] 100+ sets in a row: steady 60 fps, no growth in component count (Flame debug or a print of `children.length`).
- [ ] No bot, no turn switch, no podium, no "LEFT" scores appear.
- [ ] Pause shows Resume, Lobby and sound only; Lobby returns cleanly and music stops or switches correctly.
- [ ] Match mode (vs bot and online) behaves exactly as before.
- [ ] `flutter build web --release` builds cleanly.

## 6. Don't
- Don't save anything (no Firestore, no local storage).
- Don't allocate new dart components per throw or per set.
- Don't use `Future.delayed` for the clear pause; use a timer field in `update()` so pausing the game pauses it too.
- Don't change match-mode behaviour.
- Don't run `firebase deploy`.
