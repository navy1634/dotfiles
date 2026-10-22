# Work Process & Verification Flow

## Overview

Every task follows **Classify → Implement → Verify**. The Plan phase is conditional, not universal.

These phases are split across the client/contractor boundary defined in `agents.md`:

| Phase | Owner | What that side does |
|-------|-------|---------------------|
| Classify | Main session (client) | Chooses the route from the task size, file/component scope, design risk, and requirement clarity |
| Plan | **planner**, only for the planner route | Records design decisions and implementation steps in `~/.agents/plan/<repository-slug>/<task-slug>/plan.md` and creates the design ADRs in the same directory |
| Test | **test-writer**, only when test code is the appropriate verification | Derives only the tests, fixtures, and type-appropriate mocks justified by the requirements and contract, then confirms RED after any required plan approval |
| Implement | Client or implementation subagent, according to the route decision | The implementation owner follows the requirements, contract, and selected verification strategy; it returns new decisions to the client and does not create ADRs |
| Verify | Work owner; evaluator only when separately selected; client makes final acceptance decision | The work owner selects and runs its DoD, reports evidence, and judges its own work order complete; evaluator provides optional quality assurance after all owners finish, while the client checks the user's acceptance criteria |

Classify verification separately from task size. The existing minor-change definition remains one implementation file, no test needed, and no behavior change. Low-risk edits limited to instructions, skills, documentation, or agent configuration may also be handled directly across multiple source files when requirements are clear; file count alone does not require a planner for these changes. A small implementation may skip planning when it stays within one component and one cohesive work order, has clear requirements, follows an existing pattern, and can use an established contract; it may touch multiple implementation files. Test code is a quality tool, not a deliverable by default. Use test-writer only when a behavior test directly verifies the changed contract and is more useful than the available domain-specific checks. For YAML, Terraform, and other declarative changes, prefer the relevant parser, schema, format, lint, validate, plan, or rendered-output checks when they adequately verify acceptance. Planner is an exception to the direct route: use it only for dependent phases that need sequencing and integration, multiple technical boundaries whose contracts or owners need coordination, or unresolved material design options that affect acceptance, data, operations, or safety and whose comparison reduces a specific risk. Task size, feature/refactor/migration labels, file or module count, test needs, generic design decisions, or unclear user intent alone do not qualify. Ask the user directly when their intent is the unresolved fact. Each work owner chooses and runs the DoD for its deliverable. The client selects evaluator only for independent quality assurance of completed deliverables after all owners finish their DoD, when it materially reduces quality risk; evaluator is never used for plan or ADR assessment.

Plans use `~/.agents/plan/<repository-slug>/<task-slug>/plan.md`, where `<repository-slug>` comes from the absolute Git common directory with `.git` removed and `<task-slug>` starts with the work-start date in `YYYYMMDD-...` form; the worktree directory name is not used and the legacy Claude plan directory is not used. Planner records the selected verification method and whether test code is appropriate, with reasons, and creates a plan with an unchecked `Approval`. Give the user the saved plan path and a concise summary of scope, decisions, success criteria, verification, and unresolved items; do not paste the full plan or long excerpts into chat. The user reviews the saved plan and alone may explicitly approve it and change `[ ]` to `[x]`. Until that approval, no dependent work starts: no test-writer invocation, tests/fixtures/mocks/helpers, RED checks, or implementation. No agent may change `[ ]` to `[x]` or substitute a self-reported approval. When the planner makes a substantive revision, it must reset the canonical plan's checkbox to `[ ]`; only the user may approve it again.

Before creating a task directory, the client checks for an existing directory for the same ongoing requested outcome. A continuation, changed requirement, review correction, evaluator `REDESIGN`, or later work session reuses the original directory and exact `plan.md` path; it does not get a new date-prefixed `<task-slug>`. Create a new directory only for an independently requested outcome. Before revising the canonical `plan.md` or an ADR, read it and its diff, then edit it in place. Follow the shared `AGENTS.md` rule: archive an affected canonical file as `.old` only when a user change to requirements or requested scope supersedes an existing plan or ADR that records the former requirements. Do not archive in-progress drafts, corrections or review feedback within the same requirements, routine wording changes, or Approval-only updates. Never overwrite an existing archive. Archived files are historical only. A requirement change that materially revises the canonical plan resets its `Approval` to `[ ]`; evaluator PASS and approval recorded in an archive do not approve the revised plan. Do not begin dependent work or external operations such as registering secrets, changing connection destinations, or running workflows or CI until the user explicitly approves the current plan.

