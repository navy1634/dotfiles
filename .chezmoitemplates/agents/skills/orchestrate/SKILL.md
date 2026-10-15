---
name: orchestrate
description: リポジトリのコード・設定・文書の変更経路を分類し、必要な場合だけplanner、test-writer、実装担当、evaluatorを調整する。Orcaのworktreeやthread、task dispatch、DAG操作には使わない。
---

# Orchestrate Command

`/orchestrate [task-description]`

## Flow

```
[User Input] → [Classify scope and verification]
                 ├─ low-risk instructions/docs/skills/config → [Client + Relevant checks] → [Optional Evaluator QA after DoD]
                 ├─ small behavior change → [Test Writer if useful] → [Implementation Owner + DoD] → [Optional Evaluator QA after DoD]
                 └─ planner route → [Planner] → [Present summary + plan path] → [User approval + Approval [x]]
                                                           → [Test Writer if useful] → [Implementation Owner(s) + DoD] → [Optional Evaluator QA after DoD]
```

The main session runs this flow as the client. It owns requirements, acceptance criteria, route selection, and the final accept-or-reject. Each work owner selects and runs the DoD for its deliverable, then reports evidence. Test code is a means of checking quality, not a deliverable by default. Select the test-writer only when tests directly verify the changed behavior and are more useful than the available domain-specific checks. YAML, Terraform, documentation, skills, and agent-configuration changes often call for parsing, schema, format, lint, validate, plan, or rendered-output checks instead; when those checks adequately settle acceptance, do not create test files or invoke the test-writer. The main session may implement production code directly when delegation overhead outweighs its benefits. Select an evaluator only for independent quality assurance of completed deliverables, after all work owners finish their DoD, and only when it materially reduces quality risk. Never use an evaluator for plan or ADR assessment. Evaluator QA is optional and is not a completion gate. Keep one instance for each selected role throughout the task. See `rules/agents.md` for the full role boundaries.

## Execution Steps

### Phase 0: Route selection

A component boundary alone does not trigger planner. Before selecting planner for a boundary issue, inspect current ownership, implementation, Terraform resource addresses, and source-of-truth documentation. If these settle a correction that restores established ownership or preserves the resource address, use the direct route.

Classify both the work scope and its verification before invoking an agent. The client may directly handle low-risk edits limited to instructions, documentation, skills, or agent configuration when acceptance criteria are clear and no design decision is needed, regardless of how many such source files change. For implementation work, use the planner when it needs coordinated phases or owners, component boundaries require new contract or ownership decisions, a design decision is needed, or requirements are materially ambiguous. A small implementation may skip planning when it stays within one component and one cohesive work order, has clear requirements and a shared contract, follows an existing pattern, and needs no new design decision; it may touch multiple implementation files. Use a plan when it will materially reduce integration, rework, or risk; file count alone is not a trigger. Before selecting test-writer, decide whether test code provides meaningful behavior-regression evidence; do not select it just because behavior or a configuration value changes. For YAML and Terraform, use the relevant parser/schema/format/lint/validate/plan checks when they adequately verify acceptance. Compare task size, complexity, safety, parallel-work needs, specialist knowledge, independent implementation value, and delegation overhead to choose client direct implementation or an implementation agent. After planning, choose one implementation owner per technical boundary named by the plan.

A bounded Terraform import with known resource addresses and remote IDs that follows the repository's existing pattern is a small implementation: use the direct route without planner or `plan.md`, and verify it with the applicable Terraform checks, including `terraform plan`. The number of import entries or touched Terraform files alone does not require planning.

Before spawning, write a role map in the work order: at most one planner, one test-writer, one implementation owner per technical boundary, and an optional single evaluator for post-completion QA when the client has identified a concrete quality risk. Do not spawn agents per file, test, or evaluator iteration. Planner reports its finished plan and self-review to the client first; the client handles plan defects with the existing planner, and evaluator is never used to assess plan or ADR quality. The client routes evaluator findings on completed deliverables to the relevant work owner; test-side defects go to the existing test-writer and implementation defects to the affected implementation owner. Start a replacement only when the original agent is unavailable, its write scope changes, or the plan adds an uncovered boundary.

