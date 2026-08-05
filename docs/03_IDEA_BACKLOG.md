# 03 — Idea Backlog

A running catalogue of raw ideas to draw from during content design. Nothing here is committed or balanced — it's a well to dip into. Add freely; prune later.

## Symbols

**Standard (paying):**
- Cherry / Bell / Bar / Seven — classic ladder of low→high value.
- Gems tiered by color (a clean value hierarchy players read instantly).
- Themed sets if a theme is chosen (e.g. relics, cards, coins).

**Scatters (pay anywhere / trigger):**
- "Star" scatter — 3+ triggers free spins.
- "Coin" scatter — feeds a hold-and-spin feature.

**Wilds:**
- Basic wild (substitutes).
- Expanding wild (fills its whole reel).
- Sticky wild (stays for N spins).
- Multiplier wild (×2/×3 on any win it joins).

**Bonus (feature triggers):**
- "Vault" symbol — lands to open a bonus round.

**Curse / contamination (the risk texture):**
- Tax symbol — skims a % off the spin's payout.
- Bomb symbol — voids the spin if it lands.
- Leech symbol — drains a little bankroll when it appears.
- Others can force these onto your reels (shop event, boss).

## Bonus features

*(The bonus system as a whole is an **unlockable capability** — see `08`. These are the engines/features that unlock within it; early runs have none of them.)*

- **Free spins** — awarded spins that don't cost bankroll. The core "runway extender."
- **Hold-and-spin** — lock symbols, re-spin the rest; builds toward a payout.
- **Gamble-up** — double-or-nothing on a win (the press-your-luck heart). *(Baseline version built in Phase 3: offered at a flat probability — `D24` — as a stand-in until this bonus-feature version exists to properly gate it, and capped to a single flip rather than a repeatable ladder — `D25` — with chaining itself as a future unlockable candidate here too.)*
- **Multiplier meter** — consecutive wins raise a global multiplier; a loss resets it.
- **Pick-a-prize** — a small choice mini-event (introduces agency into a feature).
- **Cascading symbols** — winning symbols vanish, new ones fall (chain potential).

### Bonus charge sources (fill the passive meter — see `08`)

- **Charge scatter** — a "coin"/"spark" symbol that adds to the meter when it lands. Density of it = charge rate (a build decision).
- **Near-miss charge** — a whiff that *almost* hit adds a little charge (turns bad luck into progress).
- **Big-bet charge** — larger bets contribute more to the meter (ties charge to a live decision).

### Bonus tuning modifiers (drafted — visible picks, see `08`)

- "Free spins start with ×2 that grows each win."
- "+1 respin on hold-and-spin."
- "Meter charges 20% faster but bonuses pay 15% less."

## Boons (player-positive) — persist for the whole run once drafted (`D26`)

- **Overflow** — winnings above X convert back into bankroll (runway).
- **Frugal Payout** — leftover bankroll at stage end adds to score.
- **Hedged Gamble** — gamble-up wins → winnings, losses → bankroll.
- **Warm-up** — first bonus trigger of a stage is guaranteed.
- **Big-Bet Bonus** — max-bet spins get a flat payout bump.
- **Second Wind** — one free re-spin per stage when a spin whiffs.
- **Insurance** — one bust is survivable per stage (bankroll floored at 1 once).