When the planner route is selected, planner creates the required ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/` in Markdown with background, considered options, rejection reasons, decision, rationale, impact, and unresolved items or review conditions. Options and rejection reasons must precede each decision. Planner records design decisions in both `plan.md` and the ADRs, then self-checks their completeness and consistency before reporting. The test-writer, boundary specialist, generator, and client do not create or edit ADRs; they return new decisions to the client, which checks whether the current planner permission covers the scope and obtains fresh permission when it does not. A direct route may record a settled decision without planner. Planner reports only to the client; `planner → evaluator` handoff is prohibited. The client handles plan and ADR quality with the planner; evaluator is never used for that work.

## Phase 0: Classify

A component boundary alone does not require planner. Before treating a boundary issue as a new contract or ownership decision, inspect the current implementation, established module ownership, Terraform resource addresses, and source-of-truth documentation. If these settle the correction, use the direct route; returning a resource to its established module while preserving its address is an implementation correction.

Before implementation, the client records the route and acceptance criteria in the work order. The work owner selects the applicable DoD from the agreed requirements, project instructions, and relevant skills. A task may touch multiple implementation files and still use the direct route when it is cohesive, follows an existing pattern, and has clear requirements; use a plan only when one of the planner criteria above applies and planning materially reduces a named risk. A new design decision or requirement question does not automatically trigger planner. For a small behavior change, select one test-writer only when test code is useful, then compare delegation benefits with overhead for the implementation owner. For declarative changes with adequate domain checks, skip test-writer and follow those checks. For a minor change, the client may implement directly and run applicable checks. Select evaluator only for optional quality assurance of completed deliverables after every work owner completes its DoD, when separate QA materially reduces quality risk; never use it to assess a plan or ADR.

Before the first planner handoff for an outcome, the client states the qualifying criterion and evidence, why direct handling is insufficient, the concrete risk planning reduces, and the proposed scope, then asks the user for explicit permission through the available question tool. Wait for a clear affirmative answer before sending planner the task, partial analysis, or source-inspection work, or creating a plan or ADR. A task request, a request for a plan, and later `Approval [x]` are not invocation permission. Permission covers continuation and corrections within the same outcome and scope; a new outcome or material scope change requires fresh permission. If the user declines, has not answered, or gives an unclear answer, do not invoke planner; continue directly if safe, otherwise ask about the specific unresolved requirement or report the blocker. This permission is separate from plan review and `Approval [x]`.

A bounded Terraform import with known resource addresses and remote IDs that follows the repository's existing pattern uses the direct route without planner or `plan.md`; verify it with the applicable Terraform checks, including `terraform plan`. Do not select the planner route solely because the import has multiple entries or touches multiple Terraform files.

## Phase 1: Plan (conditional)

- Acceptance criteria are the client's deliverable for this phase. Write them before delegating — a work order without them is incomplete (see `agents.md`)
- When the user delegates a judgment, investigate and choose one approach with reasons. Ask the user only when investigation and existing conventions cannot resolve a branch that materially changes the deliverable
- Define clear, verifiable completion criteria and select evidence appropriate to the change
- Surface dependencies, risks, and reversibility concerns

This phase applies only after the client has checked the planner criteria and the user has explicitly authorized the handoff. Before doing any source inspection or creating files, planner verifies that the work order includes the qualifying evidence and the user's permission response; if either is missing, planner returns `[BLOCKED]` to the client without starting. Planner then analyzes the codebase, writes design decisions and ordered steps to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md`, and creates the design ADRs in the same directory. The plan must include verifiable success criteria. Planner leaves `Approval` unchecked and never changes it to `[x]`.