For behavior-changing implementation work, the plan or direct work order must contain a shared contract with public names, paths, argument and return types, inputs, outputs, external boundaries, and write scopes. The plan or work order must also state the verification strategy, whether test code is appropriate, and why. For an AWS Lambda task, assign Terraform files to `terraform-implementer` and application source files to `src-implementer`; run them in the plan's order and in parallel only when the plan proves their contracts independent.

When the planner route is selected, planner creates the necessary design ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`. Resolve `<repository-slug>` from the absolute Git common directory, not the worktree directory, and use a `<task-slug>` that starts with the work-start date in `YYYYMMDD-...` form. Planner records options and rejection reasons before each decision, along with the background, rationale, impact, and unresolved items or review conditions, then self-checks the plan and ADRs before reporting completion. The test-writer, implementation owners, and client do not create or edit ADRs; they return new design decisions to the existing planner. A direct route with no design decision has no ADR. The client handles plan and ADR quality; evaluator never assesses planner output.

Before creating a task directory, the client checks for an existing directory for the same ongoing requested outcome. A continuation, changed requirement, review correction, evaluator `REDESIGN`, or later work session reuses the original directory and exact `plan.md` path; it does not get a new date-prefixed `<task-slug>`. Create a new directory only for an independently requested outcome. If existing records do not establish the canonical directory, resolve it from the original work order and approval history before asking planner to create files. Before revising the canonical `plan.md` or an ADR, read it and its diff, then edit it in place. Follow the shared `AGENTS.md` rule: archive an affected canonical file as `.old` only when a user change to requirements or requested scope supersedes an existing plan or ADR that records the former requirements. Do not archive in-progress drafts, corrections or review feedback within the same requirements, routine wording changes, or Approval-only updates. Never overwrite an existing archive. Archived files are historical only. A requirement change that materially revises the canonical plan resets its `Approval` to `[ ]`; neither an archived `[x]` nor evaluator PASS approves the current plan. Do not start dependent work or external operations such as registering secrets, changing connection destinations, or running workflows or CI until the user explicitly approves the current plan.

### Phase 1: Planning (conditional)

Invoke the **planner** agent (model: opus) only when Phase 0 selects the planner route:

- Pass the full task description from user input
- Planner analyzes the relevant source of truth, makes design decisions, creates the implementation plan and necessary ADRs, then completes the planner self-review before reporting done
- Wait for the same planner to explicitly report completion. Do not interrupt or reinvoke it because the plan file is not yet visible or it has not produced a partial status update
- Do not paste the full plan into chat. Give the user the saved plan path and a concise summary of scope, decisions, success criteria, verification, and unresolved items.
- Planner reports its finished files and self-review to the client first. A direct planner-to-evaluator handoff is prohibited
- The client checks that the completed plan matches the user's requirements and approval state. If an artifact is missing, inconsistent, or unsupported by source evidence, return a concrete `REVISE` to the same planner; do not complete the plan or its self-review on planner's behalf
- Do not invoke evaluator for planner output. The client checks the plan and ADRs and routes omissions or unsupported claims to the same planner
- **HARD STOP**: Do NOT start any dependent work until the user reviews the saved plan, explicitly approves it, and its `Approval` is `[x]`
  - This includes invoking the test-writer, creating or editing tests/fixtures/mocks/helpers, running a pre-implementation RED check, or starting implementation
  - Approval examples: "OK", "go ahead", "LGTM", "approve"
- If user requests changes, re-invoke the existing Planner with the same exact task directory and `plan.md` path. Preserve the superseded version only when a user change to requirements or requested scope replaces an existing plan, as specified in the shared `AGENTS.md` rule; edit routine corrections in place without an archive. Reset `Approval` to `[ ]` when the current plan is materially revised, and present it for explicit user approval.
- Ambiguous responses ("hmm", "I see") are NOT approval. Ask for explicit confirmation
- The planner must map each client-owned acceptance criterion to feasible evidence and include the shared contract and implementation write scopes when required. If the plan omits or weakens these, return it to the same planner instead of rewriting it or asking evaluator to complete the check
- For a new task, Planner writes the plan to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md` and necessary design ADRs in the same directory, with an unchecked `Approval`; for a continuation, Planner updates the original task directory and canonical `plan.md`
- Only the user may change `## Approval` from `[ ]` to `[x]` after reviewing the saved plan file
- No agent may change the checkbox from `[ ]` to `[x]` or replace user approval with a self-reported claim; when the planner makes a substantive revision, it must reset the canonical plan's checkbox to `[ ]`
- No selected role proceeds before the user-owned checkbox is `[x]`; the test-writer and implementation owners must each pre-check it when the planner route applies, and must reject a parent-agent approval claim

