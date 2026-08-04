# Contributing to Reelbound

Conventions for keeping the repo history clean and the planning set coherent. This is a small project, so the rules are light — but consistency now saves pain later once code lands.

## Repo layout

```
reelbound/
├── README.md          Repo landing page.
├── CONTRIBUTING.md    This file.
├── .gitignore         Includes Godot ignores for when implementation starts.
└── docs/              The planning set (00–08). 06_OPEN_QUESTIONS.md is the source of truth.
```

Planned future folders (not yet created):
- `sim/` — the headless Phase-1 economy model. Kept **out** of the Godot project on purpose so it stays engine-independent and testable (per Roadmap Phase 1).
- `game/` — the Godot 4.7 project, once Phase 2 begins.

## Commit message convention

Format:

```
<type>: <short imperative summary>

<optional body: what changed and why>
```

Keep the summary line under ~72 chars, in the imperative mood ("add", "fix", "restructure" — not "added"/"fixes").

### Types

| Type | Use for |
|------|---------|
| `docs` | Changes to the planning set (the common case right now). |
| `decision` | Locking, revising, or reversing a decision in `06_OPEN_QUESTIONS.md`. Reference the decision ID. |
| `design` | Substantive mechanics changes in `02_GAME_DESIGN.md` or related. |
| `idea` | Additions/pruning in `03_IDEA_BACKLOG.md`. |
| `chore` | Repo plumbing: structure, gitignore, tooling, packaging. |
| `feat` | New game functionality (once code exists). |
| `fix` | Bug fixes (once code exists). |
| `sim` | Changes to the headless economy model. |
| `test` | Tests. |

### Examples

```
decision: lock D5 — build budget = currency-spine + drafted shelf

Explicit "load bankroll" shown in spins; leftover auto-converts to
bankroll before play. See 06_OPEN_QUESTIONS.md.
```

```
docs: add spin-cap boons/curses to idea backlog
```

```
chore: move planning docs into docs/; update README links
```

```
feat: reel spin + easing stop (Phase 2 spin-feel prototype)
```

## Decision discipline

The decision register (`docs/06_OPEN_QUESTIONS.md`) is the single source of truth for what's decided vs. pending. When a decision changes:

1. Update the register **in the same commit** as any doc changes that depend on it.
2. Use a `decision:` commit and name the ID (e.g. `D13`) in the message.
3. A decision is only "locked" when it's in the Locked or Answered table with a one-line rationale — not merely discussed.
4. Reversing a locked decision is fine, but do it explicitly: move it, note the reversal and why. Don't silently contradict a locked decision elsewhere.

## Branching

While this is solo/small and planning-only, committing straight to `main` is fine. Once implementation starts, prefer short-lived branches per feature (`feat/spin-easing`, `sim/payline-model`) merged into `main` when green.

## Keeping in sync

The working copy lives on your machine; that's the source of truth for git. When drafting changes with an assistant, bring files in, edit, take them back, then commit and push yourself — you own the GitHub connection and the credentials. Suggested commit messages should follow the convention above.
