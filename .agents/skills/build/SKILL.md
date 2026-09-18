---
name: build
description: Stage 2 of the development pipeline — decide the structure the increment needs, then implement it to its criteria.
disable-model-invocation: true
---

Stage 2 of the development pipeline. Consumes `<cycle-dir>/increment-spec.md` and produces `<cycle-dir>/build-report.md`: a working increment, plus the structural decisions a later reader would otherwise have to reverse-engineer from the diff.

You coordinate this stage. You dispatch specialists and integrate what they return; you do not do their work.

Read [`contract.md`](../../../docs/pipeline/contract.md) first — it holds the artifact contract the other stages read, and the note format `build-report.md` must follow.

## Inputs

- `<cycle-dir>/increment-spec.md`. If it does not exist, stop: the cycle has not been through `discover`, and building from a verbal summary is how the criteria get lost.
- `<cycle-dir>/ux-spec.md`, when `discover` produced one. Its states are already criteria; the interface design decides how they are presented, never which ones exist.
- The repository. Your specialists work in it directly.

## Steps

1. **Decide the structure before writing code.** Dispatch `architect` with the spec. Dispatch `contract-designer` in the same batch **only if** the increment crosses a boundary the spec names — a public API, a persisted schema, a module seam, another service. Both read only the spec, so they run together.

   *Completion criterion*: every structural decision returned names the alternative it was chosen over and the reason. A decision with one visible option was not a decision — send it back.

2. **Fan out the implementation.** One `implementer` subagent per backlog item in the spec, all in a single batch. The items are independent by construction — `discover` cut them that way, and one item's code is not an input to another's. Give each implementer its item, its criteria, the structure from step 1, and the repository conventions — from `recon.md` where it exists, since a greenfield repository has none and there the architect's decisions become them.

   *Completion criterion*: every item in the spec is accounted for — implemented, or reported blocked with the reason. An item silently dropped is the failure this step exists to catch.

4. **Integrate and write `build-report.md`.** Confirm the increment actually holds together in the repository: it runs, the items compose, nothing was duplicated between two implementers who could not see each other. Record the structural decisions, per-item status, and what a verifier should be suspicious of. Record each item's **first red run** too: the check that failed before the code existed is the only evidence that the check can fail at all. Start from `docs/pipeline/templates/build-report.md` and keep its headings and frontmatter keys — loose prose here is what breaks the graph.

   *Completion criterion*: `verify` can run the increment without asking how — the report names the command, the entry point and any setup.

## Specialists

| Specialist | Owns |
|---|---|
| `specialists/architect.md` | Structural decisions and the alternatives rejected |
| `specialists/contract-designer.md` | The contract across the boundary the increment touches |
| `specialists/ui-designer.md` | Composition, components and adherence to the design system in force |
| `specialists/implementer.md` | One backlog item, implemented to its criteria |

## Boundaries

- Never invoke another stage's coordinator.
- Never re-cut the scope. If the spec turns out to be unbuildable, report that to the human — the fix belongs in `discover`.
- Mark the increment done only on the strength of code that was actually run.