For a low-risk instruction/documentation/skill/agent-configuration change, or a direct route whose verification does not need test code, do not invoke test-writer; implement directly or use the selected domain owner, and run the selected checks. Do not invoke evaluator by default for routine or low-risk work. A planner route always waits for the user to review the saved plan and set the user-owned `[x]` before any dependent work, even when its verification does not use test code. For a small behavior-changing direct route where regression tests are useful, create the contract, invoke one test-writer, wait for RED, select client or an implementation agent using the Phase 0 comparison, and have the implementation owner run its DoD. The client may add evaluator only for independent QA of completed work after all owners finish their DoD, when that materially reduces risk. Never use evaluator for plan or ADR assessment. A direct route must state `No plan file is used for this route.` and include the settled contract and verification rationale.

### Phase 2: Implementation and owner verification (max 3 correction rounds)

When test code is appropriate, have the existing test-writer complete RED before implementation. The selected implementation owner then completes the approved work order or plan and runs the DoD for its own scope. When test code is not appropriate, skip test-writer and have the work owner run the selected domain-specific checks. Invoke evaluator, if selected, only after every work owner completes its deliverable and DoD evidence.

```
role_map = {
    "planner": one instance when the planner route is selected,
    "test-writer": one instance only when the selected verification needs test code,
    "implementation owners": one instance per plan-defined technical boundary,
    "evaluator": optional, at most one instance for post-completion QA when it materially reduces quality risk; never for plan or ADR assessment,
}

if test_code_is_appropriate:
    1. In a planner route, confirm the user reviewed the saved plan and its Approval is [x]
    2. Invoke the single **test-writer** with the requirements and shared contract
    3. Wait for its explicit completion, test paths, mock assumptions, and RED evidence
    4. Do not start an implementation owner before this handoff
else:
    1. Do not invoke test-writer or create test-side files; the work owner follows the plan or work order's domain-specific verification

owner_round = 0
while owner_round < 3:
    1. Invoke each selected implementation owner with the exact plan path or direct work order, contract, and applicable prior owner feedback
    2. Wait for every owner to explicitly report completion, its selected DoD commands and results, and evidence. Follow the plan's order; parallelize boundary owners only when their contracts are independent
    3. If work or checks remain incomplete, route the concrete issue to the existing test-writer or owner. The owner corrects it and reruns its own checks. Do not invoke evaluator
    4. When all owners report complete work with their DoD evidence, exit the owner-correction loop

if evaluator_was_selected:
    1. The client invokes the existing evaluator only after all work owners complete their deliverables, self-checks, and DoD evidence
    2. The client provides the acceptance criteria, completed deliverables, complete diff, owner reports, and verification evidence. An approved plan may be included only as context for the implementation contract; do not send plans or ADRs for assessment
    3. Wait for one consolidated QA assessment. The evaluator does not run DoD, certify completion, approve the plan, assess planner output, or contact planner directly
    4. The client routes concrete findings to the existing owner. The owner fixes them and reruns its own checks
    5. Allow at most one follow-up evaluator QA check, only when the client determines that independent confirmation of corrected material findings still reduces risk
```

### Phase 3: Completion

- Match the work owner's completed deliverable and evidence against the user's acceptance criteria. The owner determines and reports whether its DoD is complete; evaluator QA is optional and is not a completion gate
- Treat the task as complete when the owner has completed its DoD and the client has matched the deliverable against every user acceptance criterion with recorded evidence. Do not infer completion from elapsed time, partial output, file presence, or an unsupported self-report
- Report final status to user
- List files changed
- Summarize the verification results and state which criterion each result settles; include test results only when test code was appropriate

## Prompt Templates

### Planner Prompt

```
Task: {user_task_description}

Working directory: {cwd}
Relevant context: {any user-provided context}

Produce a complete implementation plan following your system prompt format.
Include design decisions with rationale, ordered steps with file paths,
the shared contract (public names, paths, argument and return types, inputs,
outputs, external boundaries, and implementation write scopes), a verification
strategy, whether test code is appropriate and why, and success criteria.
```

### Test-writer Prompt

