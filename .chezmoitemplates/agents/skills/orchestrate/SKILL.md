---
name: orchestrate
description: リポジトリのコード・設定・文書の変更経路を分類し、必要な場合だけplanner、test-writer、実装担当、evaluatorを調整する。Orcaのworktreeやthread、task dispatch、DAG操作には使わない。
---

# Orchestrate Command

`/orchestrate [task-description]`

## Flow

```
[User Input] → [Classify scope and verification]
                 ├─ low-risk instructions/docs/skills/config → [Client] → [Relevant checks] → [Evaluator]
                 ├─ small behavior change → [Test Writer if useful] → [Implementation Owner] → [Evaluator]
                 └─ planner route → [Planner] → [Present summary + plan path] → [User approval + Approval [x]]
                                                           → [Test Writer if useful] → [Implementation Owner(s)] → [Evaluator]
```

The main session runs this flow as the client. It owns requirements, acceptance criteria, the verification decision, role-map selection, and the final accept-or-reject. Test code is a means of checking quality, not a deliverable by default. Select the test-writer only when tests directly verify the changed behavior and are more useful than the available domain-specific checks. YAML, Terraform, documentation, skills, and agent-configuration changes often call for parsing, schema, format, lint, validate, plan, or rendered-output checks instead; when those checks adequately settle acceptance, do not create test files or invoke the test-writer. The main session may implement production code directly when delegation overhead outweighs its benefits. Keep one instance for each selected role throughout the task; evaluator feedback does not justify spawning a replacement. See `rules/agents.md` for the full role boundaries.

## Execution Steps

### Phase 0: Route selection

A component boundary alone does not trigger planner. Before selecting planner for a boundary issue, inspect current ownership, implementation, Terraform resource addresses, and source-of-truth documentation. If these settle a correction that restores established ownership or preserves the resource address, use the direct route.

Classify both the work scope and its verification before invoking an agent. The client may directly handle low-risk edits limited to instructions, documentation, skills, or agent configuration when acceptance criteria are clear and no design decision is needed, regardless of how many such source files change. For implementation work, use the planner when it needs coordinated phases or owners, component boundaries require new contract or ownership decisions, a design decision is needed, or requirements are materially ambiguous. A small implementation may skip planning when it stays within one component and one cohesive work order, has clear requirements and a shared contract, follows an existing pattern, and needs no new design decision; it may touch multiple implementation files. Use a plan when it will materially reduce integration, rework, or risk; file count alone is not a trigger. Before selecting test-writer, decide whether test code provides meaningful behavior-regression evidence; do not select it just because behavior or a configuration value changes. For YAML and Terraform, use the relevant parser/schema/format/lint/validate/plan checks when they adequately verify acceptance. Compare task size, complexity, safety, parallel-work needs, specialist knowledge, independent implementation value, and delegation overhead to choose client direct implementation or an implementation agent. After planning, choose one implementation owner per technical boundary named by the plan.

A bounded Terraform import with known resource addresses and remote IDs that follows the repository's existing pattern is a small implementation: use the direct route without planner or `plan.md`, and verify it with the applicable Terraform checks, including `terraform plan`. The number of import entries or touched Terraform files alone does not require planning.

Before spawning, write a role map in the work order: at most one planner, one test-writer, one implementation owner per technical boundary, and one evaluator for the task. Do not spawn agents per file, test, or evaluator iteration. On REVISE, send feedback to the existing owner; on a test-side defect, send it to the existing test-writer; on a design issue that requires a new design decision or contract change, return to the existing planner. Start a replacement only when the original agent is unavailable, its write scope changes, or the plan adds an uncovered boundary.

For behavior-changing implementation work, the plan or direct work order must contain a shared contract with public names, paths, argument and return types, inputs, outputs, external boundaries, and write scopes. The plan or work order must also state the verification strategy, whether test code is appropriate, and why. For an AWS Lambda task, assign Terraform files to `terraform-implementer` and application source files to `src-implementer`; run them in the plan's order and in parallel only when the plan proves their contracts independent.

