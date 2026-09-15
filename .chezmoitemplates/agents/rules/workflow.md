# Work Process & Verification Flow

## Overview

Every task follows **Classify → Implement → Verify**. The Plan phase is conditional, not universal.

These phases are split across the client/contractor boundary defined in `agents.md`:

| Phase | Owner | What that side does |
|-------|-------|---------------------|
| Classify | Main session (client) | Chooses the route from the task size, file/component scope, design risk, and requirement clarity |
| Plan | **planner**, only for the planner route | Records design decisions and implementation steps in `~/.agents/plan/<repository-slug>/<task-slug>/plan.md` |
| Test | **test-writer** | Derives tests, fixtures, and type-appropriate mocks from the requirements and contract, then confirms RED |
| Implement | Client or implementation subagent, according to the route decision | The implementation owner uses the requirements, contract, and RED evidence to implement production code and records decisions in the ADR collection |
| Verify | **evaluator**, then the client | The evaluator runs the DoD gate and reports a verdict; the client judges the deliverable against the acceptance criteria |

The existing minor-change definition is the smallest route: one implementation file, no test needed, and no behavior change. The client may make that change directly, followed by a standalone evaluator check. A small implementation that is not a minor change may skip planning only when it stays within one component and one implementation file, has clear requirements, follows an existing pattern, and needs no new design decision. For behavior changes, use one test-writer followed by one implementation owner, then evaluator; compare the task's size, complexity, safety, parallel-work needs, specialist knowledge, independent-implementer value, and delegation overhead when choosing client or subagent ownership. Medium or larger work, multiple components, multiple implementation files, design decisions, or ambiguous requirements uses planner; after planning, choose the implementation owner with the same comparison, and always run evaluator. The required ADR is a workflow record and does not count as an implementation file for this classification.

Plans use `~/.agents/plan/<repository-slug>/<task-slug>/plan.md`, where `<repository-slug>` comes from the absolute Git common directory with `.git` removed and `<task-slug>` starts with the work-start date in `YYYYMMDD-...` form; the worktree directory name is not used and the legacy Claude plan directory is not used. Planner creates a plan with an unchecked `Approval`. The full plan is presented to the user, and only the user may explicitly approve it and change `[ ]` to `[x]`. No parent agent or subagent may change the checkbox or substitute a self-reported approval.

Every task has multiple implementation ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`. The test-writer and implementation owner create separate ADRs in Markdown with background, considered options, rejection reasons, decision, rationale, impact, and unresolved items or review conditions. Options and rejection reasons must precede each decision. Planner design decisions stay in `plan.md`, test-writer, boundary specialist, generator, or client implementation decisions go in the ADR collection, and evaluator verifies every ADR without writing.

## Phase 0: Classify

Before implementation, the client records the route and role map in the work order. If any planner trigger is present — medium or larger scope, multiple components, multiple implementation files, a design decision, or ambiguous requirements — invoke planner. For a small behavior change, define the contract, use one test-writer, then compare delegation benefits with overhead for the implementation owner, and always invoke evaluator. For a minor change, the client may implement directly and evaluator runs standalone.

## Phase 1: Plan (conditional)

- Acceptance criteria are the client's deliverable for this phase. Write them before delegating — a work order without them is incomplete (see `agents.md`)
- When the user delegates a judgment, investigate and choose one approach with reasons. Ask the user only when investigation and existing conventions cannot resolve a branch that materially changes the deliverable
- Define clear, testable completion criteria
- Surface dependencies, risks, and reversibility concerns

This phase applies only to the planner route. Planner analyzes the codebase and writes design decisions and ordered steps to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md`. The plan must include verifiable success criteria. Planner leaves `Approval` unchecked and never changes it to `[x]`.

For behavior-changing work, the plan also defines the shared contract: public function or handler names, module or file paths, argument and return types, inputs and outputs, external boundaries, and each implementation owner's write scope. A small route that skips planning must put the same contract in the work order. If Terraform and source code are both in scope, the plan identifies `terraform` and `src` owners and their dependency order.

