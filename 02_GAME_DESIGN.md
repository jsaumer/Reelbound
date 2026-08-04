# 02 — Game Design *(Priority 2)*

Engine-independent. These mechanics don't care what renders them, so they can be hardened (and even paper-prototyped) in parallel with the engine evaluation.

## 1. The shape of the game

A **run** = a sequence of **stages**. Each stage has two **clean, sequential** phases (build fully completes, *then* play begins — they are not interleaved):

```
STAGE
├── BUILD PHASE   author the machine + set aside bankroll, within a budget (a prepare step)
└── PLAY PHASE    an ACTIVE press-your-luck session: spin, manage a draining bankroll,
                  convert → winnings, hit the quota before the bankroll or spin cap runs out
```

- Clear the quota → advance (harder quota, new shop options).
- Fail the play phase → run ends → meta-progression unlocks carry to future runs.
- Each stage has a **slot type** — the payout ruleset that defines how spins resolve and sets the stage's feel (see `07`). Whether the type is stage-dictated or player-chosen is an open decision (D13).

**Why two phases — and how this is NOT just Balatro (locked: "Path A").**
The build/play skeleton (prepare → score against a quota → shop → repeat) is shared by the whole deckbuilder-roguelike genre, Balatro included. The skeleton is not the differentiator. **The differentiator is that our *play phase is an active skill*, not a one-shot scoring reveal.**

- In a Balatro-like, the "score" step is essentially *instant math*: you commit a build and watch it resolve in a single deterministic burst. There are no decisions *during* scoring. It is a **one-skill** game — you build well or badly, then watch.
- In Reelbound, the play phase is a **session**, not a calculation: bankroll drains over many spins, you choose **bet size** each spin (a live throttle against two clocks — fuel and the spin cap), you **bank vs. press** on wins, and you **time bonuses/boons**. This is a genuine **second skill** — press-your-luck execution — layered on top of the build skill.

So there are **two skills and two failure modes**: you can build a great machine and still *bust it* with bad betting, or salvage a mediocre machine with disciplined play. That is the niche in one sentence: **the scoring step is a skillful press-your-luck session, not a reveal.**

**Design guardrail from this commitment:** the moment the play phase collapses into "hit spin once, watch the number resolve, did I beat quota?" — the game has drifted into a Balatro reskin. The play phase must stay an active, multi-decision session. (The build phase, by contrast, can stay a comparatively conventional shop-driven prepare step *because* the differentiation is carried by play.)

## 2. The three-pool economy (the spine)

| Pool | Role | Movement |
|------|------|----------|
| **Bankroll** | Fuel, built in the build phase. You bet *from* it. | Drains during play. |
| **Winnings** | Score. Measured against the stage quota. | Accumulates during play. |
| **Pending** | Transient press-your-luck pool before a win commits. | Committed per spin. |

**Core loop:** `bankroll → bet → spin → payout → winnings`

The machine's whole job is to be an **efficient converter** of fuel (bankroll) into score (winnings) before the fuel runs dry. This framing — a depleting resource converted into an accumulating one — is cleaner and more legible than one wobbling number, and it's what gives boons/curses a rich surface (see §6).

**Bankroll is time.** It's not score; it's how many attempts your machine gets to prove itself. This is the sentence to keep returning to.

### Stake / drain model — LOCKED (D3)
**Brutal:** the whole payout goes to **winnings**; **bankroll only ever drains**, never receiving payouts. Bankroll is a pure countdown. This falls directly out of keeping winnings a separate accumulator (D6). A boon *may* explicitly transfer winnings→bankroll as a special effect, but that's a modifier, not the baseline.

## 3. Build phase

Spend a budget to author the machine and grow the bankroll. The **split** between "spend on machine" vs "spend on bankroll" is the central build-phase decision:

- More into the **machine** → higher payout ceiling, thinner bankroll (fewer spins to realize it).
- More into the **bankroll** → more spins, weaker per-spin payout.

Authoring actions:
- Buy **symbols** from a rotating **shelf** and place them on **reels**. Adding a high-value symbol takes a slot filler could have used → feast-or-famine dilution. Money spent here is gone.
- Wire up **bonus features** *(only once the bonus capability is unlocked — see `08`; early runs skip this entirely)*.
- **Load bankroll** — an explicit action, shown in spins (≈ bankroll ÷ min bet). Leftover wallet auto-converts to bankroll before play (no-waste failsafe). *(See locked mechanic, D5.)*

**Starting deck & density progression.** The player begins with a base set of reels/symbols. Meta-progression unlocks new symbols, wilds, multipliers, and bonus symbols, which add to the **density** of those items available on the reels. Density is one progression axis; **slot type** (`07`) is another, and it interacts with density — the same symbol pool plays very differently by type.

### Build-phase budget & the machine-vs-bankroll split — LOCKED (D5)

