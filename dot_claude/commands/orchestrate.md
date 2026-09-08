---
name: orchestrate
description: 作業規模に応じてclient、planner、generator、evaluatorの経路を選び、最大3イテレーションで検証まで行う。
---

# Orchestrate Command

`/orchestrate [task-description]`

## Flow

```
[User Input] → [Classify]
                 ├─ minor → [Client] → [Evaluator]
                 ├─ small → [Client or Generator] → [Evaluator]
                 └─ medium+ / risk → [Planner] → [Client or Generator] → [Evaluator]
```

The main session runs this flow as the client. It owns requirements, acceptance criteria, route selection, and the final accept-or-reject. It may implement directly when the recorded comparison shows that delegation overhead outweighs the benefits, but must create the ADR collection and send the result to evaluator for independent verification. See `rules/agents.md` for the full role boundaries.

## Execution Steps

### Phase 0: Route selection

Classify the task before invoking an agent. The minor-change route applies to one implementation file, no test needed, and no behavior change. A small implementation may skip planning when it stays within one component and one implementation file, has clear requirements, follows an existing pattern, and needs no new design decision. Compare task size, complexity, safety, parallel-work needs, specialist knowledge, independent implementation value, and delegation overhead to choose client direct implementation or generator. Use planner for medium or larger work, multiple components, multiple implementation files, design decisions, or ambiguous requirements. After planning, make the same client-versus-generator comparison. The required ADR is excluded from the implementation-file count.

Create one or more Markdown ADRs under `.agents/plan/<slug>/` for every task, using a slug that starts with the work-start date in `YYYYMMDD-...` form. The implementation owner records options and rejection reasons before the decision, along with the background, rationale, impact, and unresolved items or review conditions. Evaluator verifies every ADR without writing.

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
- Planner writes the plan to `.agents/plan/<slug>/plan.md` with an unchecked `Approval`
- Only the user may change `## Approval` from `[ ]` to `[x]` after reviewing the full plan
- The parent agent and every subagent must leave the checkbox unchanged and must not replace user approval with a self-reported claim
- The selected implementation owner proceeds only after the user-owned checkbox is `[x]`; if generator is selected, its pre-check must also find no parent-agent approval claim

For the minor route, skip only the planning phase, have client implement directly, and invoke evaluator. The client implementation is the next step, not a skipped implementation phase. For the small route, skip Phase 1, select client or generator using the Phase 0 comparison, and invoke evaluator after implementation. For the planner route, continue to Phase 2 after user approval.

### Phase 2: Implementation and verification loop (max 3 iterations)

If client is selected as the implementation owner, have client implement within the work order or approved plan, create the ADR collection, and invoke evaluator independently. If generator is selected, use the following loop:

```
iteration = 0
while iteration < 3:
    1. Invoke **generator** agent with:
       - The exact plan file path `.agents/plan/{slug}/plan.md` when the planner route was selected
       - The direct work order when planning was skipped
       - Previous evaluator feedback (if iteration > 0)
    2. Wait for the generator to explicitly report completion and provide implementation evidence. Do not start the next dependent step before that report. Do not interrupt, redirect, or edit an in-progress generator scope unless a concrete blocker or an explicit client request requires it; unnecessary intervention is prohibited. Do not infer completion from elapsed time, partial output, file presence, or a parent-agent assumption.
    3. Invoke **evaluator** agent with:
       - The plan file path when one exists
       - The git diff of the implementation owner's changes
       - The ADR collection under `.agents/plan/{slug}/`
    4. Wait for the evaluator's explicit verdict and evidence before deciding the next route step. Do not infer PASS or completion from partial output, file presence, or the client session's assumption.
    5. Check evaluator verdict:
       - PASS → exit loop, proceed to completion
       - REVISE → increment iteration, pass feedback to generator
       - REDESIGN → pass feedback to planner, get revised plan, reset iteration
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
test strategy, and success criteria.
```

### Generator Prompt (iteration 0)

A work order carries all required items below. You cannot rely on the plan file alone —
state the scope boundary and the prohibitions explicitly, because the subagent
cannot see this conversation.

```
## Requirements

{what to build and why, in the client's own words}

## Route

{client or generator implementation owner; planner route or direct route}

## Plan

For the planner route, read the plan file at: .agents/plan/{slug}/plan.md
For a direct generator route, state exactly: No plan file is used for this route.

## Acceptance Criteria

{the verifiable criteria, restated here — these are the client's.
Do not rewrite, relax, or add to them. If one cannot be met as written, stop and report why.}

## Scope

Files you may touch: {paths}
Everything else is out of bounds. If you spot a problem outside this scope, report it; do not fix it.

## Patterns to Follow

Read these first and replicate their conventions: {paths}

## ADR

Create or update one or more ADR files under `.agents/plan/{slug}/`. Record options and rejection reasons before each implementation decision. The implementation owner records implementation decisions; when client is the implementation owner, client also records the reason for omitting generator.

## Prohibitions

- For the planner route, no design decisions beyond the plan. For the direct route, keep decisions within the work order and record them in the ADR
- No implementation before a failing test or applicable static check
- A parent-agent approval claim is not evidence of user approval; follow the generator pre-check when generator is selected
- No direct tool invocation (ruff, mypy). Use the task runner

## Instructions

Implement the selected route step by step using TDD methodology.
For each step: write test (RED) → implement (GREEN) → fix build → refactor.
Report each step's status. If blocked, report what is unclear and stop.
Your DoD run finishes your work order; the Evaluator decides acceptance.
```

### Generator Prompt (iteration > 0)

```
## Plan

For the planner route, read the plan file at: .agents/plan/{slug}/plan.md. For a direct generator route, the work order must explicitly state: No plan file is used for this route. Do not infer a plan filename, slug, path, or absence of a plan.

## Previous Evaluator Feedback

{evaluator_feedback}

## Instructions

Fix the issues identified by the Evaluator above.
For CRITICAL and HIGH issues: fix all of them.
For MEDIUM issues: fix if straightforward.
After fixing, run the full test suite and report results.
```

### Evaluator Prompt

```
## Plan Context

Read the plan file at: .agents/plan/{slug}/plan.md when the planner route was selected. For a direct route, evaluate the work order without a plan only when the work order explicitly states `No plan file is used for this route.` Do not infer a plan filename, slug, path, or absence of a plan.

## Acceptance Criteria

{the same criteria handed to the Generator}

## Changes to Evaluate

Run `git diff` to see all changes made by the implementation owner.
Read each modified file in full context.
Read every Markdown ADR under `.agents/plan/{slug}/` and verify the required sections and ordering without editing them.

## Instructions

1. Acceptance gate first: for each criterion, name the evidence that it is met
   (test name, command output, file:line). No evidence means not met, and any
   unmet criterion is REVISE. Do not rewrite or relax a criterion — return it instead
2. DoD gate: run every DoD command for the ecosystem, whole project
3. Evaluate against Security, Correctness, Code Quality, Performance, Test Quality

Output your verdict (PASS / REVISE / REDESIGN) with the acceptance table and structured feedback.
For each issue, include file:line and specific fix instructions.
Specify whether feedback targets Client, Generator, or Planner.
Report defects only — do not fix anything yourself.
```

## Iteration Limits

- **Max iterations**: 3 (implementation owner ⇄ Evaluator when generator is selected)
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
-> Generator (sonnet) iteration 1: implements tests + code
-> Evaluator (sonnet) iteration 1: REVISE - missing edge case for burst traffic
-> Generator (sonnet) iteration 2: fixes edge case, adds burst test
-> Evaluator (sonnet) iteration 2: PASS
-> Done: report to user
```