### Planner responsibilities

- Analyze requirements and existing codebase
- Make design decisions with rationale
- Define implementation steps and test strategy
- Write the plan file to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md`
- Include verifiable success criteria
- Leave the user-owned `Approval` checkbox unchanged

### Approval gate

1. Planner outputs the plan with an unchecked `Approval`
2. Client presents the full plan to the user
3. User reviews and explicitly approves
4. Only the user may update `## Approval` from `[ ]` to `[x]`
5. Only then invoke the selected implementation owner; if generator was selected, its pre-check must find no parent-agent approval claim

If user requests changes, return to Planner. If response is ambiguous, do not treat it as approval.

## Phase 2: Implement

This phase belongs to the implementation owner. The client hands over the approved plan for the planner route or the direct work order for the small route when an implementation subagent is selected. For behavior-changing work, the test-writer completes the RED handoff before implementation begins, including when the client owns production implementation. When the direct client route is selected, the client owns only the production scope, creates the ADR collection, and hands the result to evaluator. Everything below binds whoever holds the work order.

### TDD role sequence

For behavior-changing work, the client selects one test-writer and one implementation owner per planned technical boundary. The client does not create a new instance for each file or evaluator pass. The same agents receive later evidence and feedback throughout the task.

1. **Test (RED)** — test-writer reads only the requirements and shared contract, writes the tests, fixtures, and simple type-appropriate mocks, and runs the applicable test or static check to confirm failure. The test-writer must not inspect production implementation details or edit production files.
2. **Implement (GREEN)** — the implementation owner reads the requirements, shared contract, and RED evidence, then writes the minimal production change in its assigned scope. It may run the tests, but must not edit test files to make them pass.
3. **Refactor (GREEN)** — the implementation owner improves production code while keeping the test-writer's tests green. If the contract or test harness is wrong, return the evidence to the existing test-writer or planner instead of changing the test from the implementation side.
4. **Verify** — evaluator reviews the separate test and implementation scopes, confirms that both trace to the contract, and re-runs the whole-project DoD.

For AWS Lambda work that spans Terraform and source, the test-writer finishes the shared RED suite first. Then terraform-implementer and src-implementer work in the plan's order, in parallel only when the plan proves their contracts are independent. Each specialist edits only its boundary, and a single evaluator is reused for all feedback rounds.

### Subagent completion gate

When a subagent is running, do not start the next dependent step until the subagent has explicitly reported completion and provided its implementation evidence. Do not interrupt, redirect, or edit the in-progress scope unless a concrete blocker or an explicit client request requires it; unnecessary intervention is prohibited. Do not infer completion from elapsed time, partial output, file presence, or a parent-agent assumption.

### Follow existing patterns

- Read surrounding code before writing new code
- Match the project's conventions (naming, structure, error handling, module layout)
- Do not introduce custom patterns to work around standard project tooling
- Verify folder structure before creating new files; add new files only when existing structure genuinely cannot host the change

### Task runner is the source of truth (CRITICAL)

Every project defines a task runner (taskipy, npm/pnpm scripts, mise, make, etc.). Lint / format / test / type-check MUST be executed through it. Never invoke the underlying tool directly — options, target paths, and tool versions live in the task runner definition, and direct execution silently uses a different scope than CI.

| Ecosystem | Task runner call | Direct tool call (prohibited) |
|-----------|------------------|-------------------------------|
| Python (uv + taskipy) | `uv run task lint` / `test` / `format` / `type-check` | `uv run ruff check .`, `uv run mypy .` |
| Node.js (pnpm) | `pnpm lint` / `pnpm test` | `pnpm exec eslint .`, `npx tsc` |
| Node.js (npm) | `npm run lint` / `npm test` | `npx eslint .` |
| mise | `mise run lint` / `mise run test` | direct binary invocation |
| Makefile | `make lint` / `make test` | direct binary invocation |
| Terraform | (no task runner) — see `terraform` skill DoD | — |