Create one test-writer only when the agreed verification strategy says test code
is appropriate. Its work order must carry the requirements, acceptance criteria,
test rationale, and shared contract; it must not carry implementation guesses as
a substitute for the contract.

```
## Requirements

{what to build and why, in the client's own words}

## Acceptance Criteria

{the verifiable criteria; do not rewrite, relax, or add to them}

## Test Code Decision

{why automated test code is needed to verify these criteria and why the
available domain-specific checks are insufficient}

## Plan Approval Pre-check

For the planner route, read the exact plan file at
~/.agents/plan/{repository_slug}/{task_slug}/plan.md and confirm its user-owned
Approval is [x]. Do not create tests, fixtures, mocks, helpers, or run RED checks
before this pre-check. If the plan is missing, Approval is [ ], or approval is
unclear, report [BLOCKED] without writing files or running checks. For a direct
route, the work order must say exactly: No plan file is used for this route.

## Shared Contract

{public names, paths, argument and return types, inputs, outputs, external
boundaries, and implementation write scopes}

## Test Scope

Files you may touch: {test, fixture, and mock paths}
Everything else is out of bounds. Do not inspect target production files to
infer behavior or edit production code.

## Instructions

Write only the tests, fixtures, and type-appropriate simple mocks justified by
the test-code decision, using the requirements and contract. Confirm RED with
the relevant behavior test, then report the paths, mock assumptions, and failure
evidence. Do not use static configuration checks to manufacture a RED step, and
do not rewrite a test to match a production implementation.
```

### Implementation Agent Prompt (iteration 0)

A work order carries all required items below. You cannot rely on the plan file alone —
state the scope boundary and the prohibitions explicitly, because the subagent
cannot see this conversation.

```
## Requirements

{what to build and why, in the client's own words}

## Route

{client or implementation owner; planner route or direct route}

## Plan

For the planner route, read the plan file at: ~/.agents/plan/{repository_slug}/{task_slug}/plan.md
For a direct implementation route, state exactly: No plan file is used for this route.

## Acceptance Criteria

{the verifiable criteria, restated here — these are the client's.
Do not rewrite, relax, or add to them. If one cannot be met as written, stop and report why.}

## Scope

Files you may touch: {paths}
Everything else is out of bounds. If you spot a problem outside this scope, report it; do not fix it.

## Patterns to Follow

Read these first and replicate their conventions: {paths}

## Shared Contract

{public names, paths, argument and return types, inputs, outputs, external
boundaries, and this owner's write scope}

## Verification Strategy

{the agreed tests or domain-specific checks; if no test code was selected, state why}

## Test Handoff

If test code was selected, read the existing test-writer's paths, mock
assumptions, and RED evidence. If it was not selected, do not invent test code
or a static RED step; follow the verification strategy above. For a planner
route, verify the exact plan path and user-owned Approval [x] before starting.
Do not edit test-side files; if the harness is defective, return the evidence to
the existing test-writer.

## ADR

For the planner route, planner creates or updates the design ADR files under `~/.agents/plan/{repository_slug}/{task_slug}/`. Record options and rejection reasons before each decision, along with the background, rationale, impact, and unresolved items or review conditions. The test-writer, implementation owners, and client do not create or edit ADRs; they return new design decisions to the existing planner. A direct route with no design decision has no ADR.

## Prohibitions

- For the planner route, implementation owners make no design decisions beyond the plan. For the direct route, keep decisions within the work order; a new design decision returns the task to the planner
- For a planner route, no implementation before the user-approved plan. When test code was selected, no implementation before the test-writer's RED. Otherwise, use the agreed domain-specific verification after implementation; do not require a static RED step
- No creation or editing of tests, fixtures, or mocks
- A parent-agent approval claim is not evidence of user approval; follow the implementation agent pre-check when a delegated implementation owner is selected
- No direct tool invocation (ruff, mypy). Use the task runner

## Instructions

Implement the selected production scope using the agreed verification strategy.
When test code was selected, consume the test-writer's RED handoff → implement
(GREEN) → fix build → refactor production code while keeping those tests
unchanged. When test code was not selected, follow the agreed domain-specific
checks and do not add tests just to satisfy a TDD sequence.
Report each step's status. If blocked, report what is unclear and stop.
You own the DoD for your work order. Select the applicable checks from the agreed
requirements, project instructions, and relevant skills; run them, inspect the
results, and report evidence. Evaluator QA is not a substitute for this work
or the acceptance decision.
```

