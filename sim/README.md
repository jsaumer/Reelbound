# sim/ — Phase-1 headless economy model

Pure, seedable, engine-independent model of one Payline machine and the
three-pool play phase (see `docs/05_ROADMAP.md` Phase 1). No engine, no
graphics, no bonuses (K1) — this only exists to answer one question:
**with naive play, is a run winnable ~40–60% of the time?**

## Run it

```
python -m sim.main run                              # default config, flat_mid strategy, 10k runs
python -m sim.main run --strategy flat_min --runs 20000
python -m sim.main run --strategy adaptive_throttle --gamble-strategy gamble_while_behind
python -m sim.main sweep                             # quota x spin_cap grid (D12 / D18 exploration)
python -m sim.main sweep --quotas 50,60,70 --spin-caps 40,45,50
python -m sim.main compare                            # Phase 3: do decisions demonstrably matter?
```

## Tests

```
python -m unittest discover -s sim/tests -v
```

## Layout

- `pools.py` — the three pools (bankroll/winnings/pending). Bankroll only
  drains, winnings only accumulates (D3) — enforced by the API shape, not
  just convention.
- `reel.py` — reel strips and the spin draw.
- `paytable.py` — the payout resolver. Kept standalone and swappable so the
  payout math can be tuned without touching anything else.
- `strategy.py` — pluggable bet-size strategies (`flat_min`/`flat_mid`/
  `flat_max`/`adaptive_throttle`) and bank-vs-gamble strategies
  (`never_gamble`/`always_gamble`/`gamble_while_behind`), Phase 3
  (docs/05_ROADMAP.md).
- `play_phase.py` — the dual-limiter play-phase loop (D6). A win *may*
  offer a repeatable bank-vs-gamble-up decision (docs/02_GAME_DESIGN.md
  §4) — a fair coin flip that only ever doubles or zeroes *pending*;
  bankroll is untouched either way (D3). Only some of the time, though
  (`D24`, `gamble_offer_probability = 0.25`) — offering it on every win
  tested as fatiguing, not tense; meant to eventually be gated behind an
  obtainable item/boon (Phase 4/5) instead of a flat probability. When
  the offer doesn't appear, the win auto-banks. Default
  `gamble_strategy=never_gamble` keeps Phase 1/2 behavior unchanged if
  you don't pass one.

  **D23:** clearing the quota no longer stops play (D6 only ever named
  bankroll=0 / spin cap as the end triggers) — it locks in a win and, every
  spin after, offers a `continuation_strategy` a choice: keep playing to
  the natural end, or cash out now for a guaranteed bonus =
  `spins_remaining x theoretical_rate_per_spin x cash_out_discount`
  (default 0.4 — deliberately unfavorable, a mild downside not a free
  upgrade). The projection uses the paytable's *theoretical* rate
  (`odds.py`), not the realized average so far — the realized average is
  biased by whatever win just cleared quota, which made an immediate
  cash-out exploitably profitable before this fix.
- `odds.py` — theoretical hit probabilities and RTP from the paytable/reel
  strips themselves (not any run's results). Mirrors
  `game/scripts/economy/odds.gd`. What `play_phase.py` uses for the D23
  cash-out projection.
- `config.py` — every economy/machine parameter in one place, including the
  tuned defaults, the default Payline machine, `gamble_win_probability`,
  and `cash_out_discount`.
- `harness.py` — runs N play-phases, reports win/bust/out-of-spins rate,
  avg spins-to-quota, and payout volatility; checks the result against the
  40–60% tension band; supports a quota x spin_cap sweep and a
  `compare_strategies` tool for the Phase 3 exit criterion (does a decision
  demonstrably move the numbers?).

## A property worth knowing

Because bankroll only ever drains (D3) and a *flat*-bet strategy never
changes its bet with the score, the number of spins until bankroll bust is
completely deterministic: `floor(starting_bankroll / bet)`. Wins never
extend the bankroll clock. So for a flat-bet strategy, whichever of
`spin_cap` and that natural ceiling is smaller decides the failure mode
entirely (bust-only vs. out-of-spins-only) — this is exactly the D18
question the sweep is for, and it's a direct, testable consequence of the
brutal-drain design (D3), not a simulation quirk.