If no task runner exists in the project, use the work order's full static verification for Markdown or configuration work without adding an out-of-scope runner. For code work, define the task runner before implementation rather than working around its absence with ad-hoc commands.

### Ad-hoc single-target execution

Running a single test file, targeting a single lint rule, or scoping a type-check to one module during iteration is allowed. This applies only while debugging — DoD verification always uses the task runner's full-project command.

Example: `uv run pytest tests/test_user.py::test_case` while debugging is fine; DoD still requires `uv run task test` against the whole project.

## Phase 3: Verify (Completion Gate)

### Who runs what

The implementation owner runs the DoD commands to finish its own work order. That run is not the gate. The gate is the **evaluator**, invoked by the client after delivery — it re-runs the DoD, reviews the diff, and returns PASS / REVISE / REDESIGN. The client does not replace that step with its own lint/test run, and does not accept a deliverable the evaluator has not passed. Once the verdict is PASS, the client matches the deliverable against the acceptance criteria in the work order, or the planner plan's `## Success Criteria` when the planner route was used, and makes the final call only with the recorded evidence.

### Prerequisites

- Implementation is complete — no half-done branches, no TODO placeholders
- The test-writer has added tests, fixtures, and mocks for code changes and confirmed RED before implementation. For Markdown or configuration changes in a project without a test runner, the work order must define static checks and those checks substitute for a test file. Reporting "done" without the applicable tests or static checks is prohibited.

### DoD execution order (never skip or reorder)

1. The test-writer adds tests or the applicable static checks and confirms RED for behavior changes
2. The implementation owner completes production code without editing test-side files
3. Run every DoD command for the ecosystem
4. On any failure, route the root cause to the existing test-writer, implementation owner, or planner and restart from step 3 after the correction
5. Report completion with the command output and implementation evidence; never infer completion from elapsed time, partial output, file presence, or an agent's self-report alone

### DoD commands per ecosystem

The concrete command list lives in the ecosystem's skill. Do not duplicate it here — refer out:

| Ecosystem | Authoritative DoD source |
|-----------|--------------------------|
| Python | `coding-standards` skill |
| Terraform | `terraform` skill |
| GitHub Actions workflow | `gh-actions` skill |
| Other | Project's task runner definitions (lint / format / test / type-check targets) |

When no skill covers the ecosystem, the DoD is: **all lint / format / test / type-check commands defined by the project's task runner, executed against the entire project.**

### Scope

Whole project, not just changed files. Per-file or per-directory verification (e.g. `<runner> lint src/changed_file`) is not acceptable for DoD, because CI runs against the entire project and drift in unchanged files still breaks the merge.

### Definition of Done

- [ ] Tests or applicable static checks added by the test-writer for the change
- [ ] Every DoD command passed with zero errors
- [ ] Verification covered the entire project (not scoped to changed files)
- [ ] No error remains — a single failure means the task is not done
- [ ] Evaluator returned PASS (for delegated work)
- [ ] The deliverable was matched against the work order acceptance criteria, or the planner plan's `## Success Criteria` when the planner route was used

## Prohibited Actions

- Writing production or test code in the main session for work that should be delegated
- Delegating a work order that carries no acceptance criteria
- Accepting a deliverable without an evaluator verdict
- Using an unsafe or lossy file operation when the execution environment provides a safer inspection or patching mechanism
- Bypassing the task runner by invoking linters, formatters, or type-checkers directly
- File-scoped or directory-scoped DoD verification (must be whole-project)
- Custom scripts written to simplify or work around standard project tooling
- Implementation patterns that deviate from the existing codebase without explicit justification

## Implementation Patterns

### Following conventions

- Read existing code before writing new code
- Refactor similar functionality consistently across the codebase
- Document custom patterns only when they are genuinely unavoidable

### Token efficiency

- Batch independent operations into parallel tool calls
- Compress context strategically between phases
- Avoid repetitive or redundant work
