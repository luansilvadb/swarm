---
name: discover
description: Stage 1 of the development pipeline — turn a problem into a scope, with the criteria that define done.
disable-model-invocation: true
---

Stage 1 of the development pipeline. Turns a problem statement into `<cycle-dir>/increment-spec.md`: a scope small enough to build in one pass, and acceptance criteria sharp enough that later stages never have to ask what was meant.

You coordinate this stage. You dispatch specialists and integrate what they return; you do not do their work.

Read [`contract.md`](../../../docs/pipeline/contract.md) before running — it holds the stage boundary, the artifact names the other stages read, and the note format every artifact you write must follow.

## Inputs

Ask the human for whatever is missing, before dispatching:

- the problem statement — raw is fine: a ticket, a complaint, a metric, a goal;
- the cycle name. The directory is `docs/pipeline/cycles/<cycle-name>/`.

Read `docs/pipeline/backlog.md` before cutting scope — what is already deferred there changes what is worth cutting again, and the human should not have to remember it for you.

## Steps

1. **Recon, when the repository already contains code.** Dispatch `recon` as its own subagent, before anything else. Skip it on an empty repository: there is no current state to find, and an invented one is worse than none. Fold its return into `<cycle-dir>/recon.md`.

   *Completion criterion*: the current state is on record — what exists, what must not break, which conventions are already in force — or the repository is genuinely empty and `recon` reported that.

2. **Frame and shape in parallel.** Dispatch `problem-framer` and `solution-shaper` as two subagents in a single batch. Neither reads the other's output: the framer interrogates *why*, the shaper proposes *what*. Each subagent's prompt is its `specialists/<name>.md` content plus the problem statement and the cycle directory.

   *Completion criterion*: both have returned, or a failure is named explicitly. Do not start step 3 holding one of them.

3. **Reconcile into a single increment.** The framer's evidence and the shaper's candidates usually disagree about size. Cut to the smallest slice that still delivers something a user can observe; a slice that exists only to enable a later slice is a backlog item, not an increment.

   *Completion criterion*: exactly one increment, and every slice cut to get there is already written into `docs/pipeline/backlog.md` with the reason it was left out. "Everything" is not an answer. A non-goal that lives only in this cycle's spec gets re-discarded three cycles from now.

4. **Design the interaction, when the increment has a user-facing interface.** Dispatch `ux-designer` with the reconciled increment and fold its return into `<cycle-dir>/ux-spec.md`. Skip it for a background job, a migration or an internal endpoint — an invented interface is worse than none.

   *Completion criterion*: every state the user will see is named together with the case that fails for it, empty and error included. These become criteria in the next step, so a state missing here is a state nobody will ever test.

5. **Derive the criteria.** Dispatch `criteria-writer` with the reconciled increment — and with `ux-spec.md` where it exists, since those states are criteria. It genuinely needs the increment first: this is the one real dependency inside the stage.

   *Completion criterion*: every item carries criteria a test could pass or fail, and no criterion restates the item.

6. **Open the cycle.** If `<cycle-dir>/cycle.md` does not exist, create it from `docs/pipeline/templates/cycle.md`. It is the cycle's hub note, and the hub note — not the folder — is what appears in the graph.

   *Completion criterion*: the hub note exists and links the artifacts this cycle will produce — `recon` included, when it ran — whether or not they exist yet. An unresolved link in Obsidian is normal; a missing hub note is not.

7. **Write `increment-spec.md`.** Start from `docs/pipeline/templates/increment-spec.md` and keep its headings and frontmatter keys — the templates are what hold the vault to one format, so inventing structure here breaks the graph downstream. Integrate the three returns into one document, resolving contradictions yourself; do not concatenate the specialists' outputs.

   *Completion criterion*: `verify` can write a test plan from the spec alone without reading code, and `build` can scope the work from it without a follow-up question.

## Specialists

| Specialist | Owns |
|---|---|
| `specialists/recon.md` | The current state, when the repository already has code |
| `specialists/problem-framer.md` | Who suffers, the evidence, the cost of not acting |
| `specialists/solution-shaper.md` | Candidate increments as vertical slices, with value and priority |
| `specialists/ux-designer.md` | Flow, states, copy and accessibility — the states become criteria |
| `specialists/criteria-writer.md` | DoR, DoD and per-item acceptance criteria |

Dispatch only the specialists this cycle actually raises. A one-line fix needs `criteria-writer` and nothing else.

## Boundaries

- Never invoke another stage's coordinator. The human moves the cycle between stages.
- Never write the increment's code or its test plan — those belong to `build` and `verify`.
- Specialists are reachable only through you.