**Model: currency-spine + drafted shelf (hybrid).** One wallet (the winnings carried over per D21). You spend from a small, rotating, curated **shelf** of symbols/features — *not* an infinite catalog — which keeps variety legible and avoids spreadsheet-shopping. Spending from the shelf is a smooth currency spend (Option A's strength); the curated shelf supplies drafting's legibility (Option B's strength) without either failure mode.

**The split mechanic: explicit "load bankroll," shown in spins.** Setting aside fuel is an *intentional* action, not a silent leftover. When the player loads bankroll, the UI shows what it buys in **time** — e.g. "≈ 20 spins at min bet" — because `bankroll ÷ bet = spins`. This makes the core pillar ("bankroll is time") a front-and-center decision every stage: *a stronger machine, or more swings at it?*

**Safety net (no coin wasted): auto-convert leftover → bankroll.** Any wallet remaining when the play phase begins auto-converts to bankroll right before the slot. The explicit load is the *real, intentional decision*; the auto-convert is an anti-frustration failsafe on the remainder only. Money spent on the shelf is gone for good — so the live symbol-vs-fuel tension still bites on every purchase; the failsafe only sweeps up whatever's left after shopping.

- **Net tension preserved:** every coin spent on a symbol is a coin that can't become fuel — a live choice at each purchase.
- **Forgiving, not punishing:** you're never penalized for not zeroing your wallet.
- **Legible:** the fuel decision is shown in spins, not abstract money.

## 4. Play phase (active)

The player actually spins and manages the bankroll. Target: **one or two live decisions per spin**, clustered around win moments. Do **not** turn a spin into a five-variable optimization — preserve the thrill of the pull.

### Single-spin decision space
```
set bet size → spin → (on win) bank it or gamble it up → (optional) fire a stored bonus/boon → repeat
```

Decision levers:
- **Bet sizing** — flat (safe/slow) vs big (fast/volatile), pressured by both a spin deadline and the bankroll floor.
- **Bank vs press** — a win lands in *pending*; bank it (safe, counts) or roll into a gamble-up (double-or-nothing). The win moment is exactly when quitting is hardest.
- **Bonus timing** — stored bonuses fired early (safety) or saved to stack with a big bet. Only possible because build and play are separate.
- **Boon/curse activation** — some are player-fired one-shots; some curses force bad choices.

### Failure
The play phase fails if **bankroll busts** or **the spin cap is reached** before **winnings** reach quota (see locked win condition below). Good failure is legible:
- A greedy build converts in big rare bursts → may run dry (bankroll clock).
- A consistent build converts steadily → may never reach the ceiling (spin clock).
Losing should trace to a *decision*, with volatility as spice — not pure luck.

### Win condition — LOCKED (D6)
Clear the **winnings quota** under a **dual limiter**: the play phase ends when **bankroll hits zero** *or* the **spin cap is reached**, whichever comes first. You win if winnings ≥ quota by then, otherwise the run ends.

Two clocks run at once:
- **Bankroll** — fuel, drains at your chosen bet rate (brutal model, D3: it only ever drains).
- **Spin cap** — a hard count of spins, and *itself a manipulable resource*: raised by boons, bonuses, shop, card effects; lowered by curses and boss effects.

They trade against each other: a **big bet** burns bankroll faster but reaches quota in fewer spins (good when the cap is tight); a **small bet** stretches bankroll but eats spins (bad when the cap binds). Which clock is the real threat changes per stage and build — that's what keeps bet-sizing a live decision every spin.

## 5. Symbols, reels, features (vocabulary)

- **Symbol kinds:** standard (pays), scatter (pays anywhere / triggers), wild (substitutes), bonus (triggers a feature), curse (contamination forced onto reels).
- **Reel:** an ordered strip of symbols; depth (length) drives dilution.
- **Machine:** N reels × visible rows + wired features.
- **Bonus features:** free spins, hold-and-spin, gamble-up, multiplier — each with a trigger (e.g. 3 scatters) or player-activation. **Bonuses are an unlockable capability, not baseline — see `08`.** Early runs have no bonus system; it's the first big meta reveal.
- **Slot type:** the payout-evaluation ruleset for a stage (paylines, ways-to-win, cluster+cascade, hold-and-spin, Megaways-style). See `07`.

*(Concrete instances live in `03_IDEA_BACKLOG.md`; slot types in `07`; the bonus system in `08`.)*

## 6. Boons & curses

They modify the play phase. The richest ones exploit pool separation by **transferring between pools** — a design space that only exists *because* the pools are separate:

- **Boon:** winnings above X convert back into bankroll (extends runway).
- **Curse:** every spin leaks a % of winnings back out (a clock).
- **Boon:** leftover bankroll at stage end adds to score (rewards efficiency).
- **Curse:** once bankroll is low, bets draw from winnings (debt spiral — the machine eats its own score).
- **Boon:** gamble-up wins → winnings, losses → bankroll (asymmetric press-your-luck).

Implemented as small modifiers on a few lifecycle hooks: `onBet`, `onSpin`, `onWin`, `onStageEnd`. Keep the hook set minimal.

## 7. Meta-progression

Between runs (and possibly an in-run shop between stages), unlock new symbols, features, bet types, boons/curses, slot types, the **bonus capability** (`08`), and starting modifiers. Progression axes: **symbol density**, **slot type** (`07`), and the **bonus unlock ladder** (`08`).

**Constraint — the core must stand alone.** Because bonuses are a mid-game unlock, the first several runs must be genuinely fun on economy alone. If the game is only fun once bonuses appear, the core is too thin — Phase 1 (prove the economy headless) is designed to catch exactly this.

Open question: **in-run shop** (spend winnings between stages) vs **cross-run permanent unlocks** vs both. Likely both. *(D8.)*

## 8. Design pillars (the guardrails)

1. **Two phases, two skills.** Both building and playing matter.
2. **Bankroll is time.** The central resource is a countdown you convert into score.
3. **Your fault, learnably.** Failure traces to decisions, not just RNG.
4. **Keep the pull.** One or two live decisions per spin; complexity is opt-in via unlocks.
5. **Separation enables depth.** Three distinct pools give modifiers a rich surface.

## 9. What can be validated without an engine

The economy is pure math. Before/beside engine work, the whole conversion loop can be checked on paper or in a spreadsheet: starting bankroll, bet size, average payout rate, quota → is a run tense (winnable ~40–60% with naive play) rather than trivial or impossible? That question is the make-or-break of the concept and needs no graphics to answer. *(See ROADMAP Phase 1.)*
