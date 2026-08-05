# game/ — Phase 2/3/4 prototype

Godot 4.7 project. One Payline machine, spin → ease-to-stop → payout, three
pools shown live, placeholder art with real juice (Phase 2) — plus the
Phase 3 play-phase decisions: bet sizing, bank-vs-gamble-up, and the D23
post-quota cash-out choice — and the Phase 4 loop: a build phase (wallet →
reel editor + Wild shelf + load bankroll, D28-D30) into a stage path
(minor/elite/treasure nodes over one continuous economy, D31) into a
result screen that cycles winnings into the next build phase (D21). See
`docs/05_ROADMAP.md`.

## Design intent — read this before touching `reel_view.gd`

**The reel settling into its final position is the single most important
piece of feel in this game.** That moment — the reel decelerating, the beat
of not-yet-knowing before a symbol locks in, then either the payoff or the
near-miss — is a moment-to-moment experience of its own, independent of the
economy math running underneath it. `sim/` already proved the numbers are
tense on paper (55.1% win rate at 20k runs, `06_OPEN_QUESTIONS.md` D12/D18).
Phase 2's entire job is to prove that same tension actually *lands* in the
body, spin to spin — that's the roadmap's Phase 2 exit criterion, and it is
not a checkbox to wave through. If the settle feels flat or mechanical,
that's a problem worth fixing before anything else in this phase, on the
same footing as an economy bug. See `docs/04_ART_DIRECTION.md` pillar 1 and
the comment header on `scripts/ui/reel_view.gd`.

## Run it

```
tools/godot/Godot_v4.7.1-stable_win64.exe --path game
```

(No editor install needed elsewhere — the binary is vendored locally, see
repo root for how it's excluded from git.)

## Run the tests

```
tools/godot/Godot_v4.7.1-stable_win64_console.exe --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

105 GUT tests, ported from `sim/tests/` for economy parity: pools,
paytable, dual-limiter, near-miss/big-win pure logic, `Odds`, gamble-up,
D23 cash-out, Wild substitution, the reel editor, `BuildPhase`, and
`Stage` (including a tension-band regression check).

New `class_name` scripts need one editor pass before a headless run can
see them (Godot's global class cache doesn't update from a plain
`--headless` load):
```
tools/godot/Godot_v4.7.1-stable_win64_console.exe --headless --editor --path game --quit-after 20
```

## Layout

- `project.godot` — Forward+, 1280x720, GUT plugin enabled.
- `scenes/Main.tscn` — thin scene wrapper; `scripts/main.gd` builds the
  entire UI in code (pool labels, reel row, bet control, spin button) so
  the whole layout is one readable, greppable file.
- `scripts/economy/` — **GDScript port of `sim/`**, kept numerically
  identical (same default weights, paytable, paylines, quota, spin cap) so
  what you feel here matches what Phase 1 validated, not a second,
  unvalidated economy:
  - `pools.gd` — bankroll drains only, winnings accumulates only (D3).
  - `reel_machine.gd` — reel strips + the spin draw.
  - `paytable.gd` — the payout resolver.
  - `economy_config.gd` — every parameter, mirroring `sim/config.py`.
  - `play_phase.gd` — the dual-limiter (D6) as a UI-driven state machine
    (not `sim/play_phase.py`'s batch loop + pluggable strategies): a
    winning spin only *may* set `awaiting_gamble_decision` (D24,
    `GAMBLE_OFFER_PROBABILITY = 0.25` — not every win) and pause until the
    caller calls `bank_pending()`/`gamble_pending()` — a single flip, not
    a ladder (D25): a win auto-banks the double rather than offering to
    press again. Once quota clears, `awaiting_continuation_decision` (D23)
    pauses every subsequent spin until `keep_playing()`/`cash_out()`.
    Check `has_pending_decision()` before calling `spin()` again.
  - `odds.gd` — hit probabilities and theoretical RTP, computed live from
    whatever reel strips/paytable are actually loaded (per-reel, not a
    uniform-reel assumption) so it stays correct once symbols can be
    purchased onto specific reels (build phase, Phase 4). Also what the
    D23 cash-out offer is projected from — deliberately the paytable's
    *theoretical* rate, not the realized average, which turned out to be
    exploitable (see `sim/README.md`).
  - `near_miss.gd` — finds the richest developing line in an already-
    resolved grid; `main.gd` uses it to hold/pulse the deciding reel.
  - `reel_editor.gd` — D29's fixed-slot density-tuning swap (cheapest-tier
    symbol present → a symbol you own, strip length conserved).
  - `build_phase.gd` — the build phase: wallet, the Wild-only Relic shelf
    (D28/D30), the reel editor exposed as 3 pre-rolled offers per build
    phase rather than a free picker (D32) with a climbing-price reroll
    for unbought offers and a per-reel purchase ledger (D33),
    load-bankroll/finalize (D5's no-waste failsafe).
  - `stage.gd` — the D31 node path (minor/elite/event/rest/treasure) over
    one continuous economy. Unlike `sim/stage.py`'s batch loop, this
    composes a `PlayPhase` and drives it one node at a time — the same
    UI-driven adaptation `play_phase.gd` already made from its own sim
    counterpart — reusing `PlayPhase`'s internal dual-limiter/gamble/
    cash-out logic instead of duplicating it.
  - `main.gd` — a `GameState` (BUILD/PLAY/RESULT) flow: the build screen
    (wallet, reel editor, shelf, load-bankroll), the play screen (pool
    labels, reel row, bet control, spin button, bank/gamble row,
    keep-playing/cash-out row, node badge, the "i" button), and the
    result screen (outcome, "Continue" cycles winnings into the next
    build phase per D21).
- `scripts/ui/reel_view.gd` — one reel column: flicker → staggered stop →
  elastic settle bounce. **The feel-critical file** — see Design intent
  above.
- `scripts/ui/paytable_panel.gd` — the "i" button overlay: a per-reel
  purchase ledger (D33, only shown once something's been bought) + match
  rule (`_build_rules_section`, Payline-only today — see
  `docs/07_SLOT_TYPES.md` for where the other four types plug in later) +
  per-symbol payouts/odds + overall RTP, rebuilt live on every open. Meant
  to be added to every
  future slot-gameplay screen, not just this one.
- `scripts/ui/big_win_banner.gd` — tiered bounce-in banner for payouts
  ≥10x/30x/100x bet.
- `assets/symbols/` — generic flat-white silhouette icons per symbol
  (placeholder art, not a locked style — `docs/04_ART_DIRECTION.md`).
- `tests/` — GUT ports of `sim/tests/`.
- `addons/gut/` — vendored [GUT](https://github.com/bitwes/Gut) v9.7.1
  (Godot Unit Testing), committed since it's project-required GDScript
  source, not a downloaded tool binary.

## What's out of scope here

No bonuses (K1), no boons/curses, no real art, no other slot types
(Payline only). A run is exactly one stage — reel edits/purchases don't
carry forward across stages, and there's no run-level meta-progression
(that's Phase 6). Stored-bonus timing (part of the original Phase 3
checklist) doesn't apply yet either — bonuses don't exist until Phase 5.7.
Event/Rest nodes exist in `stage.gd` but aren't populated by
`default_node_sequence()` — they need Phase 5 boon/curse content to mean
anything.
