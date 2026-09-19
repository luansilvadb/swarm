---
name: grilling
description: Grill the user relentlessly about a plan or design. Use when the user wants to stress-test a plan before building, or uses any 'grill' trigger phrases.
---

# Grilling

Interview the human until no branch of the design that matters is left undecided. The interview is not prose — it is a **ledger**: a graph of typed questions, one decision per node, plus a **guard** that refuses to let the turn close with a question unasked.

You conduct. The harness holds the decisions, so nothing decided is lost between turns and nothing undecided is quietly skipped.

## Why the shape is what it is

- **A question without declared alternatives is not a question.** Every node is a `choice` (options), a `score` (ordered levels) or a `noul` (yes/no), with the alternatives written out and one of them recommended. It forces the real decision space to be enumerated *before* asking, instead of asking something open and thinking afterwards.
- **One node, one judgment.** A question that weighs two things answers neither. If `decides` needs an "and", it is two questions.
- **Fan out first, ask one at a time.** Declare every candidate question up front — including the ones that only matter if an earlier answer goes a certain way — then ask strictly one per turn. The batching is for the graph, not for the human: three questions at once is bewildering.
- **Facts go in one state; questions point at it.** A fact is recorded once with its source, and referenced between crases in the question. A fact without a source is an invention.
- **Decisions are the human's.** A node only closes with `answer_source: user`. Your confidence in your own recommendation is recorded, and below the floor (0.5) the node is *not* decided — it is a guess, and it goes back.
- **What it costs to be wrong scales with the risk.** A `risk high` node only closes with explicit `-Confirmed`. A reversible decision does not need the same ceremony as a destructive one.
- **A cut is declared, never dropped.** A question you chose not to ask is a `cut` with a reason, and it appears in the receipt. The silently abandoned question is the one that bites during implementation.
- **The run closes on the human's word.** `conclude` happens when they say the understanding is shared; until then the guard blocks the turn from closing on an unasked question.

## The harness

`grill.ps1` next to this file. The ledger lives at `.grill.json` in the project root.

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill>/grill.ps1" <cmd>
```

| Command | What it does |
|---|---|
| `new -Plan "…"` | Opens the ledger and installs the guard. |
| `fact -Id f1 -What "…" -Source "path:line"` | Records a fact found in the repository — the state every question reads from. |
| `add -Id … -Type choice\|score\|noul -Decides "…" -Instructions "…" -Options "a,b" -Recommended "a" -Risk low\|medium\|high [-DependsOn x,y]` | Declares one question. `-Recommended` must be on the menu (a score takes the level index). |
| `next` | Picks the ready question with the most questions behind it, marks it as awaiting the human, and prints it. Ask exactly this one. |
| `answer -Id … -Value "…" -Confidence 0..1 [-Confirmed]` | Records the human's answer. |
| `block -Id … -Ask "…"` | Hands the question back: only the human can answer it. |
| `cut -Id … -Reason "…"` | Declares that this question will not be asked, and why. |
| `check` | Prints the counts and every finding. |
| `conclude` | Records the shared understanding and prints the receipt — the handoff into enactment. |
| `install` | Puts the guard in the project's `.trae/hooks.json`, merging with whatever is already there. |
| `repair` | Restores a corrupted ledger from `.grill.json.bak`. |

## The loop

1. `new -Plan "…"`.
2. `fact` for the state: what the repository already says. Read the code — do not ask the human what the code answers.
3. `add` for **every** candidate question, fanning out before asking the first. A real edge goes in `-DependsOn`; a forward reference is fine here.
4. `next`. Ask that one question, with your recommendation and why. Wait. Do not ask a second thing in the same message.
5. `answer`. If the human's answer is not on the menu, that is a question you failed to foresee: `add` it as a new node — never record an off-menu answer, and never pick the closest option for them. If the answer never comes from them, `block`. If it turns out not to matter, `cut` with the reason.
6. Repeat 4–5 until `next` has nothing ready.
7. `check` for zero blocking findings, then `conclude` — only when the human says the understanding is shared.
8. Enact the plan. The receipt is what you enact from.

Exit codes are a signal, not noise: the CLI exits `1` when it refuses (off-menu answer, missing `-Confirmed`, confidence below the floor, blocking findings, a corrupted ledger) and prints why; a successful command exits `0`.

## The guard

Deterministic, and the reason this is a harness rather than a prompt. There is nothing to configure by hand: `new` runs `install`, which writes the project's `.trae/hooks.json` — pointing the command at this script's absolute path, so moving the skill is repaired by running `install` again.

`install` is safe to run at any time. It keeps every hook group that is not ours, replaces ours when the path or the settings drifted, backs the previous file up to `hooks.json.bak`, and rebuilds the file from scratch if it was not valid JSON.

| Event | What it does |
|---|---|
| `SessionStart` | Names the state of the interrogation: what is decided, what is awaiting the human, which question is next, or that no ledger exists yet. |
| `Stop` | Blocks the turn from closing while a ready question stands unasked, a decision was taken in the human's name, or a high-risk decision is unconfirmed. |

The contract is Trae's, not an invention: input arrives as JSON on stdin (`hook_event_name`, `workspace_roots`, `cwd`, `loop_count`), `SessionStart` answers with `hookSpecificOutput.additionalContext`, and `Stop` answers with `{"decision":"block","reason":…}`. `loop_limit` is set to 2, so Trae releases the turn by itself if the block is ignored twice.

### Self-healing, and where it stops

Writing the configuration is not the same as it running: Trae needs the project hook enabled (Settings > Hooks) and an execution mode that lets the command run — and, if the mode is sandboxed, a hook may not be allowed to touch the filesystem at all. The harness does not pretend otherwise. `SessionStart` writes a heartbeat in `.trae/grill-hooks.alive`, and `install` and `check` read it: until a session has actually started in this project, they say **hooks-sem-sinal** with the fix, instead of assuming the gate is protecting anything.

The ledger heals the same way. Every write is atomic and keeps the previous state in `.grill.json.bak`, so a ledger mangled mid-write costs one command, not the interview — `check` says `repair` and `repair` says what it restored. It is one write behind on purpose: the backup is the last good state, not a guess at the current one.

Validation also runs on every mutation, so a malformed node surfaces where it is written, not ten turns later.
