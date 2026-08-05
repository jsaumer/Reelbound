# 05 — Roadmap

Engine-agnostic. Ordered so that the **make-or-break questions are answered cheapest and first**: decide the engine, prove the economy is fun, then build the visual game on proven foundations.

## Current focus *(updated 2026-08-05, post project review)*

**Now (parallel tracks):**
1. **Phase 4 closing playtest checklist** (below) — hands-on feedback questions; human-gated, no code needed.
2. **Phase 4.5 — multi-stage economic skeleton, sim-only** (new phase, below) — pulled forward from Phase 6 because the purchase-EV finding showed the macro loop is the biggest unvalidated assumption left, and every Phase 5+ balance target depends on it. Pure `sim/` work; doesn't wait on the playtest checklist.

**Decisions to make soonest (both cheap, both load-bearing):**
- **`D36`** — do machines persist across stages, or get re-authored each stage? Gates all of Phase 4.5's modeling and every Phase 5 balance number. Currently implied per-stage, never decided.
- **`D7`** — theme. Recommended earlier than originally planned (~Phase 5, not 7): it has mechanical hooks (what a quota *is*, fiction-wise), not just art ones.

**Next:** Phase 5 (boons/curses/bet types), now carrying a skill-gap exit criterion (`K4`). **Then:** 5.5 as a two-type slice first (see the amended phase), 5.7, 6, 7, 8.

**Standing risk ledger (from the 2026-08-05 review):** the differentiator (active play phase) is currently the *thinnest measured* part of the game — one lever, ~5-point skill gap — while being the whole niche claim; `K4` exists to keep this honest. Phase 5.5 is the largest scope item in the plan (five payout resolvers); the two-type slice is the hedge. Expect gambling-imagery ratings scrutiny at Phase 8 (Balatro precedent) — plan the store/rating approach early, don't discover it at submission.

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

## Phase 2 — Spin Feel Prototype (in Godot 4.7) *(accepted, good enough to proceed)*
Now prove the *feel*, with placeholder art. **This phase is not a formality.** The reel settling into its final position — the deceleration, the beat of not-yet-knowing before the symbol locks — is a moment-to-moment experience in its own right, as important to the game's success as the economy Phase 1 validated. See `04` pillar 1. If the settle doesn't land, fix *this* before adding anything else.
- [x] One machine that spins, eases to a stop, and resolves a payout. *(`game/scripts/ui/reel_view.gd`: flicker → left-to-right staggered stop → elastic settle bounce, driven by the same economy model as `sim/`.)*
- [x] Three pools shown and updating. *(`game/scripts/main.gd`: bankroll debits immediately on bet; pending ticks up and winnings tallies in after the reels settle.)*
- [x] Real juice on placeholder art: easing, win burst, number pop, near-miss anticipation. *(Easing/settle bounce, win flash, and number tween confirmed working. Near-miss anticipation (`game/scripts/economy/near_miss.gd` + `reel_view.gd:pulse_cell`) holds the deciding reel and pulses the cells feeding into it when a line is developing. Tiered big-win banner (`game/scripts/ui/big_win_banner.gd`) added alongside it for large payouts. Built and unit-tested 2026-08-04 — not yet hand-confirmed for feel, see Exit below.)*
- **Exit:** pulling the lever feels good even with grey boxes. **Accepted 2026-08-04** — "good for right now," moving on to Phase 3. Not every juice beat (near-miss anticipation, big-win banner) got an explicit separate hand-confirmation; revisit specific pieces later if something about the feel bothers you in play, rather than treating this as a closed book.

