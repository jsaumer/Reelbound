# Reelbound

A **slot-machine roguelike for desktop (Steam-style)** where you **build the machine, then survive it.**

Each stage splits into two phases with two distinct skills: a **build phase** (author reels, symbols, bonuses; set aside a bankroll within a budget) and an **active play phase** (spin the machine you built, converting a draining bankroll into accumulating winnings against a quota, before bankroll or the spin cap runs out). The differentiation from other deckbuilder-roguelikes lives in that active play phase — it's a skillful press-your-luck session, not a one-shot scoring reveal.

## Status

**Phase 1 complete.** Engine locked (Godot 4.7); core economy decisions locked; the headless economy prototype ([`sim/`](sim/)) clears its tension bar — 55.1% win rate at 20k naive-play runs, inside the 40–60% target band. Next milestone: Roadmap Phase 2, a spin-feel prototype in Godot. No Godot game code yet.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for repo layout, commit conventions, and decision discipline.

## The planning set

Start with [`00_START_HERE.md`](docs/00_START_HERE.md) — it indexes the whole set.

| # | Doc | Purpose |
|---|-----|---------|
| 00 | [START_HERE](docs/00_START_HERE.md) | Index + how the set fits together. |
| 01 | [ENGINE_EVALUATION](docs/01_ENGINE_EVALUATION.md) | Engine decision (Godot 4.7) and reasoning. |
| 02 | [GAME_DESIGN](docs/02_GAME_DESIGN.md) | Mechanics: phases, three-pool economy, spins, failure, boons/curses. |
| 03 | [IDEA_BACKLOG](docs/03_IDEA_BACKLOG.md) | Catalogue of symbols, features, boons, curses, bet types, themes. |
| 04 | [ART_DIRECTION](docs/04_ART_DIRECTION.md) | Visual style, "juice," UI feel (light for now). |
| 05 | [ROADMAP](docs/05_ROADMAP.md) | Phased plan from decisions → prototype → content. |
| 06 | [OPEN_QUESTIONS](docs/06_OPEN_QUESTIONS.md) | The live decision register — source of truth for decided vs. pending. |
| 07 | [SLOT_TYPES](docs/07_SLOT_TYPES.md) | The five starting slot types and how they interact with the economy. |
| 08 | [BONUS_SYSTEM](docs/08_BONUS_SYSTEM.md) | Bonuses as an unlockable capability; the three-tier structure. |

## Core decisions locked

- **Engine:** Godot 4.7 (E1)
- **Structure:** two sequential phases; differentiation in the active play phase ("Path A", D20)
- **Economy:** one currency cycling; three separate pools within a stage (D21, D2)
- **Play:** brutal bankroll drain; dual limiter (bankroll **or** manipulable spin cap) vs. a winnings quota (D3, D6)
- **Build:** currency-spine + drafted shelf; explicit "load bankroll" shown in spins; leftover auto-converts (D5)

See [`06_OPEN_QUESTIONS.md`](docs/06_OPEN_QUESTIONS.md) for the full register.
