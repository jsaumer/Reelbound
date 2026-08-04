# Reelbound — Planning Set

**Engine is locked (Godot 4.7) and the Phase-1 headless economy prototype (`sim/`) has passed validation. No Godot game code yet.** The goal of this document set is to think the game through end-to-end and reach key decisions before/alongside implementation.

## What Reelbound is

A **slot-machine roguelike for desktop (Steam-style)** where you **build the machine, then survive it.** The game splits into two phases with two distinct skills: a **build phase** (author the reels, symbols, bonuses; grow a bankroll) and a **play phase** (spin the machine you built, converting a depleting bankroll into accumulating winnings before you run out). It aims to be **graphically rich and visually appealing**, not a spreadsheet with reels.

Progression runs on several axes: **symbol density** (what's on the reels — symbols, wilds, multipliers, bonus symbols), **slot type** (the payout ruleset that defines a stage — see `07`), and **bonuses** (an unlockable capability layered onto a pure-economy base — see `08`). Early runs are pure economy; bonuses are the first big meta reveal.

## Fixed constraints (from you)

- **Platform:** Desktop, Steam-style distribution.
- **Working style:** A *mix* of code and visual/drag-drop authoring.
- **Planning priority:** (1) engine/tech evaluation and (2) game design & mechanics first, then (3) visual style & art direction afterward.
- **Engine:** **Godot 4.7** — locked (E1, 2026-08-03). See `01`.

## The document set

| # | Doc | Purpose |
|---|-----|---------|
| 00 | **START_HERE** (this) | Index + how the set fits together. |
| 01 | `ENGINE_EVALUATION.md` | Compare engines against our constraints; reach a recommendation + decision checklist. **Priority 1.** |
| 02 | `GAME_DESIGN.md` | The mechanics: phases, three-pool economy, spins, failure, boons/curses. **Priority 2.** |
| 03 | `IDEA_BACKLOG.md` | Running catalogue of symbols, features, boons, curses, bet types, themes — raw ideas to draw from later. |
| 04 | `ART_DIRECTION.md` | Visual style, mood, "juice," UI feel. **Priority 3 — deliberately lighter for now.** |
| 05 | `ROADMAP.md` | Phased plan from decisions → prototype → vertical slice → content. Engine-agnostic. |
| 06 | `OPEN_QUESTIONS.md` | The live decision register. Engine is decision #1. |
| 07 | `SLOT_TYPES.md` | The five starting slot types (payout rulesets) and how each interacts with the economy and symbol density. |
| 08 | `BONUS_SYSTEM.md` | Bonuses as an unlockable capability: the three-tier (meta/run/play) structure and the unlock ladder. |

## How to use this set

1. ~~Work **01 Engine Evaluation** to a decision first~~ → **Done: engine locked to Godot 4.7 (E1).** Doc 01 stands as the reasoning of record.
2. ~~Harden **02 Game Design** and prove the economy headless (ROADMAP Phase 1)~~ → **Done: `sim/` clears the 40–60% tension band (55.1% win rate); D12/D18 locked.** Next gating work is ROADMAP **Phase 2** (Godot spin-feel prototype).
3. Feed loose ideas into **03 Idea Backlog** continuously.
4. Now that the engine is settled, **04 Art Direction** can begin firming once design/theme lock.
5. Keep **06 Open Questions** current — it's the single source of truth for what's decided vs. pending.

## The one thing to internalize

**The mechanics are engine-independent; the *feel* is not.** The three-pool economy and the build/play split can be designed and even paper-prototyped without any engine. But "graphically rich and visually appealing" is a property of the engine + art pipeline. That's why engine evaluation is priority one: it's the choice that most constrains the visual ceiling.