## Phase 3 — Play-Phase Decisions *(accepted, good enough to proceed)*
Layer the live decisions onto the proven loop.
- [x] Bet sizing; bank vs. gamble-up (pending pool). *(`sim/strategy.py`, `sim/play_phase.py`: adaptive bet-sizing + a bank-vs-gamble-up decision, offered on ~25% of wins (`D24`) as a single flip, not a ladder (`D25`); D23's post-quota cash-out choice on top. Mirrored into `game/scripts/economy/play_phase.gd` as a UI-driven state machine, with a bank/gamble row and a keep-playing/cash-out row in `main.gd`, plus explicit won/lost feedback on the flip.)* Stored-bonus timing is **not applicable yet** — bonuses don't exist until Phase 5.7; not stubbed out.
- [x] Confirm (via the Phase-1 model or playtests) that skilled play beats button-mashing. *(`python -m sim.main compare`, 2026-08-04: `adaptive_throttle` bet-sizing alone lifts win rate 55.1% → 60.3%. `gamble_while_behind` alone is roughly a wash — an honest result, not tuned to look good; a fair-odds gamble is EV-neutral, so it shouldn't move win rate much by itself.)*
- **Exit:** decisions demonstrably matter. **Met for bet-sizing** (sim-confirmed) and **hand-confirmed for feel 2026-08-04**, including after the `D24`/`D25` gamble-up refinements — "feels good for the absolute base gameplay." Playtesting also produced a **structural upgrades** progression idea (more paylines/reels as a distinct unlock axis from symbol density) logged in `02_GAME_DESIGN.md` §7 / `03_IDEA_BACKLOG.md` for when meta-progression (Phase 6) is designed.

## Phase 4 — Build Phase + End-to-End Stage
Make the player an author. Pre-implementation planning (2026-08-04) landed several decisions before any code: `D28`-`D30` (the shelf/Relic system, reel editor split, shelf content tiers) and `D31` (the play phase is a linear path of nodes over one continuous economy, not a `D20` reversal — see `02_GAME_DESIGN.md` §4).
- [x] Splittable build budget (machine vs. bankroll). *(`sim/build_phase.py` / `game/scripts/economy/build_phase.gd`: `BuildPhase` — wallet, `load_bankroll`/`spins_from_load`, `finalize()` auto-converts leftover per `D5`.)*
- [x] Reel editor (mechanical density tuning, `D29`) + shelf (Relics, `D28`/`D30` — Wild is Phase 4's only shelf content). *(`sim/reel_editor.py` / `game/scripts/economy/reel_editor.gd` (fixed-slot cheapest-tier swap), `build_phase.gd`'s `default_shelf`/`buy_relic`, Wild substitution mirrored into `paytable.gd`. UI: a reel-index/symbol/quantity row + live cost preview in `main.gd`'s build screen, shelf rendered as buy buttons.)*
- [x] Stage path: minor/elite/event/rest/treasure nodes (`D31`), linear sequence, one shared economy, no branching yet. *(`sim/stage.py` / `game/scripts/economy/stage.gd`: sim batch-loops via `itertools.cycle()`; the GDScript port instead composes a `PlayPhase` and drives it one node at a time — same UI-driven adaptation `play_phase.gd` already made from its own sim counterpart — reusing `PlayPhase`'s internal dual-limiter/gamble/cash-out logic rather than duplicating it. EVENT/REST nodes exist as no-ops; they need Phase 5 boon/curse content to mean anything.)*
- [x] A full single stage playable start-to-finish by a human: build → walk the path → result. *(`main.gd`: a `GameState` (BUILD/PLAY/RESULT) flow — build screen (wallet, reel editor, shelf, load-bankroll) → play screen (existing Phase 2/3 spin/juice/gamble/cash-out UI, extended with a node badge and an auto-resolving Treasure beat) → result screen (outcome + winnings, "Continue" cycles winnings into the next wallet per `D21`). Verified headless, then **hand-playtested 2026-08-05**, which drove a same-day iteration loop: `D32` (freeform reel picker → 3 pre-rolled offers), `D33` (climbing-price reroll + purchase ledger), `D34` (pricing rebalance — the original factor made top-tier symbols literally unaffordable), `D35` (reroll resets bought slots; ledger surfaced on the play screen itself).)*
- [ ] **Ample purchase opportunity.** Looking at the genre's best (Balatro-likes, `Luck be a Landlord`, etc.), the shelf/shop needs to give the player generous, frequent chances to buy Relics during the build phase — not a thin trickle. This sharpens `D5`'s "small, curated, rotating shelf" without contradicting it: curated ≠ scarce. **Still thin as shipped** — Phase 4's shelf is Wild-only (`D30` tier 1), so this is inherently a one-item shelf until `D30`'s tiers 2/3 or Phase 5 boons land; revisit once there's more than one thing to offer. The reel-editor side is in better shape post-`D33`/`D35`: 3 offers + unlimited (wallet-permitting) rerolls is a real stream of purchase chances.
- **Exit:** one complete stage loop is playable in the engine. ✅ Met 2026-08-04; hand-playtested 2026-08-05 through several feedback rounds (`D32`-`D35`). Remaining before fully closing the book: the structured playtest checklist below.

**Sim-side balance note (2026-08-04):** the first `default_node_sequence()` (2-in-6 ELITE, 1-in-6 TREASURE, at a 2x bet multiplier / 1.5x payout multiplier / +10 flat winnings) produced a **100% win rate** in the 20k-run tension-band check — a severe regression from the validated 40-60% band. Root cause: the Phase-1/2/3 economy is **spin-cap-bound**, not bankroll-bound (most losses are "ran out of spins near quota," not bankrupt — see the `D18` numbers). Any node that hands out winnings for free, or that increases bet-size variance, converts a disproportionate share of those near-miss runs into wins even at small magnitudes, because so much of the loss distribution sits just short of quota. Fixed by removing ELITE's payout multiplier entirely (now just a forced bigger bet — EV-neutral versus betting bigger manually) and cutting TREASURE's bonus to +0.5, with both nodes dropped to 1-in-15 frequency instead of 1-in-3/1-in-6. Re-verified at 58.0% (`never_gamble`) / 55.4% (`always_gamble`), both inside the band; a regression test (`sim/tests/test_stage.py::TestTensionBandHolds`) now guards this. **Relevant to `D22`** (the not-yet-answered quota escalation curve): any future stage-path content that grants free winnings or bet-variance will need the same small-and-rare treatment, tuned per stage via the sim, not guessed.

**Purchase-cost balance note (2026-08-05):** a 5,000-run sim comparison (post-`D34` pricing, `flat_mid` betting) of buying reel-editor offers vs. hoarding the wallet: **0 purchases (all wallet → bankroll) wins 57.6%** (0% bust / 42.4% out-of-spins); **forcing 2+ purchases wins 45.7%** (40.3% bust / 14.0% out-of-spins). Two readings, both true: (a) still inside the 40-60% band, and buying changes the *failure mode* from "ran out of spins" to "went bankrupt" — the `D5` machine-vs-fuel tension working exactly as designed; (b) at the single-stage scope, purchases are **net negative in win-rate terms** — the payout upside of added symbols doesn't yet repay the bankroll they cost. This is *expected* at current scope: a purchase's value is supposed to compound across a multi-stage run (`D30`'s "later stages demand more and supply more"), which doesn't exist yet. **This is the concrete, sim-measured entry point for `D22`/Phase 6:** whatever the escalation curve becomes, it must make purchases EV-positive across a run, or the build phase is a trap. Until then, treat single-stage purchase win-rate drag as a known, accepted artifact of scope — not a bug to tune away now (over-buffing purchases at single-stage scope would overshoot once compounding exists).

### Phase 4 closing playtest checklist *(the asks before moving on)*

Structured feedback wanted from hands-on play, 2026-08-05. Each is a specific question, not "play and see":

- [ ] **Build-phase decision quality.** Across ~5 runs: do the 3 offers + reroll produce at least one *interesting* decision per build phase (a real "do I chase this or bank the wallet?"), or do they mostly read as noise to skip past? If skipping is common, note whether it's the symbols offered, the prices, or the reel targeting that makes them skippable.
- [ ] **Wallet split instincts.** After a few runs, does the machine-vs-bankroll split feel like the central decision (`D5`'s intent), or does one option dominate? The sim says hoarding wallet wins more *at this scope* (see the 2026-08-05 balance note) — does that show through in play, and does buying still feel *worth doing* for fun reasons even when it costs win rate?
- [ ] **Reroll pull.** Does the climbing reroll price create a real "one more roll" tension, or is 5/10/15... either too cheap to feel (spam) or too steep to ever use twice? Note the reroll count you naturally settle at.
- [ ] **Stage-path legibility.** Is the node badge (Minor/Elite) + auto-resolving Treasure readable in the moment, or does Elite's forced bet bump ever land as a surprise? (First-time surprise was reported once already — the ×1.25 badge is the fix under test.)
- [ ] **Ledger usefulness.** Does the play-screen ledger line actually get glanced at mid-stage, or is it dead weight? (If dead weight: candidate for showing only post-purchase runs.)
- [ ] **Loss reading.** When a run ends BUST after heavy buying, does it feel like *your* call gone wrong (good — legible failure, `02` §4) or like the shop robbed you (bad — pricing/feedback problem)?

**Gate to Phase 5:** the checklist above answered (even roughly), plus no new D-level design reversals pending. Balance findings that depend on multi-stage play (purchase EV, `D22`) explicitly do **not** gate Phase 5 — they gate Phase 6.

## Phase 4.5 — Multi-Stage Economic Skeleton *(sim only — new 2026-08-05)*
Validate the *run*, not just the stage, before content gets balanced against a possibly-wrong macro loop. Pulled forward from Phase 6 (per the review: phases 5–5.7 are content on top of a loop whose macro-structure is unvalidated, and the purchase-EV finding is the smoking gun). **No Godot work in this phase** — everything here is `sim/`, cheap, and disposable.
- [ ] **Decide `D36`** (machine persistence) — prototype both variants in sim if the answer isn't obvious on paper; this is the cheapest place to ever test it.
- [x] Multi-stage sim loop: N stages, wallet cycling per `D21`, machine scoping per `D36`, run ends on first failed stage. *(`sim/run.py`: `run_run`/`run_many_runs`/`summarize_runs`, both `D36` variants, pluggable quota curves, purchase strategies (hoard / buy-N / EV-driven), plus two experimental levers the findings forced into existence: `clear_bonus` and `bet_scale`.)*
- [x] **Answer `D22` with data:** `python -m sim.main runsweep` (4 experiments, n=400/cell). **The question got reframed by the data — see the findings block below.**
- [x] **Per-offer EV tool** in `sim/odds.py`. *(`theoretical_rtp_exact` (exact wild-aware enumeration through the real resolver, memoized), `rtp_delta_for_edit`, `offer_ev`. Confirmed the review's qualitative flags with numbers: single-crown adds are RTP-**negative** (−0.020); position asymmetry ~6.7×; wild +0.140 but unpayable at stage-1 volume.)*
- [x] **Formalize the `K4` skill-gap KPI**: `python -m sim.main compare` now ends with the gap line. **Current: +4.6pts** (target ≥10 by Phase 5 exit).
- [x] Tech debt: dual-limiter loops consolidated (`run_play_phase` is a wrapper over `run_stage` with an all-MINOR sequence; bit-identical results, pinned by the deterministic tests).
- **Exit:** `D36` and `D22` decided with sim evidence; a full ~8-stage run holds a defensible difficulty/EV shape in simulation; purchases are worth buying across a run. **Sim evidence complete (below); the D36/D22 decisions themselves await sign-off.**

### Phase 4.5 findings (2026-08-05, `python -m sim.main runsweep`, n=400/cell)

Four structural findings, each pinned by a regression test where possible:

1. **The run economy is dissipative.** Every stage force-converts the wallet through a 0.886-RTP machine and burns leftover bankroll; wallets decay ~×0.886/stage (100 → 81.6 → 58.5 → 46.9 measured). Even at quota=1.0, only ~⅓ of runs survive 8 stages. **No quota curve can fix this — the run needs stage-clear income** (genre convention: Balatro's per-blind cash, StS gold). A clear bonus ≈ 1.0×quota stabilizes wallets (~170-180).
2. **Per-stage failure compounds brutally.** 55-60% per-stage clear rates — the Phase-1 "tension band" — compound to <3% full-run clears (0.55⁸). The tension band is a *single-stage* concept and **cannot be the per-stage target in a run**: a healthy 10-25% run win rate needs per-stage clears averaging ~75-85%, ideally rising across the run.
3. **Fixed bets cap capability, making all escalation unwinnable.** Usable volume is hard-capped at spin_cap × mid-bet (~90 wagered) no matter how large the wallet grows — excess bankroll is burned — so player capability is *constant* while any escalating quota rises past it: every escalating curve collapsed to 0% full clears at fixed bets.
4. **Bet escalation is the missing design axis — and it fixes several things at once.** With bets ×(1+0.25k) per stage: flat65 jumps 2.5% → **17.5%** full clears with per-stage rates **rising 60% → 89%** (the genre's power-curve shape, emerging naturally); geo1.10 reaches 8.0%. It also scales purchase value with volume — **Wild flips EV-positive around stage-7 bet sizes** — giving purchases their first data-supported path to mattering. Candidate D22 shape: modest quota escalation (flat-to-gentle) + clear income ≈ quota + escalating bet scale, with tension carried by the run, not each stage.
   - **D36 evidence:** per-stage vs persistent machines were statistically indistinguishable in *every* experiment — purchases are currently too weak for persistence to matter. The per-stage lean stands at zero balance cost; revisit only after purchase EV is redesigned (above-crown symbols, D30 tier 2, priced against escalated bet volumes).

## Phase 5 — Boons, Curses, Bet Types
The spice, as small modifiers on defined hooks (`onBet/onSpin/onWin/onStageEnd`).
- [ ] Modifier system + first 8–10 boons/curses from the backlog.
- [ ] Alternate bet types.
- **Exit:** modifiers change how a stage plays without breaking the core, **and the `K4` skill gap widens measurably past the Phase-3 baseline (~5 points) — target ≥10 points with boons/bet types in play.** If the gap refuses to move, stop and rework the play-phase decision surface before adding more content; a static gap means the niche claim is hollow.

## Phase 5.5 — Slot Types
Prove the second gameplay axis: the payout rulesets (`07`). **Scope note (2026-08-05 review): this is the single largest scope item in the plan** — five payout resolvers, each needing its own balance pass and native bonus. So it's now explicitly staged as a **two-type slice first**:
- [ ] **Slice: Payline + hold-and-spin.** Hold-and-spin is the second type on purpose — its respin mode natively reinforces bank-vs-press, the game's differentiator, and proves the multi-type architecture (per-type resolver modules, per-type rules sections in the paytable panel) with the hardest structural questions answered.
- [ ] Validate both types' volatility via the sim harness; confirm density interacts distinctly between them (a build strong in one is weak in the other).
- [ ] **Checkpoint: is the two-type game distinct and fun?** Only then build out ways-to-win, cluster+cascade, and Megaways-style — as content on a proven pattern, not as gates.
- **Exit (slice):** two types play distinctly and are balanced by simulation. **Exit (full):** all five.

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
- [ ] **Ratings / store positioning for gambling imagery.** A literal slot-machine game should *expect* age-rating scrutiny — Balatro was rated PEGI 18 for "prominent gambling imagery" despite having no real-money anything, and had store friction over it. Not a design change; a plan-early item: know the likely rating, write the store copy accordingly, and don't discover this at submission.
- **Exit:** shippable.

## Guiding principles
1. **Cheapest decisions first.** Engine and economy before pixels.
2. **Prove the economy headless.** No graphics needed to know if it's fun.
3. **Placeholder art + real juice.** Lock feel before final art.
4. **The simulation is a permanent tool.** Balance by simulating, not guessing.
5. **Art last, on purpose.** Rich visuals sit on top of proven foundations.
