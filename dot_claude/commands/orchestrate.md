---
name: orchestrate
description: 作業規模と技術境界に応じてclient、planner、test-writer、実装担当、evaluatorの経路を選び、agentを再利用して最大3イテレーションで検証まで行う。
---

# Orchestrate Command

`/orchestrate [task-description]`

## Flow

```
[User Input] → [Classify]
                 ├─ minor → [Client] → [Evaluator]
                 ├─ behavior change → [Test Writer] → [Implementation Owner] → [Evaluator]
                 └─ medium+ / risk → [Planner] → [Test Writer] → [Implementation Owner(s)] → [Evaluator]
```

The main session runs this flow as the client. It owns requirements, acceptance criteria, role-map selection, and the final accept-or-reject. It may implement production code directly when the recorded comparison shows that delegation overhead outweighs the benefits, but behavior changes always require the test-writer boundary, and the result must go to evaluator for independent verification. Keep one instance for each selected role throughout the task; evaluator feedback does not justify spawning a replacement. See `rules/agents.md` for the full role boundaries.

## Execution Steps

### Phase 0: Route selection

Classify the task before invoking an agent. The minor-change route applies to one implementation file, no test needed, and no behavior change. Every behavior change uses one test-writer before implementation; a small task may skip planning when it stays within one component and one implementation file, has clear requirements and a shared contract, follows an existing pattern, and needs no new design decision. Compare task size, complexity, safety, parallel-work needs, specialist knowledge, independent implementation value, and delegation overhead to choose client direct implementation or an implementation agent. Use planner for medium or larger work, multiple components, multiple implementation files, design decisions, or ambiguous requirements. After planning, choose one implementation owner per technical boundary named by the plan. The required ADR is excluded from the implementation-file count.

Before spawning, write a role map in the work order: at most one planner, one test-writer, one implementation owner per technical boundary, and one evaluator for the task. Do not spawn agents per file, test, or evaluator iteration. On REVISE, send feedback to the existing owner; on a test-side defect, send it to the existing test-writer; on a design defect, return to the existing planner. Start a replacement only when the original agent is unavailable, its write scope changes, or the plan adds an uncovered boundary.

For behavior changes, the plan or direct work order must contain a shared contract with public names, paths, argument and return types, inputs, outputs, external boundaries, and write scopes. For an AWS Lambda task, assign Terraform files to `terraform-implementer` and application source files to `src-implementer`; run them in the plan's order and in parallel only when the plan proves their contracts independent.

Create one or more Markdown ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/` for every task. Resolve `<repository-slug>` from the absolute Git common directory, not the worktree directory, and use a `<task-slug>` that starts with the work-start date in `YYYYMMDD-...` form. The test-writer and each implementation owner record options and rejection reasons before their decisions, along with the background, rationale, impact, and unresolved items or review conditions. Evaluator verifies every ADR without writing.

### Phase 1: Planning (conditional)

Invoke the **planner** agent (model: opus) only when Phase 0 selects the planner route:

- Pass the full task description from user input
- Planner analyzes codebase, makes design decisions, outputs implementation plan
- Present plan to user **in full**
- **HARD STOP**: Do NOT proceed to Phase 2 until user explicitly approves
  - Approval examples: "OK", "go ahead", "LGTM", "approve"
- If user requests changes, re-invoke Planner with revised requirements
- Ambiguous responses ("hmm", "I see") are NOT approval. Ask for explicit confirmation
- Before presenting the plan, confirm its `## Success Criteria` are verifiable acceptance criteria — each one settled by a named test or a command output, not by opinion. Rewrite vague ones yourself; they are the client's responsibility, not the Planner's
- For behavior changes, confirm that the plan defines the shared contract and implementation write scopes before presenting it: public names, paths, argument and return types, inputs, outputs, external boundaries, and the `terraform`/`src` split when applicable
- Planner writes the plan to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md` with an unchecked `Approval`
- Only the user may change `## Approval` from `[ ]` to `[x]` after reviewing the full plan
- The parent agent and every subagent must leave the checkbox unchanged and must not replace user approval with a self-reported claim
- The selected implementation owner proceeds only after the user-owned checkbox is `[x]`; if an implementation agent is selected, its pre-check must also find no parent-agent approval claim

For the minor route, skip only the planning and test phases, have client implement directly, and invoke evaluator. The client implementation is the next step, not a skipped implementation phase. For a behavior-changing small route, create the contract, invoke one test-writer, wait for RED, select client or an implementation agent using the Phase 0 comparison, and invoke evaluator after implementation. For the planner route, continue to Phase 2 after user approval.

### Phase 2: Implementation and verification loop (max 3 iterations)

If client is selected as the implementation owner, have the existing test-writer complete RED, then have client implement within the work order or approved plan, create the ADR collection, and invoke one evaluator independently. If one or more implementation agents are selected, use the following loop. Create every role instance once and reuse it for the whole task:

