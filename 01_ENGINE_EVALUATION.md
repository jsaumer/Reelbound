# 01 — Engine Evaluation *(Priority 1)*

> **DECISION LOCKED (2026-08-03): Godot 4.7.** The analysis below stands as the reasoning of record. For a 2D, desktop, small-team, data-driven slot roguelike, Godot won on fit: free/MIT with no revenue thresholds, first-class 2D rendering and juice tooling, resource files ideal for data-driven content, and the gentlest ramp for a fresh start. It is proven in-genre on Steam (Luck Be a Landlord — a slot roguelike; Brotato; Slay the Spire 2). Unity 6.x remains a documented fallback if Godot ever frustrates in practice, but the runtime-fee cloud is gone and Unity's strengths (deepest VFX, largest Asset Store, existing C# investment) didn't apply to this project or team. An optional non-blocking "spin feel" spike (see end of doc) can confirm the workflow before deep implementation.

The engine is the single most constraining decision because it sets the **visual ceiling** and the **authoring workflow**. Everything downstream depends on it. This doc frames the choice; the final call is recorded above and in `06_OPEN_QUESTIONS.md` (Decision E1).

## What we're optimizing for

From the fixed constraints:

1. **Desktop, Steam-style.** Native desktop export, controller support optional, good performance, reasonable install size.
2. **Graphically rich & visually appealing.** Strong 2D rendering, particles/shaders, smooth animation, "juice" on spins and wins.
3. **Mix of code + visual authoring.** A real scene/editor for laying out visuals and UI, *plus* a solid scripting layer for the economy logic.
4. **Roguelike content velocity.** Easy to add many symbols, boons, curses, features without fighting the tooling.
5. **Solo/small-team friendly.** Approachable, well-documented, affordable.

## Candidates

### Godot (4.x)
- **Fit:** Very strong for stylized 2D. Scene system is genuinely a mix of visual authoring + scripting (GDScript, or C# if preferred). Node-based scenes suit slot UIs well.
- **Visuals:** Good 2D renderer, shader language, particles, animation player + tweens for juice. Ceiling is high enough for an appealing 2D slot game.
- **Desktop/Steam:** First-class native export (Windows/macOS/Linux). Steam integration via GodotSteam. No royalties, MIT-licensed.
- **Content velocity:** Resources (.tres) + scenes make data-driven content (symbols/boons as resources) clean.
- **Risks:** Smaller asset ecosystem than Unity; C# tooling less mature than GDScript; 3D not a strength (irrelevant here).

### Unity
- **Fit:** Heaviest toolset; strong visual editor + C# scripting — squarely a "mix of both."
- **Visuals:** Best-in-class VFX (Shader Graph, VFX Graph, particle systems), huge Asset Store for juice/UI/audio.
- **Desktop/Steam:** Excellent native export and Steamworks support; proven for shipped Steam titles.
- **Content velocity:** ScriptableObjects are an ideal fit for data-driven roguelike content (each symbol/boon/curse as an asset).
- **Risks:** Heavier, slower iteration; licensing/pricing and past runtime-fee controversy warrant a current check; larger project overhead for a small 2D game.

### Web + render layer (PixiJS / Phaser) — *lower fit for this platform*
- **Fit:** Great reach/shareability, but our platform is **desktop/Steam**, so a browser stack means wrapping (e.g. Electron/Tauri) to ship on Steam — extra layer, larger installs, more moving parts.
- **Visuals:** Pixi is a strong GPU 2D renderer; polish ceiling is high.
- **Why it drops:** The visual authoring is code-first (weaker "mix of both"), and desktop packaging is a workaround rather than native. Keep as a fallback only if browser reach later becomes a goal.

### Others to note (not front-runners)
- **Defold** — lean, excellent for 2D, smaller community; more code-first.
- **LÖVE (Love2D)** — code-only Lua framework; contradicts the "visual authoring" preference.
- **GameMaker** — solid 2D, visual + GML scripting; viable, but data-driven roguelike content is less ergonomic than Godot resources / Unity ScriptableObjects.

## Comparison snapshot

| Criterion | Godot | Unity | Web+Pixi (wrapped) |
|---|---|---|---|
| Desktop/Steam native | ★★★ | ★★★ | ★★ (needs wrapper) |
| 2D visual ceiling | ★★★ | ★★★ | ★★★ |
| Mix code + visual authoring | ★★★ | ★★★ | ★★ (code-first) |
| Data-driven content ergonomics | ★★★ (resources) | ★★★ (ScriptableObjects) | ★★ (roll your own) |
| Iteration speed | ★★★ | ★★ | ★★★ |
| Ecosystem / assets | ★★ | ★★★ | ★★ |
| Cost / licensing simplicity | ★★★ (MIT) | ★★ (check current terms) | ★★★ |
| Small-team friendliness | ★★★ | ★★ | ★★ |

*(★ counts are a planning heuristic, not gospel — validate with the test below.)*

## Leaning

For a **2D, desktop, small-team, visually appealing slot roguelike** where you want a genuine mix of visual authoring and scripting, **Godot 4.x is the current front-runner**, with **Unity** as the strong alternative if you want the deepest VFX tooling and asset ecosystem and don't mind heavier iteration. Web/Pixi is a fallback tied to a future browser-reach goal, not this platform.

## How to actually decide (do this before committing)

Don't decide on paper alone. Run a tiny, timeboxed **"spin feel" spike** in the top two candidates:

- Build *one reel* that spins and stops with an easing curve.
- Land three symbols, play a particle burst + a number pop on a "win."
- Show the three pool numbers updating.

Judge each on: how fast you got there, how good the juice looked with low effort, and how pleasant the code+editor mix felt. Whichever wins the spike wins the engine slot. Log the result in `06_OPEN_QUESTIONS.md` (Decision E1).

## Decision checklist (fill during the spike)

- [ ] Native desktop export produces a runnable build with no fuss?
- [ ] Steam integration path confirmed (achievements/cloud saves feasible)?
- [ ] Spin easing + particle juice achievable quickly and looks good?
- [ ] Data-driven content pattern is clean (a symbol/boon as an editable asset)?
- [ ] Iteration loop (edit → run) is fast enough to enjoy?
- [ ] Licensing/cost acceptable at our scale?
- [ ] The code+visual "mix" feels right to work in day to day?
