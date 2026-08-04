# 06 — Open Questions & Decision Register

The single source of truth for what's decided vs. pending. Update as decisions land.

## Locked (fixed constraints)

| # | Decision | Notes |
|---|----------|-------|
| C1 | Platform: **Desktop, Steam-style** | From you. |
| C2 | Working style: **mix of code + visual authoring** | From you. |
| C3 | Planning priority: **engine + design first, art after** | From you. |
| D1 | Split into distinct **Build + Play** phases | Core niche. |
| D2 | **Three separate pools** (Bankroll / Winnings / Pending) | Design spine. |
| D4 | Play phase is **active** (player spins + manages) | Core. |
| **E1** | **Engine: Godot 4.7** | Locked 2026-08-03. Best fit for a 2D, desktop, small-team, data-driven slot roguelike: free/MIT (no revenue thresholds), first-class 2D, resource files suit heavy data-driven content, and a gentle learning curve for a fresh start. Proven on Steam in-genre (Luck Be a Landlord, Brotato, Slay the Spire 2). Unity's runtime-fee risk is gone but its strengths (deep VFX, huge Asset Store, existing C# skill) didn't apply here. |

## The gating decision — RESOLVED

| # | Question | Decision | Resolved |
|---|----------|----------|----------|
| **E1** | **Which engine?** | **Godot 4.7** (see Locked table for rationale). | 2026-08-03 |

*Optional confidence spike (not blocking): build the one-reel "spin feel" test in Godot — spin + easing stop, particle burst + number pop on a win, three pool numbers updating — to confirm the workflow feels good before deep implementation. If Godot ever actively frustrates, Unity 6.x is the documented fallback, but the decision is considered locked.*

## Provisional (decide before/early in prototyping)

| # | Question | Current lean | Resolve by |
|---|----------|--------------|------------|
| *(none — D5 resolved; see Answered)* | | | |

## Open (later phases)

| # | Question | Notes |
|---|----------|-------|
| D7 | Theme / tone? | Pick from backlog once design firm. Drives art. |
| D8 | Meta: in-run shop vs cross-run unlocks vs both? | Likely both. |
| D9 | Art style (pixel/vector/painted)? | Depends on engine + theme. |
| D10 | How much controller support for Steam? | Nice-to-have; decide pre-ship. |
| D11 | Run length (how many stages)? | ~8 as a starting guess; tune by feel. |
| D12 | Difficulty scaling curve for quotas? | Answer with the Phase-1 sim. |
| D18 | Spin-cap tuning: where does the cap sit relative to `bankroll ÷ min bet`? | Phase-1 sim question. If the cap is far above the bankroll's natural spin ceiling it never binds (→ bankroll-only). Cap should sit near/below that ceiling to stay a live constraint. |
| D19 | Do free spins (bonus) consume the spin cap? | Lean **no** — not counting against the cap is their appeal. Pin when the bonus system (`08`) comes online. |

### Slot types (`07`)

| # | Question | Current lean | Notes |
|---|----------|--------------|-------|
| D13 | Is slot type stage-dictated or player-chosen? | **Stage-dictates** for first prototype | Revisit toward hybrid once the five types are individually proven. |

### Bonus system (`08`)

| # | Question | Current lean | Notes |
|---|----------|--------------|-------|
| D14 | No-bonus opening length? | (undecided) | How long the pure-economy phase lasts before the first bonus reveal. |
| D15 | Bonus engine vs. charge meter — separate unlocks? | **Separate** (two beats) | Bonuses trigger from luck/symbols first; charge meter unlocks later. |
| D16 | Bonus meter persistence? | **Within-stage only** for prototype | Carrying between stages adds long-game tension but complicates balance. |
| D17 | Random-rider spice on symbol adds? | **Minimal, always visible** | Never the primary bonus source; garnish only. |

## Design constraints (non-negotiable guardrails)

| # | Constraint | Rationale |
|---|-----------|-----------|
| K1 | The **core must be fun without bonuses**, on economy alone. | Bonuses are a mid-game unlock (`08`). If the game's only fun once they appear, the core is too thin. Phase 1 must clear its tension bar with no bonuses. |
| K2 | The **bonus charge meter fills from player influence**, never pure spin count. | Otherwise it's a passive timer with no decision (`08`). |
| K3 | **One or two live decisions per spin.** | Preserve the thrill of the pull; complexity is opt-in via unlocks (`02` pillar 4). |

## Answered

| # | Decision | Resolved | Reason |
|---|----------|----------|--------|
| **D20** | **"Path A" — differentiation lives in the PLAY phase.** Build and play are clean *sequential* phases (not interleaved). What makes the game not-Balatro is that the play phase is an **active press-your-luck session** (draining bankroll, live bet-sizing, bank-vs-press, spin cap, bonus timing), not a one-shot scoring reveal. The build phase may stay a comparatively conventional shop-driven prepare step. | 2026-08-03 | The build/play skeleton is shared by the whole genre; the skeleton isn't the niche. An active play phase is a genuine second skill with its own failure mode, and it's already designed. Chosen over "Path B" (active/interleaved build phase), which would require inventing a second gameplay loop from scratch and would compete with the play phase — the best mechanic. |
| **D21** | **One currency, cycling.** Within a stage, bankroll (drains) and winnings (accumulate) are separate pools. On clearing a stage, **winnings become the player's single spendable wallet**; in the next build phase the player chooses how much of that wallet reloads bankroll vs. buys symbols/features. Winnings never flow into bankroll *during* play — only *between* stages, via a build decision. | 2026-08-03 | Gives "the money is the same money throughout" without dissolving the in-stage pool separation. The separation's job is now to make play a *conversion* (two opposing clocks), not to prevent infinite spinning — the spin cap (D6) handles length. |
| **D5** | **Build budget = currency-spine + drafted shelf (hybrid); split via explicit "load bankroll" shown in spins; leftover wallet auto-converts to bankroll before play.** One wallet spent on a small rotating shelf (money spent is gone); fuel is loaded intentionally and shown as ≈ spins; any remainder sweeps into bankroll as a no-waste failsafe. | 2026-08-03 | Currency-spine matches D21's "spend your wallet" and preserves the smooth machine-vs-bankroll dial; the curated shelf gives drafting's legibility without spreadsheet sprawl. Explicit spins-shown loading puts "bankroll is time" front-and-center as the real decision; auto-convert makes the economy forgiving without softening the live symbol-vs-fuel tension (shelf spending is irreversible). |

| # | Decision | Resolved | Reason |
|---|----------|----------|--------|
| **D6** | **Win condition = clear the winnings quota, under a dual limiter: play ends when bankroll hits zero OR the spin cap is reached, whichever first.** The spin cap is itself a manipulable resource (raised by boons/bonuses/shop/cards, lowered by curses/bosses). | 2026-08-03 | Purest expression of "bankroll is time." The dual clock (fuel vs. spin count) keeps bet-sizing a live decision — big bets burn fuel but save spins; small bets stretch fuel but eat spins. Which clock binds varies by stage/build. |
| **D3** | **Brutal drain — bankroll only ever drains; winnings never flow back into it.** | 2026-08-03 | Falls directly out of D6's framing (winnings are a strictly separate accumulator). Makes the core countdown impossible to miss. A boon *can* explicitly transfer winnings→bankroll as a special effect, but that's a modifier, not the baseline. |

## Decision protocol

- A decision only counts as **locked** when it's moved to the Locked table with a one-line rationale.
- Provisional decisions are safe to prototype against but expected to be revisited after Phase 1's economy validation.
- **E1 (engine) is the priority** — it blocks the most downstream work.
