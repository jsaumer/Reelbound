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
- Tune symbol **density** directly in the **reel editor** — no shelf slot needed (`D29`).
- Buy **Relics** — the shelf's generic item name (new symbol kinds you don't yet own, and later boons/bonus-wiring/structural items, `D28`) — from a rotating **shelf** (`D30`).
- Wire up **bonus features** *(only once the bonus capability is unlocked — see `08`; early runs skip this entirely)*.
- **Load bankroll** — an explicit action, shown in spins (≈ bankroll ÷ min bet). Leftover wallet auto-converts to bankroll before play (no-waste failsafe). *(See locked mechanic, D5.)*

**Starting deck & density progression.** The player begins with a base set of reels/symbols. Meta-progression unlocks new symbols, wilds, multipliers, and bonus symbols, which add to the **density** of those items available on the reels. Density is one progression axis; **slot type** (`07`) is another, and it interacts with density — the same symbol pool plays very differently by type.

### Reel editor vs. shelf — LOCKED (D29)

Symbol acquisition splits into two distinct interactions, not one:

- **Reel editor (mechanical, always available, no shelf slot).** Fluid density tuning among symbol kinds you **already own** — converts copies of a reel's *cheapest-tier filler symbol present* (cascading to the next-cheapest if exhausted) into the symbol being added, keeping that reel's total strip length unchanged. This *is* "adding a high-value symbol takes a slot filler could have used → feast-or-famine dilution" (the mechanic was already described in prose above; this is its concrete shape) — a fixed-slot swap, not a growing strip, so total probability mass per reel is conserved and every purchase is a clean, legible trade. Zero purchases = the validated Phase-1/2/3 baseline machine, unchanged. **Presented as a few pre-rolled offers, not a free reel/symbol/quantity picker (`D32`)** — see below.
- **Shelf (curated, rotating, scarce — `D5`).** Sells **Relics** — the generic name for shelf items — reserved for things you **don't yet own**: new symbol kinds, and later boons/bonus-wiring/structural items (`D28`). Buying more copies of a symbol you already have is a reel-editor action, not a shelf draft. **One-time-use effects (like applying an enchantment once obtained) are also not shelf items** — they're immediate actions, the same category as the reel editor, not a persistent listing.

### Reel editor offers — LOCKED (D32)