### Spin-cap boons (act on the *time* clock — see D6)
- **Extra Reels** — +N to the spin cap this stage.
- **Refund** — a whiff (no win) refunds its spin (doesn't count against the cap).
- **Momentum** — every bonus trigger grants +1 spin.
- **Overtime** — if you're within X% of quota when the cap hits, get +3 spins.

## Curses (player-negative) — persist for the whole run once drafted (`D26`)

- **Leak** — every spin, a % of winnings drains back out (a clock).
- **Debt Spiral** — once bankroll is low, bets draw from winnings.
- **Contamination** — a curse symbol is forced onto a random reel.
- **Volatility Tax** — big bets are taxed a flat amount.
- **Cold Streak** — first N spins of a stage pay reduced.
- **Forced Max** — every 5th spin must be max bet.

### Spin-cap curses (act on the *time* clock — see D6)
- **Short Clock** — −N to the spin cap this stage.
- **Heavy Spins** — big bets cost 2 spins against the cap each.
- **Fraying** — lose a spin from the cap whenever bankroll drops below a threshold.
- **Sudden Death** — the last 3 spins pay nothing if quota isn't already in reach.

## Symbol enchantments (`D27`)

A boon/curse whose trigger is "this owned symbol is in a winning combination" instead of a global hook. Always a drafted, player-chosen target — never randomly assigned (see `D27`'s reasoning). These generalize ideas that already existed here as one-off hardcoded symbols/wilds:

- **Multiplier Wild**, generalized — any symbol enchanted with "×2/×3 on any win it joins," not just wilds.
- **Sticky / Expanding**, generalized — enchant *which* symbol gets the sticky/expanding behavior, rather than it being a fixed wild variant.
- **Tax / Bomb / Leech**, reframed — these are curse *enchantments* on a specific symbol rather than a separate "curse symbol" kind; the enchantment system subsumes them.
- New ideas the system opens up: "this Bell pays double but only on paylines 1-3," "this Star's win also refunds its spin (spin-cap interaction)," "this Cherry's win is halved but charges the bonus meter double."

## Bet types (unlockable)

- **Flat** — same stake each spin (baseline).
- **Escalating** — stake climbs each spin until a win resets it.
- **All-in** — bet the whole bankroll (one spin to glory or ruin).
- **Scatter-focus** — pays 3× but only counts scatter symbols.
- **Martingale** — auto-double after a loss (rope to hang yourself with).

## Themes / tone (for later — art direction)

- **Neon vaporwave casino** — clean, glowy, synthy; broad appeal.
- **Underground fight betting** — grimy, tense.
- **Prophecy / oracle** — symbols as omens; mystical framing.
- **Debt-spiral horror** — the loan shark is the final boss; escalating dread.
- **Carnival / rigged midway** — you run a crooked game; playful-sinister.
- **Retro fruit-machine pub** — cozy, nostalgic, low-stakes charm.

## Boss / event ideas

- **The Inspector** — forces a curse symbol unless you pay a bribe from bankroll.
- **The Whale** — a stage with a huge quota but a fat starting bankroll.
- **The Drought** — reduced trigger rates; tests consistency builds.
- **The Loan Shark** — borrow bankroll now, owe winnings later.

## Parking lot (unsorted sparks)

- **"Path B" — active/interleaved build phase** *(still parked; core commits to Path A, D20)*. Instead of build-then-play, the player plays a lighter in-stage loop that earns money + spin-cap *during* the stage, spending it on symbols/bonuses as they go, with the big slot spin as a finale. Novel but requires inventing a second gameplay loop from scratch, and it competes with the active play phase (the strongest mechanic). **The pacing/variety need this was reaching for got addressed a different way: `D31`'s node-structured play phase** (minor/elite/event/rest/treasure nodes, one continuous economy, no new spending loop) — genre-style stage structure without actually building Path B. Revisit *this* entry only if `D31`'s approach ever proves too thin on its own.
- Reels of different heights/depths per machine.
- **Structural upgrades — additional paylines, additional reels/rows.** Playtested the base 5-reel/3-row, 5-payline Payline machine (2026-08) and it holds up well enough that this is now a real unlock idea, distinct from symbol density: adding lines/reels changes hit *frequency* and combination *count*, not what's on the reels. Pairs naturally with "dead reel slots you must pay to unlock" below (unlocking structure both ways — width via lines/reels, depth via reel length). See `02_GAME_DESIGN.md` §7.
- "Dead" reel slots you must pay to unlock.
- Symbol synergies (two symbols that pay extra together).
- A "cash out early" button that banks winnings but ends the stage. *(Built — see `D23`, the post-quota cash-out choice.)*
- Daily-seed challenge mode (post-launch).
- **Jackpot / progressive** — a growing pot hit rarely; *not* a base slot type (see `07`) — better as a boss/event feature layer.
- **Expanding / colossal symbols** — big symbols spanning multiple cells; a modifier, not a slot type.
