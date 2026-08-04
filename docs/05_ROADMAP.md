# 05 — Roadmap

Engine-agnostic. Ordered so that the **make-or-break questions are answered cheapest and first**: decide the engine, prove the economy is fun, then build the visual game on proven foundations.

## Phase 0 — Planning & Decisions *(complete)*
Reach the decisions that gate everything else.
- [x] Design set drafted (this document set).
- [x] **Engine decision → Godot 4.7** (E1 locked 2026-08-03). Optional non-blocking "spin feel" spike remains as a workflow confidence check.
- [x] Lock provisional design decisions enough to prototype: win condition (D6), build budget shape (D5), stake-return model (D3). *(All three locked 2026-08-03, see `06`.)*
- **Exit:** an engine is chosen and the core economy is specified precisely enough to prototype. ✅

## Phase 1 — Prove the Economy (no visuals needed) *(complete)*
The single most important validation. Can be a spreadsheet or a tiny headless script — **independent of the engine choice.** Model the **pure economy with no bonuses** — bonuses are a later unlock (`08`), and the core must be tense without them.
- [x] Model the three-pool loop: bankroll → bet → spin → winnings. *(`sim/pools.py`, `sim/play_phase.py`.)*
- [x] Approximate reel payout math (average return per spin, variance) — start with the **Payline** type (`07`); add other types once the baseline holds. *(`sim/reel.py`, `sim/paytable.py`.)*
- [x] Answer: is a run **tense** — winnable ~40–60% with naive play — rather than trivial or impossible? *(No-bonus core must clear this bar on its own.)* **Yes — 55.1% win rate at 20k runs.**
- [x] Simulate many auto-played runs; read win rate, bust rate, spins-to-quota, volatility. *(`sim/harness.py`.)*
- **Exit:** the numbers produce tension on paper, **without bonuses**. If they don't, fix the design *before* building anything. ✅ Met 2026-08-04 — see `sim/README.md` and the D12/D18 locks in `06_OPEN_QUESTIONS.md`.

## Phase 2 — Spin Feel Prototype (in Godot 4.7) *(current)*
Now prove the *feel*, with placeholder art. **This phase is not a formality.** The reel settling into its final position — the deceleration, the beat of not-yet-knowing before the symbol locks — is a moment-to-moment experience in its own right, as important to the game's success as the economy Phase 1 validated. See `04` pillar 1. If the settle doesn't land, fix *this* before adding anything else.
- [x] One machine that spins, eases to a stop, and resolves a payout. *(`game/scripts/ui/reel_view.gd`: flicker → left-to-right staggered stop → elastic settle bounce, driven by the same economy model as `sim/`.)*
- [x] Three pools shown and updating. *(`game/scripts/main.gd`: bankroll debits immediately on bet; pending ticks up and winnings tallies in after the reels settle.)*
- [x] Real juice on placeholder art: easing, win burst, number pop, near-miss anticipation. *(Easing/settle bounce, win flash, and number tween confirmed working. Near-miss anticipation (`game/scripts/economy/near_miss.gd` + `reel_view.gd:pulse_cell`) holds the deciding reel and pulses the cells feeding into it when a line is developing. Tiered big-win banner (`game/scripts/ui/big_win_banner.gd`) added alongside it for large payouts. Built and unit-tested 2026-08-04 — not yet hand-confirmed for feel, see Exit below.)*
- **Exit:** pulling the lever feels good even with grey boxes. **Partially verified 2026-08-04** — the reel settle-bounce itself was hand-tested and confirmed to feel good. Still open: near-miss anticipation and the big-win banner just landed and haven't been hand-tested yet; the overall "pulling the lever" experience end-to-end hasn't been separately confirmed either.

## Phase 3 — Play-Phase Decisions
Layer the live decisions onto the proven loop.
- [ ] Bet sizing; bank vs. gamble-up (pending pool); stored-bonus timing.
- [ ] Confirm (via the Phase-1 model or playtests) that skilled play beats button-mashing.
- **Exit:** decisions demonstrably matter.

## Phase 4 — Build Phase + End-to-End Stage
Make the player an author.
- [ ] Splittable build budget (machine vs. bankroll).
- [ ] Symbol/reel editing UI (the "mix of code + visual authoring" in action).
- [ ] A full single stage playable start-to-finish by a human.
- **Exit:** one complete stage loop is playable in the engine.

## Phase 5 — Boons, Curses, Bet Types
The spice, as small modifiers on defined hooks (`onBet/onSpin/onWin/onStageEnd`).
- [ ] Modifier system + first 8–10 boons/curses from the backlog.
- [ ] Alternate bet types.
- **Exit:** modifiers change how a stage plays without breaking the core.

## Phase 5.5 — Slot Types
Prove the second gameplay axis: the payout rulesets (`07`).
- [ ] Implement the five types (Payline first, then ways-to-win, cluster+cascade, hold-and-spin, Megaways-style).
- [ ] Validate each type's volatility via the Phase-1 sim harness.
- [ ] Confirm symbol density interacts distinctly per type (a build strong in one is weak in another).
- **Exit:** all five types play distinctly and are individually balanced by simulation.

## Phase 5.7 — Bonus System (unlockable capability)
Layer bonuses on *after* the pure-economy game stands (`08`).
- [ ] Tier structure: meta capability unlock → in-run build cost → in-stage charge & fire.
- [ ] Per-slot-type native bonus (each type's intrinsic bonus).
- [ ] Passive charge meter (charges from symbols/decisions, never pure spin count).
- [ ] The unlock ladder: bonuses-exist → charge meter → multipliers/stacking as separate beats.
- **Exit:** bonuses deepen the game without becoming mandatory; the no-bonus core still holds.

## Phase 6 — Meta-Progression & Content
Make it a *run*.
- [ ] Multi-stage runs, escalating quotas.
- [ ] Shop (in-run and/or cross-run).
- [ ] Unlock trees: symbol density, slot types, the bonus ladder.
- [ ] Content pass across symbols/features/boons/curses/types.
- **Exit:** a full ~8-stage run is playable and replayable.

## Phase 7 — Art Direction & Feel Pass
Now invest in the final look (see `04`).
- [ ] Lock theme + art style.
- [ ] Replace placeholders; full VFX/audio juice pass.
- [ ] Balance pass using the Phase-1 simulation against real unlock trees.
- **Exit:** it *looks* and *feels* like a polished slot roguelike.

## Phase 8 — Steam Readiness
- [ ] Steam integration (achievements, cloud saves), store assets, build pipeline.
- [ ] Onboarding / first-run experience.
- [ ] Playtesting + balance.
- **Exit:** shippable.

## Guiding principles
1. **Cheapest decisions first.** Engine and economy before pixels.
2. **Prove the economy headless.** No graphics needed to know if it's fun.
3. **Placeholder art + real juice.** Lock feel before final art.
4. **The simulation is a permanent tool.** Balance by simulating, not guessing.
5. **Art last, on purpose.** Rich visuals sit on top of proven foundations.
