# GameVerse: Social & Results implementation plan

Implementation guide for the "GameVerse Social & Results" design canvas (11 artboards). Work **one section at a time**, in the order below. Each section is self-contained, compiles on its own, and can ship on its own.

Before every section:
- Open the matching artboard image(s) and match spacing, colours and wording.
- Run `flutter analyze` and `flutter test` when done. Don't start the next section until both pass.

---

## 0. Ground rules (read first, apply everywhere)

**Project rules (CLAUDE / project instructions):**
- 60 FPS on mobile web.
- No `Paint()`, `Rect`, `List` or other allocations inside Flame `render()`/`update()`.
- Riverpod (`hooks_riverpod`) + `flutter_hooks`.
- No SnackBars: errors animate inside the card with a RETRY button.
- Light/medium haptics only, and only on taps.
- **Never delete completed matches** unless the user taps the trash icon.

**No `BackdropFilter` over a live game canvas.** It re-blurs every frame (this was removed in the performance pass). Use solid translucent fills (`0xF00F172A`) instead. Blur is allowed only on full-screen sheets, where the game behind is paused or static.

**Palette:**
- Surfaces: `#0A0E1A`, `#0B1020` (sheet), `#111827` (cards), `#1E2638` (raised and secondary buttons).
- Text: white headings, `#94A3B8` labels, `#64748B` meta.
- You = sky `#38BDF8`; opponent = amber `#F59E0B`.
- Win/positive = mint `#00FFCC`; loss = red `#F87171` text on `rgba(239,68,68,.10–.16)`.
- Crown/gold: `#FBBF24`.

**Type:** the Inter variable font via `UiFont`.
- Section labels: 11 px, w800, letter-spacing 0.1em, uppercase.
- Titles: 22–34 px, w900, slight negative tracking.

**Shapes:**
- Corner radius: cards 20, inner panels 16, buttons 12–14, pills fully round.
- Touch targets ≥ 44 px, except in-game micro buttons (22 px), which get a 44 px invisible hit area.

**Motion (Apple design skill):**
- Default spring is critically damped (damping 1.0, response 0.3–0.4 s).
- Things that grow from an element grow **from that element** (anchored origin) and shrink back the same way.
- Respect `MediaQuery.disableAnimationsOf(context)`: cross-fade instead of scale or slide.

**Reuse before creating:** `AppAvatar` (`game/ui/common/app_avatar.dart`), `CleanUi`/`CleanButton` (`game/ui/common/clean_ui.dart`), `ui_font.dart`, `ArcheryRoundButton` (`archery/ui/archery_match_bar.dart`).

**New shared code goes in `lib/social/`:**

```
lib/social/
  models/match_summary.dart        // game-agnostic view of a finished CloudMatch
  models/head_to_head.dart         // record between two players
  providers/social_providers.dart  // h2h + friendship providers
  ui/results/results_sheet.dart    // shared results sheet shell
  ui/results/darts_results_body.dart
  ui/results/hoops_results_body.dart
  ui/results/archery_results_body.dart
  ui/results/race_to_zero_chart.dart
  ui/tiles/completed_match_tile.dart
  ui/tiles/active_match_tile.dart
  ui/profile/profile_sheet.dart
  ui/profile/matches_page.dart
  ui/profile/friends_page.dart
  ui/in_game/opponent_badge_social.dart  // + button, chip, peek, h2h panel
  ui/in_game/h2h_card.dart
  ui/common/verdict_banner.dart, crown_avatar.dart, game_chip.dart, section_label.dart
```

---

## Section 1. Shared building blocks (no visible change yet)

Artboards: none. These are used by every later section.

1. **`GameChip`.** A pill with an icon and a label per game id:
   - `darts`: target icon, red-ish `#F87171`, label "Darts 301".
   - `hoops`: basketball icon, amber, label "Hoops".
   - `archery`: arrow icon, mint, label "Archery".

   Read the game id from `CloudMatch.game`.