When the planner route is selected, planner creates the necessary design ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`. Resolve `<repository-slug>` from the absolute Git common directory, not the worktree directory, and use a `<task-slug>` that starts with the work-start date in `YYYYMMDD-...` form. Planner records options and rejection reasons before each decision, along with the background, rationale, impact, and unresolved items or review conditions. The test-writer, implementation owners, and client do not create or edit ADRs; they return new design decisions to the existing planner. A direct route with no design decision has no ADR. Evaluator verifies every planner-created ADR without writing.

### Phase 1: Planning (conditional)

Invoke the **planner** agent (model: opus) only when Phase 0 selects the planner route:

- Pass the full task description from user input
- Planner analyzes codebase, makes design decisions, outputs the implementation plan and necessary design ADRs
- Do not paste the full plan into chat. Give the user the saved plan path and a concise summary of scope, decisions, success criteria, verification, and unresolved items.
- **HARD STOP**: Do NOT start any dependent work until the user reviews the saved plan, explicitly approves it, and its `Approval` is `[x]`
  - This includes invoking the test-writer, creating or editing tests/fixtures/mocks/helpers, running a pre-implementation RED check, or starting implementation
  - Approval examples: "OK", "go ahead", "LGTM", "approve"
- If user requests changes, re-invoke Planner with revised requirements
- Ambiguous responses ("hmm", "I see") are NOT approval. Ask for explicit confirmation
- Before giving the plan path and summary, confirm its `## Success Criteria` are verifiable acceptance criteria — each one settled by appropriate evidence such as a test, rendered output, validator, linter, or plan result, not by opinion. A test is required only when it is the appropriate evidence for that criterion. Rewrite vague ones yourself; they are the client's responsibility, not the Planner's
- For behavior changes, confirm that the plan defines the shared contract and implementation write scopes before giving the summary: public names, paths, argument and return types, inputs, outputs, external boundaries, and the `terraform`/`src` split when applicable
- Planner writes the plan to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md` and necessary design ADRs in the same directory, with an unchecked `Approval`
- Only the user may change `## Approval` from `[ ]` to `[x]` after reviewing the saved plan file
- The parent agent and every subagent must leave the checkbox unchanged and must not replace user approval with a self-reported claim
- No selected role proceeds before the user-owned checkbox is `[x]`; the test-writer and implementation owners must each pre-check it when the planner route applies, and must reject a parent-agent approval claim

For a low-risk instruction/documentation/skill/agent-configuration change, or a direct route whose verification does not need test code, do not invoke test-writer; implement directly or use the selected domain owner, run the chosen checks, and invoke evaluator. A planner route always waits for the user to review the saved plan and set the user-owned `[x]` before any dependent work, even when its verification does not use test code. For a small behavior-changing direct route where regression tests are useful, create the contract, invoke one test-writer, wait for RED, select client or an implementation agent using the Phase 0 comparison, and invoke evaluator after implementation. A direct route must state `No plan file is used for this route.` and include the settled contract and verification rationale.

### Phase 2: Implementation and verification loop (max 3 iterations)

If test code is appropriate and client is selected as the implementation owner, have the existing test-writer complete RED before client implements within the work order or approved plan. If test code is not appropriate, skip test-writer and have the client or domain owner follow the selected validation strategy. Invoke one evaluator independently in either case. If one or more implementation agents are selected, use the following loop. Create each required role instance once and reuse it for the whole task:

