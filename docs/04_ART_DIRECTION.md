# 04 — Art Direction *(Priority 3 — light for now)*

Deliberately kept lighter until engine (01) and design (02) settle. This is a placeholder to capture direction, not to commit to a style yet. The goal for the game is **graphically rich and visually appealing**; this doc will grow once the foundations are locked.

## Why this waits

Art direction is expensive to redo and depends on decisions not yet made:
- The **engine** sets the visual ceiling and the art pipeline (sprites vs. vector, shader capabilities, particle tooling). **→ Resolved: Godot 4.7 (E1).** Godot's 2D pipeline is strong — sprite rendering, a full shader language, particles, and animation/tween tooling for juice — so the visual ceiling for this project is set by art/animation effort, not the engine.
- The **theme** (see idea backlog §Themes) sets palette, mood, and symbol design. *(Still open — D7.)*

Committing to art before those are chosen risks throwaway work. So for now we only sketch principles.

## Guiding principles (provisional)

1. **Juice is the point.** A slot's appeal is the *feel of the pull* — easing on reel stops, anticipation on near-misses, satisfying win bursts, number pops, screen shake on big hits. Budget for this from day one; it's not polish, it's core.
   - **The reel settling into its final position is the single highest-priority beat in that list.** That instant — the reel decelerating and locking onto a symbol, with the tension of not yet knowing if it's a winner — is a moment-to-moment experience in its own right, independent of the economy math underneath it. Phase 1 proved the numbers are tense on paper; Phase 2's job is to prove that same tension *lands* in the body, spin to spin. If the settle feels flat, the economy being sound won't save the game. Treat this beat as load-bearing, not decorative — see the Phase 2 exit criterion in `05`.
2. **Legibility first.** Three pools (bankroll / winnings / pending) must be readable at a glance and clearly distinct — this is a UI-design problem before it's an aesthetic one. Players track these constantly.
3. **Two-phase visual identity.** The build phase (calm, considered, editor-like) and play phase (energetic, kinetic) should *feel* different, reinforcing the two-skills design.
4. **Readable symbol hierarchy.** Value tiers must be instantly distinguishable (shape/color/size), so players read a spin outcome without effort.
5. **Restraint over noise.** Rich ≠ cluttered. A strong, consistent visual language beats maximal effects.

## Decisions parked for later

- **Theme** — pick from idea backlog once design is firm (neon casino, oracle, debt-horror, crooked carnival, retro pub…). This drives everything visual.
- **Art style** — pixel vs. vector vs. hand-painted 2D. Depends partly on engine and team capacity.
- **UI framework/layout** — the three-pool HUD, the build editor, the shop.
- **Sound direction** — deeply tied to juice; note it now, design it with the visuals.

## Placeholder-first workflow (recommendation)

When implementation starts, build with **ugly placeholder art** and *real juice*. A grey box that spins, eases, and pops with particles teaches more about feel than a beautiful static mockup. Lock the *motion and feel* first; skin it later. This also de-risks the art commitment — you validate that the game feels good before investing in a final style.

## To expand here later

- Mood board / reference collection.
- Palette + typography.
- Symbol design sheet (per chosen theme).
- Animation & VFX spec (spin, near-miss, win tiers, feature triggers).
- Sound design brief.
