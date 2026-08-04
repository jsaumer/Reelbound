# game/ — Phase 2/3 prototype

Godot 4.7 project. One Payline machine, spin → ease-to-stop → payout, three
pools shown live, placeholder art with real juice (Phase 2) — plus the
Phase 3 play-phase decisions: bet sizing, bank-vs-gamble-up, and the D23
post-quota cash-out choice. See `docs/05_ROADMAP.md`.

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

39 GUT tests, ported from `sim/tests/` for economy parity: pools,
paytable, dual-limiter, near-miss/big-win pure logic, `Odds`, gamble-up,
and D23 cash-out.

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
    `GAMBLE_OFFER_PROBABILITY = 0.25` — not every win, see below) and
    pause until the caller calls `bank_pending()`/`gamble_pending()`; once
    quota clears, `awaiting_continuation_decision` (D23) pauses every
    subsequent spin until `keep_playing()`/`cash_out()`. Check
    `has_pending_decision()` before calling `spin()` again.
  - `odds.gd` — hit probabilities and theoretical RTP, computed live from
    whatever reel strips/paytable are actually loaded (per-reel, not a
    uniform-reel assumption) so it stays correct once symbols can be
    purchased onto specific reels (build phase, Phase 4). Also what the
    D23 cash-out offer is projected from — deliberately the paytable's
    *theoretical* rate, not the realized average, which turned out to be
    exploitable (see `sim/README.md`).
  - `near_miss.gd` — finds the richest developing line in an already-
    resolved grid; `main.gd` uses it to hold/pulse the deciding reel.
  - `main.gd` — pool labels, reel row, bet control, spin button, the
    bank/gamble row, the keep-playing/cash-out row, the "i" button.
- `scripts/ui/reel_view.gd` — one reel column: flicker → staggered stop →
  elastic settle bounce. **The feel-critical file** — see Design intent
  above.
- `scripts/ui/paytable_panel.gd` — the "i" button overlay: match rule
  (`_build_rules_section`, Payline-only today — see `docs/07_SLOT_TYPES.md`
  for where the other four types plug in later) + per-symbol payouts/odds
  + overall RTP, rebuilt live on every open. Meant to be added to every
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

No bonuses (K1), no build phase, no real art, no multi-stage runs, no
other slot types (Payline only). Stored-bonus timing (part of the
original Phase 3 checklist) doesn't apply yet either — bonuses don't
exist until Phase 5.7.
