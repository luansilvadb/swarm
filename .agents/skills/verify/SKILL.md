---
name: verify
description: Stage 3 of the development pipeline — plan the proof from the criteria, then gate the increment before it ships.
disable-model-invocation: true
---

Stage 3 of the development pipeline. Two modes, entered at different times:

- **plan** — entered right after `discover`, in parallel with `build`. Reads only `increment-spec.md` and writes `<cycle-dir>/test-plan.md`. The proof derives from the criteria, never from the code, which is exactly why it does not wait for the code to exist.
- **gate** — entered after `build`. Reads the spec, the plan and `build-report.md`, and writes `<cycle-dir>/verdict.md`: evidence, and a ship / do-not-ship call.

Read [`contract.md`](../../../docs/pipeline/contract.md) first — it holds the artifact contract and the note format both artifacts of this stage must follow. If the human does not name a mode, infer it: `build-report.md` absent means `plan`.

You coordinate this stage. You dispatch specialists and integrate what they return.

## plan mode

1. **Dispatch `test-designer`** with `increment-spec.md` — and not with the repository. If the designer needs the code to decide what to test, the criteria are too weak, and that is a finding to report rather than a gap to paper over.

   *Completion criterion*: every acceptance criterion in the spec maps to at least one planned check, and every check names the condition that would make it fail.

2. **Write `test-plan.md`** from the return, one entry per criterion, starting from `docs/pipeline/templates/test-plan.md` and keeping its headings and frontmatter keys.

## gate mode

1. **Dispatch three in parallel** — `test-executor`, `code-reviewer` and `release-guard`. They read different material (the plan; the code; the DoD) and none reads another's output, so they go in one batch.

   *Completion criterion*: all three have returned. A gate holding two of three is not a gate.

2. **Reconcile and write `verdict.md`.** Start from `docs/pipeline/templates/verdict.md` and keep its headings and frontmatter keys. When the specialists disagree — a green plan against a review that found a real defect — the review wins. A passing test proves the criteria were checked, not that the increment is right.

   *Completion criterion*: every planned check has a recorded result, every review finding is either fixed or listed as accepted with the reason — and every accepted-open item is written into `docs/pipeline/backlog.md`, where the next `discover` will read it. The verdict says ship or do-not-ship in one word. "Probably fine" is not a verdict.

## Specialists

| Specialist | Owns |
|---|---|
| `specialists/test-designer.md` | The checks that would prove each criterion, planned from the spec |
| `specialists/test-executor.md` | Running them and recording evidence |
| `specialists/code-reviewer.md` | The increment read as code: defects, risks, convention breaks |
| `specialists/release-guard.md` | Whether the DoD is met, and what exactly ships |

## Boundaries

- Never invoke another stage's coordinator.
- Report defects; do not repair them, and do not dispatch anyone who would. A defect goes back to the human as a finding — `verify` that edits the increment can no longer be trusted to judge it.
- Keep the verdict honest. The stage's whole value is that its no is credible.
