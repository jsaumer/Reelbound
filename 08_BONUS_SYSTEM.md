# 08 — Bonus System

Bonuses are **an unlockable capability layered onto a pure-economy base** — not a baseline feature. Early runs have *no bonus system at all*: just the three-pool economy (bankroll → bet → spin → winnings). Bonuses are the first big meta reveal, and even once unlocked they remain a *choice you invest in*, not a freebie.

## Why bonuses are unlockable (not baseline)

1. **Clean early game.** A first run with no bonuses is the purest teaching version of the core loop — and exactly what Phase-1 economy validation should start from.
2. **Earned, not assumed.** Unlocking "bonuses can happen at all" is a *capability* unlock — a meatier, more exciting progression beat than one more symbol.
3. **A real unlock branch.** The bonus system isn't one switch; it's a ladder the player invests in across runs (see below).

**Hard constraint:** the game must be genuinely fun *without* bonuses, on economy alone. If it's only fun once bonuses appear, the core is too thin — and Phase 1 is designed to catch exactly that. *(Logged as a constraint in `06`.)*

## The two things a "bonus" actually is

Keep these separate:

1. **The bonus round itself** — what happens when it triggers (free spins, hold-and-spin, a pick-round, a cascade multiplier ramp).
2. **The passive charge toward it** — a meter that fills from things the player influences, giving a *guaranteed* payoff built by effort, hedging against a cold RNG streak.

The passive meter is the key design move: it's a second accumulating resource beside winnings. Winnings are luck-driven; the bonus meter is **effort-driven**. That serves "your fault, learnably" — the meter is filled by *decisions*, not dice.

## Three tiers — where bonus decisions live

The whole system nests inside decision surfaces we already have (slot type, symbol density, drafted modifiers) rather than adding a hidden fourth one.

**Tier 1 — Meta (cross-run): does this capability exist?**
Permanent unlocks that widen what the game can contain. "Bonuses exist" → then specific engines → then the charge meter → then multipliers/stacking. Once unlocked, it's *available to build*, not automatically on.

**Tier 2 — Run (in-run build): do I put it on this machine?**
Even with the capability unlocked, wiring a bonus engine onto a stage's machine costs **build-budget**, competing with paying-symbol density and bankroll. Unlocking bonuses makes them *an option on the menu*, not free.

**Tier 3 — Play (in-stage): it charges and fires.**
The **bonus type** comes from the **slot type** (intrinsic, legible, no randomness — see `07`). The **charge rate** comes from **which symbols you put on the reels** (reuses the density axis — a bonus/charge scatter that fills the meter when it lands). The **variety/tuning** comes from **drafted boons/curses** (visible picks — "free spins start with ×2 that grows," "+1 respin," "meter charges 20% faster but bonuses pay 15% less").

### Sourcing summary

| Decision | Comes from | Randomness? |
|----------|-----------|-------------|
| Bonus *type* | Slot type (`07`) | None — intrinsic to the stage |
| Charge *rate* | Symbols on the reels (density unlocks) | None — a build choice |
| Bonus *tuning/variety* | Drafted boons/curses (shop) | Yes — but as **visible drafted picks** |
| Minor riders on adds | Occasional visible symbol property | Rare **spice only**, never the backbone |

Random *hidden* secondary stats are deliberately avoided as a primary source — they make builds feel unowned and fight the core pillar. Randomness belongs in *visible drafted choices*, not silent rolls.

## The unlock ladder (the concept getting deeper over time)

- **Locked** → no bonuses. Pure economy. The base game.
- **Unlock 1:** *bonuses can exist* + first engine (e.g. **free spins**). At this stage bonuses trigger from **luck/symbols only**.
- **Unlock 2:** the **passive charge meter** — now you can *build toward* bonuses, not just get lucky into them. (A separate reveal from Unlock 1 on purpose — two beats, not one.)
- **Unlock 3+:** more engines (**hold-and-spin**, **cascade multipliers**), **multipliers**, **stacking**, faster charge, etc.

Even the multiplier and passive-meter pieces are their own unlock beats rather than assumed features — stretching the progression runway so each reveal makes the game feel deeper.

## Guardrail — the meter must reward influence, not time

The charge meter fills from things the player **influences** — symbol choices, bet size, near-misses — **never purely from spin count**, or it degrades into a passive timer with no decision in it.

## Open questions (logged in `06`)

- **D14 — No-bonus opening length.** How long is the pure-economy phase before the first bonus reveal? (After run 1? After first clearing stage 3? A meta-currency threshold?)
- **D15 — Engine vs. meter as separate unlocks.** Confirm bonuses first trigger from luck/symbols, *then* the charge meter unlocks as a later beat (two reveals). Lean: yes, separate.
- **D16 — Bonus meter persistence.** Does the meter reset each stage, or carry between stages within a run? Lean: within-stage-only for the first prototype (self-contained, readable); revisit for the long-game "bank it before the stage ends?" tension later.
- **D17 — Random-rider spice.** How much (if any) visible random-rider on symbol adds? Lean: minimal, always visible, never primary.
