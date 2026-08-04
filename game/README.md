# game/ — Phase 2 spin-feel prototype

Godot 4.7 project. One Payline machine, spin → ease-to-stop → payout, three
pools shown live, placeholder art with real juice. See
`docs/05_ROADMAP.md` Phase 2.

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

17 GUT tests, ported from `sim/tests/` so the two economy implementations
stay verified in parallel.

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
  - `play_phase.gd` — the dual-limiter (D6), driven one spin at a time by
    the UI instead of `sim/play_phase.py`'s batch loop.
- `scripts/ui/reel_view.gd` — one reel column: flicker → staggered stop →
  elastic settle bounce. **The feel-critical file** — see Design intent
  above.
- `tests/` — GUT ports of `sim/tests/`.
- `addons/gut/` — vendored [GUT](https://github.com/bitwes/Gut) v9.7.1
  (Godot Unit Testing), committed since it's project-required GDScript
  source, not a downloaded tool binary.

## What's out of scope for Phase 2

No bonuses (K1), no build phase, no real art, no bank-vs-press (that's
Phase 3). This is strictly: does the core spin loop feel good on grey
boxes.