```
role_map = {
    "planner": one instance when the planner route is selected,
    "test-writer": one instance for behavior changes,
    "implementation owners": one instance per plan-defined technical boundary,
    "evaluator": one instance for the task,
}

if behavior_change:
    1. Invoke the single **test-writer** with the requirements and shared contract
    2. Wait for its explicit completion, test/static-check paths, mock assumptions, and RED evidence
    3. Do not start an implementation owner before this handoff

iteration = 0
while iteration < 3:
    4. Invoke each selected implementation owner, reusing the existing instance, with:
       - The exact plan file path `~/.agents/plan/{repository_slug}/{task_slug}/plan.md` when the planner route was selected
       - The direct work order when planning was skipped
       - The test-writer's RED handoff
       - Previous evaluator feedback for this owner's scope (if iteration > 0)
    5. Wait for every implementation owner to explicitly report completion and evidence. Follow the plan's order; run boundary owners in parallel only when the plan proves their contracts independent. Do not interrupt, redirect, or edit an in-progress agent scope unless a concrete blocker or an explicit client request requires it; unnecessary intervention is prohibited. Do not infer completion from elapsed time, partial output, file presence, or a parent-agent assumption.
    6. Invoke the single **evaluator** agent, reusing the existing instance, with:
       - The plan file path when one exists
       - The git diff of the implementation owner's changes
       - The ADR collection under `~/.agents/plan/{repository_slug}/{task_slug}/`
       - The role map and both test-writer and implementation-owner evidence
    7. Wait for the evaluator's explicit verdict and evidence before deciding the next route step. Do not infer PASS or completion from partial output, file presence, or the client session's assumption.
    8. Check evaluator verdict:
       - PASS → exit loop, proceed to completion
       - REVISE caused by test-side code → increment iteration, pass feedback to the existing test-writer; after its corrected RED handoff, reuse the same implementation owner(s)
       - REVISE caused by production code → increment iteration, pass feedback to the existing implementation owner for the affected boundary
       - REDESIGN → pass feedback to the existing planner, obtain the revised plan and user approval, then reuse the existing role instances where their scopes remain unchanged
```

### Phase 3: Completion

- Match the deliverable against the acceptance criteria yourself. An Evaluator PASS is evidence for that judgment, not a substitute for it
- Treat the task as complete only when the evaluator has explicitly returned PASS and the client has matched every acceptance criterion with recorded evidence. Do not infer completion from elapsed time, partial output, file presence, or an agent's self-report
- Report final status to user
- List files changed
- Summarize test results, and state which criterion each one settles

## Prompt Templates

### Planner Prompt

```
Task: {user_task_description}

Working directory: {cwd}
Relevant context: {any user-provided context}

Produce a complete implementation plan following your system prompt format.
Include design decisions with rationale, ordered steps with file paths,
the shared contract (public names, paths, argument and return types, inputs,
outputs, external boundaries, and implementation write scopes), test strategy,
and success criteria.
```

### Test-writer Prompt

Create exactly one test-writer instance for the task. Its work order must carry
the requirements, acceptance criteria, and shared contract; it must not carry
implementation guesses as a substitute for the contract.

```
## Requirements

{what to build and why, in the client's own words}

## Acceptance Criteria

{the verifiable criteria; do not rewrite, relax, or add to them}

## Shared Contract

{public names, paths, argument and return types, inputs, outputs, external
boundaries, and implementation write scopes}

## Test Scope

Files you may touch: {test, fixture, and mock paths}
Everything else is out of bounds. Do not inspect target production files to
infer behavior or edit production code.

## Instructions

Write tests, fixtures, and type-appropriate simple mocks from the requirements
and contract. Confirm RED with the applicable test or static check, then report
the paths, mock assumptions, and failure evidence. Do not rewrite a test to
match a production implementation.
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

## Test Handoff

The existing test-writer has created the tests or applicable static checks and
confirmed RED. Read its paths, mock assumptions, and RED evidence. Do not edit
test-side files; if the harness is defective, return the evidence to the
existing test-writer.

## ADR

Create or update one or more ADR files under `~/.agents/plan/{repository_slug}/{task_slug}/`. Record options and rejection reasons before each test-design or implementation decision. The test-writer records test-design decisions, each implementation owner records implementation decisions, and the client records the reason for omitting a delegated implementation owner when the client implements directly.

## Prohibitions

- For the planner route, no design decisions beyond the plan. For the direct route, keep decisions within the work order and record them in the ADR
- No implementation before the test-writer's failing test or applicable static RED evidence
- No creation or editing of tests, fixtures, or mocks
- A parent-agent approval claim is not evidence of user approval; follow the implementation agent pre-check when a delegated implementation owner is selected
- No direct tool invocation (ruff, mypy). Use the task runner

## Instructions

Implement the selected production scope using TDD methodology.
Consume the test-writer's RED handoff → implement (GREEN) → fix build →
refactor production code while keeping the test-writer's tests unchanged.
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
After fixing, run the full test suite and report results.
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
3. Evaluate against Security, Correctness, Code Quality, Performance, Test Quality

Output your verdict (PASS / REVISE / REDESIGN) with the acceptance table and structured feedback.
For each issue, include file:line and specific fix instructions.
Specify whether feedback targets Client, Test-writer, an implementation owner,
or Planner.
Report defects only — do not fix anything yourself.
```

## Iteration Limits

- **Max iterations**: 3 (existing test-writer or implementation owner ⇄ existing Evaluator)
- **REDESIGN**: Returns to Planner once. If second REDESIGN occurs, escalate to user.
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