For behavior-changing implementation work, the plan also defines the shared contract: public function or handler names, module or file paths, argument and return types, inputs and outputs, external boundaries, and each implementation owner's write scope. The plan includes a verification strategy and explains whether test code is appropriate. A small route that skips planning must put the same contract and verification decision in the work order. If Terraform and source code are both in scope, the plan identifies `terraform` and `src` owners and their dependency order.

### Planner responsibilities

- Analyze requirements and existing codebase
- Make design decisions with rationale
- Define implementation steps and an appropriate verification strategy, including whether test code is needed and why
- Write the plan file to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md`
- Write the design ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`
- Include verifiable success criteria
- Never change `Approval` from `[ ]` to `[x]`; reset it from `[x]` to `[ ]` when making a substantive revision
- Before reporting completion, inspect the final plan and active ADRs; map requirements to plan content, verify source-backed claims and consistency, confirm verification is feasible, and list any assumptions or unresolved items
- Return the completed files, exact paths, Approval state, and self-review evidence to the client; never hand off directly to the evaluator

### Approval gate

1. Planner outputs the plan with an unchecked `Approval`
2. Client gives the user the saved plan path and a concise summary without pasting the full plan into chat
3. User reviews and explicitly approves
4. Only the user may update `## Approval` from `[ ]` to `[x]`
5. Only then begin dependent work. Invoke test-writer only if the approved verification strategy requires test code; if generator was selected, its pre-check must find no parent-agent approval claim

If the user requests changes within the authorized outcome and scope, return them to the existing Planner and reuse the canonical task directory. If the request materially expands the scope, obtain fresh permission through the planner invocation gate before resubmitting it. An ambiguous response is not plan approval.

## Phase 2: Implement

This phase belongs to the implementation owner. The client hands over the approved plan for the planner route or the direct work order for the small route when an implementation subagent is selected. When test code is appropriate, the test-writer completes the RED handoff before implementation begins, including when the client owns production implementation. Otherwise, the implementation owner follows the selected domain-specific validation and no test-writer or static RED step is required. When the direct client route is selected, the client owns only the production scope and does not create ADRs; a new decision returns to the client, which checks whether the planner criteria apply and obtains user permission before any planner handoff. Everything below binds whoever holds the work order.

### Test-first sequence when appropriate

When the approved verification strategy selects regression tests, the client selects one test-writer and one implementation owner per planned technical boundary. The client does not create a new instance for each file or evaluator pass. The same agents receive later evidence and feedback throughout the task. Test code is not required merely because the work changes behavior.

1. **Test (RED)** — only after any required plan approval, test-writer reads the requirements and shared contract, writes only the justified tests, fixtures, and simple type-appropriate mocks, and confirms RED with the relevant behavior test. It must not inspect production implementation details or edit production files.
2. **Implement (GREEN)** — the implementation owner reads the requirements, shared contract, and RED evidence, then writes the minimal production change in its assigned scope. It may run the selected tests, but must not edit test files to make them pass.
3. **Refactor (GREEN)** — the implementation owner improves production code while keeping the selected tests green. If the test harness is wrong, return the evidence to the existing test-writer. If the implementation is wrong but can be corrected within the agreed plan and contract, return it as REVISE to the same implementation owner. Return new design decisions or contract changes to the client; the client checks the planner criteria and obtains user permission before any planner handoff.
4. **Verify** — implementation owner runs the applicable DoD for the work order, checks the results, and reports evidence. The client may separately select an evaluator to provide quality assurance for the completed diff and evidence after all work owners finish, when that adds material quality value.

When tests are not the right verification, skip the test-writer sequence. Implement from the approved plan or direct work order, then run the relevant parser, schema, formatter, linter, validator, plan, rendered-output, or project checks after the change.

For AWS Lambda work that spans Terraform and source, run a shared RED suite first only when the approved verification strategy says tests are useful. Otherwise, use the Terraform and source checks assigned by the plan. Then terraform-implementer and src-implementer work in the plan's order, in parallel only when the plan proves their contracts are independent. Each specialist edits only its boundary and completes its own assigned DoD. If the client selected an evaluator, reuse that instance for one consolidated QA assessment after both owners finish and at most one follow-up when independent confirmation of corrected material findings still reduces risk.

### Subagent completion gate