The reel editor is a small drafted set, not a free picker: each build phase rolls **3 offers**, each a fully specified purchase — symbol (drawn from what's already owned), target reel, and quantity (1) — with the cost shown up front. Buying one applies exactly the fixed-slot swap `D29` already defines; there's no separate reel/symbol/quantity selection step. Offers are rolled once per build phase (not per purchase); a bought offer just shows as bought, the other two stay available — unless you pay to **reroll** them (`D33`). Refines D29's original freeform picker, which read as spreadsheet-shopping — the exact thing `D5` was trying to avoid.

### Reroll and the reel ledger — LOCKED (D33)

Don't like the 3 offers? **Reroll** them for a price that **climbs each time you use it within the same build phase** (resets on the next one) — a real trade against the wallet, not a free do-over. Rerolling only replaces *unbought* offers; anything already bought is a done deal and stays exactly as purchased. This is the intended path to a symbol you just unlocked from the shelf (Wild): the offers already rolled for this build phase were fixed before you could've bought it, so rerolling is how you go looking for it instead of waiting on the next build phase's luck.

Because purchases can happen fast during a build phase and easily blur together, the play screen's existing paytable/odds panel (`02` §4, the "i" button) also shows a small **reel ledger** — a per-reel list of everything the reel editor added this build phase — so what you bought isn't forgotten by the time you're mid-stage deciding bets.

### Shelf content tiers — LOCKED (D30)

Three tiers of "new symbol kind" the shelf can offer as Relics, only the first built in Phase 4:

1. **New symbol kinds** — Wild (`02` §5: "substitutes") is Phase 4's shelf content. Scatter/bonus-trigger kinds come later, once bonus-system infrastructure (`08`) exists to make them mean anything.
2. **Standard symbols valued above the current ceiling** (today, crown) — a designed counterpart to quota escalation (`D22`): later stages can both demand more *and* supply more powerful tools, not just get harder with no compensating upside. Needs a meta-progression unlock ladder (Phase 6) to gate *when* these appear; not built in Phase 4.
3. **Enchantment charges** — a Relic that *grants the capability* to enchant a symbol (e.g., "gain 1 enchantment charge"). The Relic itself is the shelf item; *spending* the charge to actually enchant a chosen symbol is a one-time action (like the reel editor), not a second shelf listing. Needs `D27` actually implemented (Phase 5); not built in Phase 4.

Tiers 2 and 3 are **designed now, built later** — the Shelf Item shape (`D28`) isn't capped at crown's value and can represent a Relic that grants a one-time action, but Phase 4 ships with only Wild as real content, matching K1 (no bonus-adjacent systems assumed in the early game).

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
- **Bank vs press** — a win lands in *pending*; bank it (safe, counts) or roll into a gamble-up (double-or-nothing). The win moment is exactly when quitting is hardest. **Not offered on every win** (`D24`) — it surfaces with some probability (25% in the Phase 3 prototype), and is intended to eventually be gated behind an obtainable item/boon rather than always-available. Offering it on every single win tested as fatiguing rather than tense. When it is offered, it's **one flip only, not a repeatable ladder** (`D25`) — a win banks immediately rather than offering to press again; chaining is also deferred to a future unlockable, since an uncapped ladder is an easy out for a lucky player.
- **Bonus timing** — stored bonuses fired early (safety) or saved to stack with a big bet. Only possible because build and play are separate.
- **Boon/curse activation** — some are player-fired one-shots; some curses force bad choices.

### Stage path — LOCKED (D31)

The play phase isn't one undifferentiated spin session — it's a **path of nodes** the player walks through, each a different flavor of turn, all drawing from **one continuous economy**. `D6` is unchanged: a single bankroll, a single winnings total, a single spin cap, for the whole stage. Node type changes what happens on a given turn, not the underlying rules:

- **Minor** — a plain spin.
- **Elite** — a spin with a temporary modifier (a forced curse, harsher odds) for a better reward.
- **Event** — no spin; a themed choice with an immediate pool effect (e.g. spend bankroll to skip a curse, gain winnings outright — the backlog's "Inspector" is an example).
- **Rest** — a no-risk beat (a discount on loading bankroll, removing a curse).
- **Treasure** — a free Relic or wallet bump, no cost.

There's no mechanically distinct "boss fight" — the stage still ends exactly per `D6`'s dual limiter, wherever that lands along the path; node pacing can aim the climax toward the final node, but nothing new gates the win condition.

**Linear for now, not a branching map** — proves the node concept with a small UI lift before investing in route-choice map rendering. Branching (multiple paths forward, player picks the route, closer to the genre's iconic map) is the **intended future evolution**, not a rejected idea — revisit once the linear version is proven.

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

### Persistence — LOCKED (D26)

**Boons and curses persist for the entire run once acquired** — not redrafted each stage's build phase. This falls out of `D21`: the wallet already cycles across the whole run (only the pools reset per stage), so a boon is something you *own* going forward, the same way a Balatro joker or Slay the Spire relic persists until sold/removed. Re-drafting every stage would also fight the shelf's own scarcity — see `D5`'s curated, rotating shelf.

### Symbol enchantments — LOCKED (D27)

A boon or curse can optionally **target a specific owned symbol instead of the whole run** — it still persists for the run (you own the enchanted symbol), but its trigger becomes "this symbol is part of a winning combination" instead of a global hook (`onBet`/`onSpin`/`onWin`/`onStageEnd`). This generalizes ideas already in the backlog that were each hardcoded one-offs — the Multiplier Wild ("×2/×3 on any win it joins"), Tax/Bomb/Leech curse symbols — into one system: any boon/curse effect can be written once and offered either as a run-wide version or a symbol-targeted version.

**The target symbol is always player-chosen when drafted, never randomly assigned.** This isn't a new rule — it's `D17`'s existing guardrail ("random-rider spice... minimal, always visible, never primary," and `08`'s "randomness belongs in visible drafted choices, not silent rolls") applied to this specific mechanic. A silently-random enchantment target would make builds feel unowned, the exact failure mode `08` already warns against.

## 7. Meta-progression

Between runs (and possibly an in-run shop between stages), unlock new symbols, features, bet types, boons/curses, slot types, the **bonus capability** (`08`), and starting modifiers. Progression axes: **symbol density**, **slot type** (`07`), the **bonus unlock ladder** (`08`), and **structure** — the current 5-reel/3-row, 5-payline machine (`sim/config.py` / `game/scripts/economy/economy_config.gd`) is the validated **base** configuration for the Payline type, not a ceiling. Additional paylines and additional reels/rows are a distinct unlock axis from symbol density — more structure changes hit *frequency* and *combination count* independent of what's actually on the reels. Idea, not yet designed in detail: see `03_IDEA_BACKLOG.md`.

**Constraint — the core must stand alone.** Because bonuses are a mid-game unlock, the first several runs must be genuinely fun on economy alone. If the game is only fun once bonuses appear, the core is too thin — Phase 1 (prove the economy headless) is designed to catch exactly this.

**In-run shop vs. cross-run permanent unlocks — ANSWERED (D8): both, sequenced.** The in-run shop is `D5`'s drafted shelf, built in Phase 4. Cross-run permanent unlocks (symbol density, structural upgrades, the bonus ladder, bet types, slot types) are Phase 6 content layered on top — they widen *what can appear on* the in-run shelf, they don't replace it.

### Acquisition structure — what's earned vs. bought

Every category of ownable content, and how it's meant to reach the player:

| Category | Acquired via | Scope | Costs | Gated by | Builds in |
|---|---|---|---|---|---|
| Standard symbols | In-run shelf purchase (`D5`) | Per-machine (this stage) | Wallet | Symbol-density meta-unlocks | Phase 4 (mechanic) / 6 (content) |
| Scatter / Wild / Bonus-trigger symbols | Same shelf purchase | Per-machine | Wallet | Density unlocks + bonus-capability unlock | Phase 4 / 5.7 / 6 |
| Curse symbols | Mostly **forced** — boss/event, not bought | Per-machine (imposed) | Bankroll-as-bribe to avoid, sometimes | — | Phase 5, boss/event system |
| Structural upgrades (paylines/reels/rows) | Cross-run meta-unlock (ceiling) + in-run purchase (per use) | Meta: permanent. In-run: per-machine | Meta-currency + wallet | Meta-unlock ladder | Phase 6 (unlock), reuses Phase 4 shelf |
| Boons / curses (run-wide) | Drafted shelf pick (`08` Tier 3) | Whole run (`D26`) | Wallet | Nothing baseline | Phase 5 |
| Symbol enchantments | Drafted shelf pick, player picks the target symbol (`D27`) | Whole run, conditional trigger | Wallet | Nothing baseline | Phase 5 |
| Bonus features | Three tiers (`08`): meta capability → in-run wiring → in-stage charge/tuning | Meta: permanent. Wiring: per-machine. Charge/tuning: per-spin | Meta-currency → wallet → density + drafts | The unlock ladder itself | Phase 6 → 4 (wiring reuses the shelf) → 5.7 |
| Bet types | Cross-run meta-unlock, then a live per-spin choice | Permanent unlock, per-spin use | Meta-currency | Meta-unlock | Phase 5 / 6 |
| Slot types | Meta-progression reveal; stage-dictated (`D13`) | Stage property | Meta-currency (widens the pool) | Meta-unlock | Phase 5.5 / 6 |

**Phase-4 dependency (D28):** `08`'s Tier 2 already establishes that bonus-wiring purchases compete for the *same* build-budget as symbols, and boon/enchantment drafts work the same way. So the Phase 4 shelf must be built against a generic **Shelf Item** shape — `{id, category, cost, effect, unlock_requirement}` — populated with `category: symbol` items only for now (matching K1: early runs have no bonus system at all). Boons, enchantments, bonus-wiring, and structural items plug into the same mechanism later without a rework. This is the one piece of Phase 5/5.7/6 design that Phase 4's *data model* — not its content — needs to account for now.

## 8. Design pillars (the guardrails)

1. **Two phases, two skills.** Both building and playing matter.
2. **Bankroll is time.** The central resource is a countdown you convert into score.
3. **Your fault, learnably.** Failure traces to decisions, not just RNG.
4. **Keep the pull.** One or two live decisions per spin; complexity is opt-in via unlocks.
5. **Separation enables depth.** Three distinct pools give modifiers a rich surface.

## 9. What can be validated without an engine

The economy is pure math. Before/beside engine work, the whole conversion loop can be checked on paper or in a spreadsheet: starting bankroll, bet size, average payout rate, quota → is a run tense (winnable ~40–60% with naive play) rather than trivial or impossible? That question is the make-or-break of the concept and needs no graphics to answer. *(See ROADMAP Phase 1.)*