### Implementation Agent Prompt (iteration > 0)

```
## Plan

For the planner route, read the plan file at: ~/.agents/plan/{repository_slug}/{task_slug}/plan.md. For a direct implementation route, the work order must explicitly state: No plan file is used for this route. Do not infer a plan filename, slug, path, or absence of a plan.

## Previous Evaluator Feedback

{evaluator_feedback}

## Routing

Reuse the existing implementation owner for the affected technical boundary.
If the feedback identifies a test, fixture, or mock defect, send it to the
existing test-writer instead. Do not spawn a replacement and do not edit tests
from the implementation owner.

## Instructions

Fix the issues identified by the Evaluator above.
For CRITICAL and HIGH issues: fix all of them.
For MEDIUM issues: fix if straightforward.
After fixing, run the relevant project verification for the selected strategy
and report results.
```

### Evaluator Prompt

```
## Implementation Context

For the planner route, read the approved plan only as implementation-contract context at `~/.agents/plan/{repository_slug}/{task_slug}/plan.md`. For a direct route, use the work order without a plan only when it explicitly states `No plan file is used for this route.` Do not infer a plan filename, slug, path, or absence. Never assess the plan or ADRs.

## Role Map

{the existing planner, test-writer, implementation owners, and evaluator if the
client selected one; all findings return to the client}

## Acceptance Criteria

{the same criteria handed to the test-writer and implementation owners}

## Changes to Evaluate

Run `git diff` to see the completed changes made by the test-writer and implementation owners.
Read each modified file in full context.
Do not inspect plans or ADRs as evaluation targets. Use the approved plan only as implementation-contract context.

## Instructions

1. Assess the supplied DoD evidence against the agreed criteria; do not invent criteria or run/re-run any DoD command
2. Assess the completed diff for concrete Security, Correctness, Code Quality, Performance, or verification defects; assess test quality only when tests were selected
3. Never assess plan or ADR quality. Planner owns their completeness; the client handles plan-level omissions and approval

Output one consolidated QA result (PASS / REVISE / REDESIGN) with the evidence assessed and structured findings. PASS means no material issue was found within this QA scope; it does not certify task completion, DoD, or plan approval.
For each issue, include file:line and specific fix instructions.
Send every finding to the client, who routes it to the existing owner. Never hand off directly to planner.
Report defects only — do not fix anything yourself.
```

## Iteration Limits

- **Work-owner corrections**: up to 3 rounds; the owner reruns its own applicable checks after each correction
- **Evaluator**: one consolidated QA assessment after all owners complete; at most one follow-up QA check when independent confirmation of corrected material findings still reduces risk
- **REDESIGN**: Return to Planner only for an actual design change. Bounded implementation corrections remain REVISE. If a second genuine REDESIGN occurs, escalate to the user.
- Do not invoke evaluator once per correction round or continue QA checks to obtain PASS. If work remains incomplete after 3 correction rounds, report remaining issues and evidence to the user.

## Key Constraints

- Agents cannot see each other's conversation history
- All context must be explicitly passed in prompts
- Agents cannot invoke other agents (no nesting)
- The main loop (this orchestration) controls all flow
- File-based data exchange for large outputs (plans, reports)

## Arguments

$ARGUMENTS: The task description to implement

## Workflow Types

Shorthand aliases (all follow the same loop, with adjusted Planner scope):

- `/orchestrate feature <desc>` - Full feature with architecture decisions
- `/orchestrate bugfix <desc>` - Bug investigation (Planner focuses on root cause)
- `/orchestrate refactor <desc>` - Safe refactoring (Planner focuses on preserving behavior)

## Example

```
User: /orchestrate feature "Add rate limiting to API endpoints"

-> Planner (opus): analyzes codebase, designs rate limiting strategy,
   outputs plan with middleware approach, Redis counter, per-endpoint config
-> User confirms plan
-> Test Writer (sonnet): writes independent tests and confirms RED
-> Implementation Owner (sonnet): implements production code from the contract
-> Evaluator (sonnet): identifies one concrete quality issue through post-completion QA
-> Client routes it to the existing Implementation Owner
-> Implementation Owner fixes it, reruns its DoD, and reports evidence
-> Done: client checks acceptance criteria and reports status; no evaluator PASS gate
```