When a subagent is running, do not start the next dependent step until the subagent has explicitly reported completion and provided its work evidence. Do not interrupt, redirect, or edit the in-progress scope unless a concrete blocker or an explicit client request requires it; unnecessary intervention is prohibited. A delayed response or a file not yet present while the owner is active is not a blocker and does not justify a duplicate invocation or evaluator handoff. Do not infer completion from elapsed time, partial output, file presence, or a parent-agent assumption. If a deliverable is incomplete after the owner reports completion, return it to that same owner with `REVISE`.

### Follow existing patterns

- Read surrounding code before writing new code
- Match the project's conventions (naming, structure, error handling, module layout)
- Do not introduce custom patterns to work around standard project tooling
- Verify folder structure before creating new files; add new files only when existing structure genuinely cannot host the change

## Phase 3: Verify (Completion Gate)

### Who runs what

The owner of each work unit chooses the applicable DoD from the work order, project instructions, and relevant skills, executes it, checks the results, and reports evidence. For planner work, this includes the plan and ADR self-check. The client checks the completed deliverable against the user's requirements and acceptance criteria and makes the final acceptance decision. An evaluator is optional and provides quality assurance on the finished deliverable and owner evidence only after all work owners finish their DoD, when the client determines that separate QA materially reduces risk. It does not choose or re-run DoD, certify completion, or approve a plan. Its PASS means no material issue was found within the completed-deliverable QA scope, not that the task is complete or guaranteed correct.

### Prerequisites

- Implementation is complete — no half-done branches, no TODO placeholders
- The plan or work order states the selected verification strategy. Require test-writer output and RED only when test code was selected. When test code was not selected, verify that the named domain-specific checks are run and pass; do not require test files for Markdown, YAML, Terraform, or configuration changes solely because they change.

### DoD execution order (never skip or reorder)

1. Confirm that the planner handoff had explicit user permission and the plan had user approval `Approval [x]` before dependent work began; never seek either approval retroactively
2. If test code was selected, inspect the test-writer's existing tests and RED evidence from before implementation; otherwise confirm no test-side files were created
3. The implementation owner completes the assigned scope without editing test-side files
4. Run all applicable DoD commands for the ecosystem, including domain-specific checks; run test suites where required, but do not add test code to satisfy the sequence
5. On any failure, route test-side failures to the existing test-writer and implementation failures that fit the approved plan or work order to the same implementation owner; return material design decisions or contract changes to the client, who rechecks the planner criteria and permission gate before any planner handoff
6. The work owner reports completion with its command output, self-check, and deliverable evidence; never infer completion from elapsed time, partial output, file presence, or an unsupported self-report. The client routes any specific gap to the same owner

### DoD commands per ecosystem

The concrete command list lives in the ecosystem's skill. Do not duplicate it here — refer out:

| Ecosystem | Authoritative DoD source |
|-----------|--------------------------|
| Python | `coding-standards` skill |
| Terraform | `terraform` skill |
| GitHub Actions workflow | `gh-actions` skill |
| Other | Project's task runner definitions (lint / format / test / type-check targets) |

When no skill covers the ecosystem, the DoD is: **all applicable lint / format / validation / test / type-check commands defined by the project's task runner, executed against the entire project.** Existing project test commands may be part of the DoD, but they do not imply that new test files must be authored for every change.

### Scope

Whole project, not just changed files. Per-file or per-directory verification (e.g. `<runner> lint src/changed_file`) is not acceptable for DoD, because CI runs against the entire project and drift in unchanged files still breaks the merge.

### Definition of Done

- [ ] The selected verification strategy passed; test-side files exist only when test code was appropriate and selected
- [ ] Every DoD command passed with zero errors
- [ ] Verification covered the entire project (not scoped to changed files)
- [ ] No error remains — a single failure means the task is not done
- [ ] The work owner completed and reported the selected DoD for its deliverable
- [ ] The deliverable was matched against the work order acceptance criteria, or the planner plan's `## Success Criteria` when the planner route was used

## Prohibited Actions

- Writing production or test code in the main session for work that should be delegated
- Delegating a work order that carries no acceptance criteria
- Treating evaluator PASS as a required completion gate or as a substitute for the work owner's DoD
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