2. **`CrownAvatar`.** Wraps `AppAvatar`.
   - `crowned: true` adds a gold ring (2 px `#FBBF24` plus a soft glow) and a crown above it, centred, overlapping the top by about 40%. Draw the crown as a small vector path (a `CustomPainter` is fine; it's a widget, not Flame).
   - Sizes 40 / 52 / 68.
   - Optional `online` dot: 12 px `#22C55E` with a 2.5 px sheet-coloured border.
3. **`VerdictBanner(win: bool, line: String)`.**
   - Tile style: a tinted row with "VICTORY" or "DEFEAT" (18 px w900, 0.08em) followed by the sentence.
   - Hero style for sheets: "YOU WON" or "YOU LOST" (34 px w900) with the sentence underneath.
4. **`SectionLabel(text, trailing?)`.**
5. **`MatchSummary` (pure Dart, unit-tested).** Build it from a `CloudMatch` plus `myUid`:
   - `game`, `finishedAt`, `me` / `opponent` (uid, name, avatar), `didIWin` (null = draw), `byForfeit`.
   - `verdictLine`: a plain sentence. Examples:
     - "You checked out in round 7"
     - "Boogyman checked out · you had 32 left"
     - "You won by 6 points"
     - "Boogyman reached 6 set points"
     - "Boogyman left the match"
   - `myHeadline` / `theirHeadline` + `myUnit` / `theirUnit`, in each game's own terms:
     - darts: "Checked out" or "32 left";
     - hoops: "24 pts";
     - archery: "4 sets".

   **This is the fix for the confusing "0 vs 5" darts tiles.**
   - Winner: use the existing `CloudMatch.outcome` logic (it already handles archery set points and darts checkout and dart count). **Don't re-implement the rules.**
   - Darts remaining: `DartsRules.remaining(player.roundScores)`.
   - Archery set points: `ArcheryRules`.
   - Hoops: sum of `roundScores`.
6. **Tests:** `test/social/match_summary_test.dart`. Cover each game (win, loss, forfeit) and check that darts never produces a bare "0".

---

## Section 2. Results sheet (artboards 6, 7, 8)

Goal: **View results never opens a game.** It shows the saved match data in one shared sheet.

1. **`ResultsSheet.show(context, CloudMatch m)`.** A full-screen modal sheet, about 96% of the height, with a grabber; drag down to dismiss with velocity projection. **Shared header:**
   - `GameChip`, the date ("Today · 10:42" or "Oct 22"), and a close button.
   - Two `CrownAvatar`s at 68 px with "VS" between them; the crown goes on the winner.
   - Hero `VerdictBanner`.
   - Two score cards (you = sky tint and border, opponent = amber), each with name, headline and unit, taken from `MatchSummary`.
2. **Game body, chosen with a `switch` on `m.game`:**
   - **Darts:**
     - `RaceToZeroChart`: a `CustomPainter` with one line per player of points left after each round, plus the y-axis labels 301 / 150 / 0 and R1…Rn.
       - Data: cumulative `roundScores`; a bust turn = 0.
       - Mint dot where a line hits 0.
     - Stats table rows: 3-dart avg, Best turn, Tons (≥ 100), Darts thrown, Busts. If `roundSummaries` carries darts per turn and checkout, add Checkout. Missing data shows "—"; never invent it.
   - **Hoops:** round-by-round table (R1, R2, Total) from `roundScores`. Stats: shots made `madeShots/totalShots`, accuracy %, swishes, best streak. Bank shots only if stored.
   - **Archery:** set-by-set rows with each player's three arrows (from `roundSummaries` if present, otherwise only the set total), set total, and a set-points chip (+2 / +1 / +0) from `ArcheryRules`. Stats: Xs, arrow average, best set.
   - **Table style:** a 3-column grid (your value | label | their value). The better value is white w900, the other slate w600.
3. **Shared footer:**
   - "HEAD TO HEAD · You lead 7–4 ›", which opens the H2H view (Section 6).
   - **REMATCH** (sky, 2/3 width) and **Share** (1/3).
   - Rematch reuses the existing `XChallenge.rematch(...)` per game: `ArcheryChallenge`, `DartsChallenge`, and basketball's rematch.
   - Share uses the existing share text and code logic in `match_setup_dialog.dart` (or `share_plus`, if it's already a dependency).
4. **Wire it in.** Everywhere a completed match currently routes to `/match/:id` for the podium, call `ResultsSheet.show` instead:
   - `MatchInboxSheet` (`onViewPodium`);
   - `ArcheryInbox.open` (`archery_match_bar.dart`);
   - `ProfileDrawer` `onOpenMatch` for completed matches;
   - the lobby's `account_chip.dart`.

   Keep `/match/:id` for **active** matches only. Rename every "VIEW PODIUM" to **"View results"**.
5. **Acceptance:**
   - Tapping a completed darts, hoops or archery match shows the sheet with no game screen behind it and no REMATCH / BACK TO SOLO from the in-game card.
   - The crown is on the right player.
   - Completed matches are still never deleted, except by the trash icon.

---

## Section 3. Completed match tiles (artboard 5)

1. **`CompletedMatchTile(CloudMatch m)`.** A card (`#111827`, radius 20, 14 px padding) containing:
   - Row 1: `GameChip`, date, trash icon button (the existing delete flow with its existing confirmation).
   - Row 2: tile-style `VerdictBanner` with VICTORY/DEFEAT and `MatchSummary.verdictLine`.
   - Row 3: `CrownAvatar` 40 (you) | YOU + headline + unit | VS | opponent name + headline + unit | `CrownAvatar` 40. The crown goes on the winner.
   - Row 4: a full-width secondary button, "View results ›", which opens `ResultsSheet`.
2. Replace the completed-state rendering in `match_inbox_card.dart` with this tile. You can delete the darts special case (remaining shown as a raw number) there, since `MatchSummary` now covers it.

---

## Section 4. Active match tiles + Matches page (artboard 10)

1. **`ActiveMatchTile`.** Three states, worked out from `CloudMatch` + `myUid`:
   - **Your turn:**
     - Card tinted `#0F1A1F` with a 1.5 px mint border and a soft mint glow.
     - "YOUR TURN" pill in mint, filled.
     - Scores labelled ("301 left", "12 pts", "2 sets").
     - Primary CTA, verb per game: darts "THROW YOUR TURN", hoops "SHOOT YOUR TURN", archery "SHOOT YOUR SET". It opens `/match/:id`.
   - **Their turn:**
     - Amber "THEIR TURN" pill.
     - Sentence, for example "Boogyman is shooting round 2 now. You lead by 4."
     - Buttons: "Watch live" (primary; only if live spectating exists for that game, otherwise "Open match") and "Nudge" (only if a nudge exists; otherwise omit it, never fake it).
   - **Invite not joined:**
     - Slate "NOT JOINED" pill.
     - "Waiting for Kay to join · code 4F7K2Q".
     - "Copy code" shows the existing ✓ CODE COPIED badge; "Cancel" uses the existing cancel flow.
2. **`MatchesPage`.** Pushed inside the profile sheet (Section 5) with a back arrow:
   - A segmented control: "Active · n" / "Completed · n", with the counts from `userMatchesProvider`.
   - Active is grouped under the labels **YOUR TURN**, **WAITING ON THEM** and **INVITES**, in that order. Completed is the list of Section 3 tiles, newest first.
   - Empty states: a short sentence plus a "Play a friend" button. No illustrations needed.

---

## Section 5. Profile sheet (artboard 9): replaces the side drawer

1. **`ProfileSheet.show(context, …)`.** Same callbacks as `ProfileDrawer.show`, so call sites don't change shape. It's a full-screen sheet that rises from the bottom, with a grabber and close button. Inner navigation (Matches, Friends) uses a nested `Navigator` inside the sheet: push from the right, back arrow, swipe-back on iOS.
2. **Content, top to bottom:**
   - Avatar 64 + name + "Edit name and avatar" (the existing `edit_profile_dialog.dart`).
   - Three stat tiles: Wins, Win rate, Best streak. Compute them from completed matches in `userMatchesProvider`. If the history is paginated or capped, label it "Last N matches" rather than all-time.
   - **WAITING ON YOU · n**: the `ActiveMatchTile`s in the your-turn state, plus an "All matches" link to `MatchesPage`. Hide the section when n = 0.
   - Three shortcut tiles: **Play a friend** (`DartsChallenge.start` or the game-agnostic `ArcheryChallenge.start(showGamePicker: true)`), **Join with code** (`join_match_dialog.dart`), **Add friend** (`add_friend_dialog.dart`).
   - **FRIENDS · n**: a horizontal row of `CrownAvatar` 52 with an online dot and a name, and a "See all" link to `FriendsPage`. Use the presence data if `friends_service.dart` exposes it; otherwise no dots.
   - Grouped list rows: **Matches** ("2 active · 14 completed"), **How to play**, **Sound** (the existing pause-menu audio rows, or the existing audio settings sheet).
3. **Replace every `ProfileDrawer.show(...)` call with `ProfileSheet.show(...)`:** the archery, darts and basketball HUD buttons and the lobby `account_chip.dart`. Keep `profile_drawer.dart` until all call sites are moved, then delete it.
4. **Badge** on the profile button: keep the existing count (your-turn matches + notices).

---

## Section 6. Head-to-head data + view (used by artboards 3, 4, 11 and the results footer)

1. **`HeadToHead` model:** `myWins`, `theirWins`, `draws`, `byGame` (map of game → wins/losses), `lastFive` (newest first, W/L), `currentStreak` (+n you, −n them), `matches` (a list of `MatchSummary`).
2. **`headToHeadProvider.family(String opponentUid)`.** Computed client-side from `userMatchesProvider` (completed only, where the opponent uid matches). **Before writing it, check** whether `userMatchesProvider` loads the full history or only recent matches.
   - If it's capped, add a Firestore query in `FirestoreMatchService`: `status == completed` AND `playerUids array-contains myUid`, filtered client-side by the opponent.
   - If a `playerUids` array field doesn't exist, add it on match create/join, and backfill lazily: read old matches from both `player1.uid` / `player2.uid` queries.
   - Rules: reads only by participants, as for existing matches.
3. **`H2HCard`.** A reusable widget with two sizes:
   - **peek:** record (big sky and amber numbers with a split bar), last-5 W/L dots, "See all our matches".
   - **full:**
     - header: stacked avatars, "You vs Name", "Head to head · n matches", collapse button;
     - game filter pills: All n / Darts n / Hoops n / Archery n, with the active one filled white;
     - record panel with a "You lead · won last 2" mint pill;
     - a scrolling list of rows: game icon, sentence (`MatchSummary.verdictLine`), date, WON/LOST pill. Tapping a row opens `ResultsSheet`.

---

## Section 7. Friends page (artboard 11)

1. Pushed inside the profile sheet. Header: back, "Friends", **+ Add** (opens `add_friend_dialog.dart`).
2. A search field that filters loaded friends by name or gamer tag. If the existing service supports searching by tag, show "Add" results too.
3. **REQUESTS · n:** from `incomingInvitesProvider`. Each row has a context line if one is known, for example "Played you at Hoops yesterday", taken from h2h data. Buttons: decline (×) and **Accept** (mint).
4. **ONLINE · n** and **ALL FRIENDS · n** grouped lists. Each row has:
   - `CrownAvatar` 44 with an online dot;
   - name and status ("Online · in a Darts match", "Last played 2 days ago", "Never played");
   - the record line "You lead 7–4" / "Level 2–2" / "They lead 1–3", from `headToHeadProvider`;
   - a **Challenge** pill that starts a match against that friend using the existing challenge flow.

   Tapping the row opens `H2HCard(full)` for that friend.

---

## Section 8. In-game: add friend + / chip / sent (artboards 1, 2)

Applies to the darts `_ScoreBadge` (opponent side), the archery HUD opponent badge, and the basketball `scoreboard_opponent_avatar.dart`. These are Flutter overlay widgets, **not Flame components**.

1. **`isFriendProvider(uid)`.** True if the uid is in the friend list; "pending" if a request is already sent; hidden when the opponent is the bot or offline.
2. **The + button:**
   - 22 px mint circle with a 2 px border in the badge colour and a faint mint halo.
   - Sits on the avatar's top-outer corner: the top-left corner when the badge is on the right, mirrored on the left.
   - 44 px invisible hit area.
   - Shown only when not friends and not pending.
3. **The chip:**
   - Placement: when the + first appears in a match, a small pill floats **above** the avatar when the badge is in the bottom half of the screen, and **below** it when it's in the top half. Decide by comparing the badge's global y with half the screen height.
   - Content: "+ Add to friends" (11.5 px w700) and a 2 px mint bar along the bottom that empties over **2 seconds**.
   - Behaviour: it fades out after the 2 seconds, or on tap (tap = add). It never blocks input to the game; wrap it in `IgnorePointer` except the pill itself.
   - Show it **once per opponent per match**.
4. **Tap +:**
   - Call the existing send-friend-request in `friends_service.dart`, with a light haptic.
   - The + morphs into a check (dark fill, mint ring), and the chip re-appears as "✓ Request sent to Name" for 2 seconds.
   - Error: the chip turns red, "Couldn't send · Tap to retry" (no SnackBar).
5. **Performance:**
   - All of this lives in a `ValueListenableBuilder` / Riverpod `select` scoped to the badge, so the HUD doesn't rebuild every frame.
   - Animations use `AnimationController` + `AnimatedBuilder` on the chip only.

---

## Section 9. In-game: avatar peek + H2H panel (artboards 3, 4)

**No dialogs or sheets.** The opponent badge itself grows.

1. **Tap the opponent's avatar** (not the +). The badge animates into the **peek card**:
   - Anchored to the badge's corner: bottom-right for a bottom-right badge.
   - Width about 272.
   - Grows with a critically damped spring (`AnimatedContainer` / `TweenAnimationBuilder` on size + opacity, scale origin at the anchor).
2. **Peek card content:**
   - avatar 46, name, "Not in your friends yet", and a mint **Add** pill if not friends;
   - `H2HCard(peek)` content;
   - "See all our matches ⌃";
   - the original badge row kept as the card's footer ("Boogyman · 205 left ⌄"), so it visibly *is* the badge, expanded.
3. **"See all our matches":** the same card grows upward into the **H2H panel**:
   - full width minus 12 px margins;
   - top edge never above the board centre (darts) or the hoop/target (other games);
   - contains `H2HCard(full)`, defaulting to the **current game's** filter.
4. **Dismiss:**
   - tap outside;
   - tap the badge footer or the collapse button;
   - drag down (spring back on release, with velocity handoff);
   - automatically when it becomes your throw in solo play.

   It shrinks back along the same path into the badge.
5. **Game input while open:**
   - Touches on the card are consumed.
   - Touches elsewhere first close the card and are **not** passed as a throw: one tap = close, no accidental flick.
6. **Live 1v1:**
   - The shot clock keeps running.
   - Show a small "YOUR THROW · 14s" pill above the panel when it's your turn.
   - **Don't pause the opponent's game.** In solo play, pause the engine while the panel is open (`g.pauseEngine()` / resume on close), the same as the pause menu.
7. **Performance:** the card is a Flutter overlay above the `GameWidget`, with no blur and a solid `0xF70F172A` fill. Its data comes from `headToHeadProvider` (cached), and it doesn't rebuild the HUD.

---

## Suggested order and rough size

| # | Section | Depends on | Size |
|---|---|---|---|
| 1 | Shared building blocks + `MatchSummary` + tests | none | S |
| 2 | Results sheet | 1 | L |
| 3 | Completed tiles | 1, 2 | S |
| 6 | H2H data + `H2HCard` | 1 | M |
| 4 | Active tiles + Matches page | 1 | M |
| 5 | Profile sheet (replaces drawer) | 3, 4 | M |
| 7 | Friends page | 5, 6 | M |
| 8 | In-game + / chip / sent | none (uses friends_service) | S |
| 9 | In-game peek + H2H panel | 6, 8 | L |

After each section, check:
- `flutter analyze` is clean;
- `flutter test` passes;
- `flutter build web --release` succeeds;
- the result is tested on a phone (iOS Safari and Android Chrome) at 360 px wide.

Commit per section, for example `feat(social): results sheet replaces podium navigation`.

## Out of scope / don't do
- Don't change match rules, scoring or Firestore match lifecycle (completed matches stay forever).
- Don't add blur over the live game.
- Don't invent data: if a stat isn't stored, show "—" or hide the row.
- Don't run `firebase deploy`. If Firestore rules or indexes change (`playerUids` query), write them and list the deploy command for the developer.
