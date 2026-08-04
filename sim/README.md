# sim/ — Phase-1 headless economy model

Pure, seedable, engine-independent model of one Payline machine and the
three-pool play phase (see `docs/05_ROADMAP.md` Phase 1). No engine, no
graphics, no bonuses (K1) — this only exists to answer one question:
**with naive play, is a run winnable ~40–60% of the time?**

## Run it

```
python -m sim.main run                              # default config, flat_mid strategy, 10k runs
python -m sim.main run --strategy flat_min --runs 20000
python -m sim.main sweep                             # quota x spin_cap grid (D12 / D18 exploration)
python -m sim.main sweep --quotas 50,60,70 --spin-caps 40,45,50
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
- `strategy.py` — pluggable bet-size strategies (`flat_min`, `flat_mid`,
  `flat_max`) for the naive auto-player.
- `play_phase.py` — the dual-limiter play-phase loop (D6).
- `config.py` — every economy/machine parameter in one place, including the
  tuned defaults and the default Payline machine.
- `harness.py` — runs N play-phases, reports win/bust/out-of-spins rate,
  avg spins-to-quota, and payout volatility; checks the result against the
  40–60% tension band; supports a quota x spin_cap sweep.

## A property worth knowing

Because bankroll only ever drains (D3) and a *flat*-bet strategy never
changes its bet with the score, the number of spins until bankroll bust is
completely deterministic: `floor(starting_bankroll / bet)`. Wins never
extend the bankroll clock. So for a flat-bet strategy, whichever of
`spin_cap` and that natural ceiling is smaller decides the failure mode
entirely (bust-only vs. out-of-spins-only) — this is exactly the D18
question the sweep is for, and it's a direct, testable consequence of the
brutal-drain design (D3), not a simulation quirk.