```
role_map = {
    "planner": one instance when the planner route is selected,
    "test-writer": one instance only when the selected verification strategy needs test code,
    "implementation owners": one instance per plan-defined technical boundary,
    "evaluator": one instance for the task,
}

if test_code_is_appropriate:
    1. In a planner route, confirm the user reviewed the saved plan and its Approval is [x]
    2. Invoke the single **test-writer** with the requirements and shared contract
    3. Wait for its explicit completion, test paths, mock assumptions, and RED evidence
    4. Do not start an implementation owner before this handoff
else:
    1. Do not invoke test-writer or create test-side files; use the plan or work order's domain-specific validation after implementation

iteration = 0
while iteration < 3:
    1. Invoke each selected implementation owner, reusing the existing instance, with:
       - The exact plan file path `~/.agents/plan/{repository_slug}/{task_slug}/plan.md` when the planner route was selected
       - The direct work order when planning was skipped
       - The test-writer's RED handoff when test code was selected, or the domain-specific validation strategy when it was not
       - Previous evaluator feedback for this owner's scope (if iteration > 0)
    2. Wait for every implementation owner to explicitly report completion and evidence. Follow the plan's order; run boundary owners in parallel only when the plan proves their contracts independent. Do not interrupt, redirect, or edit an in-progress agent scope unless a concrete blocker or an explicit client request requires it; unnecessary intervention is prohibited. Do not infer completion from elapsed time, partial output, file presence, or a parent-agent assumption.
    3. Invoke the single **evaluator** agent, reusing the existing instance, with:
       - The plan file path when one exists
       - The git diff of the implementation owner's changes
       - The ADR collection under `~/.agents/plan/{repository_slug}/{task_slug}/`
       - The role map and all applicable verification and implementation-owner evidence
    4. Wait for the evaluator's explicit verdict and evidence before deciding the next route step. Do not infer PASS or completion from partial output, file presence, or the client session's assumption.
    5. Check evaluator verdict:
       - PASS → exit loop, proceed to completion
       - REVISE caused by test-side code → increment iteration, pass feedback to the existing test-writer; after its corrected RED handoff, reuse the same implementation owner(s)
       - REVISE caused by production code → increment iteration, pass feedback to the existing implementation owner for the affected boundary; do not invoke planner for a bounded correction within the approved contract, even if the task used planner
       - REDESIGN → use only when resolving the issue requires a new design decision or a change to requirements or the shared contract; send it to the existing planner. Treat implementation defects within the approved scope as REVISE
```

### Phase 3: Completion

- Match the deliverable against the acceptance criteria yourself. An Evaluator PASS is evidence for that judgment, not a substitute for it
- Treat the task as complete only when the evaluator has explicitly returned PASS and the client has matched every acceptance criterion with recorded evidence. Do not infer completion from elapsed time, partial output, file presence, or an agent's self-report
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
Your DoD run finishes your work order; the Evaluator decides acceptance.
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
## Plan Context

Read the plan file at: ~/.agents/plan/{repository_slug}/{task_slug}/plan.md when the planner route was selected. For a direct route, evaluate the work order without a plan only when the work order explicitly states `No plan file is used for this route.` Do not infer a plan filename, slug, path, or absence of a plan.

## Role Map

{the existing planner, test-writer, implementation owners, and evaluator; reuse
these instances for this task}

## Acceptance Criteria

{the same criteria handed to the test-writer and implementation owners}

## Changes to Evaluate

Run `git diff` to see all changes made by the test-writer and implementation owners.
Read each modified file in full context.
Read every Markdown ADR under `~/.agents/plan/{repository_slug}/{task_slug}/` and verify the required sections and ordering without editing them.

## Instructions

1. Acceptance gate first: for each criterion, name the evidence that it is met
   (test name, command output, file:line). No evidence means not met, and any
   unmet criterion is REVISE. Do not rewrite or relax a criterion — return it instead
2. DoD gate: run every DoD command for the ecosystem, whole project
3. Evaluate against Security, Correctness, Code Quality, Performance, and the selected verification's quality; assess test quality only when tests were selected

Output your verdict (PASS / REVISE / REDESIGN) with the acceptance table and structured feedback.
For each issue, include file:line and specific fix instructions.
Specify whether feedback targets Client, Test-writer, an implementation owner,
or Planner.
Report defects only — do not fix anything yourself.
```

## Iteration Limits

- **Max iterations**: 3 (existing test-writer or implementation owner ⇄ existing Evaluator)
- **REDESIGN**: Return to Planner only for an actual design change. Bounded implementation corrections remain REVISE. If a second genuine REDESIGN occurs, escalate to the user.
- **After 3 iterations without PASS**: Stop and report remaining issues to user for decision.

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
-> Evaluator (sonnet): REVISE - missing edge case for burst traffic
-> Existing Test Writer or Implementation Owner: corrects the affected scope
-> Existing Evaluator (sonnet): PASS
-> Done: report to user
```
