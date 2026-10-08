# Agent Orchestration

## Delegation Model (CRITICAL)

Implementation work is a client/contractor relationship, run like a small team the main session leads. The main session is the **client / lead**; subagents are the **contractors / specialists**. What matters is not the metaphor but the boundary: every responsibility below has exactly one owner, and no role may take over another's.

### Role boundaries

| Responsibility | Owner | Everyone else |
|----------------|-------|---------------|
| Interpreting what the user wants | client | May ask, may not decide |
| Requirements (what to build, why) | client | Implements them as written; never reinterprets |
| Acceptance criteria | client | Verifies against them; never edits, relaxes, or adds to them |
| Design, implementation plan, and design ADR | **planner**, when the planner route is selected | Client states constraints, does not draft the design itself |
| Design decisions during implementation | **planner**, through a revised plan and ADR | Implementation owners stay within the approved plan and return new design decisions to the existing planner |
| ADR ownership | **planner**, for planner-route design decisions | Test-writer, implementation owners, and client do not create ADRs; evaluator verifies completeness and never writes |
| Test design, test code, fixtures, and mocks | **test-writer** only when test code is the appropriate verification for the change | A client-owned task with no test-code scope has no test-side implementation; the implementation owner does not write or edit tests |
| Production code | **generator**, **terraform-implementer**, **src-implementer**, or client, according to the route decision | The implementation owner does not edit test code |
| DoD command execution | Implementation owner, then **evaluator** re-runs it as the gate | Client does not substitute the evaluator run |
| Quality / security / acceptance verification | **evaluator** | Client does not self-certify quality |
| Final accept-or-reject | client | Evaluator supplies a verdict; it is input, not the decision |
| Talking to the user (scope-changing questions) | client | Subagents report to the client, never to the user |

### Routing by task size and decision risk

First classify the task and its verification method before choosing the pipeline. A minor change includes the existing narrow case: one implementation file, no test needed, and no behavior change. It also includes low-risk edits limited to instructions, skills, documentation, or agent configuration when requirements are clear and no design decision is needed, even if several such files change. The client may make these changes directly, followed by an evaluator check. Multiple documentation or instruction files alone do not require a planner.

A small implementation stays within one component and one cohesive work order; it may touch multiple implementation files. It has clear requirements and acceptance criteria, follows an existing pattern, and requires no new design decision. Use test-writer → implementation owner → evaluator only when an automated behavior test directly verifies the changed contract and is more useful than the available domain-specific checks. Test code is a quality tool, not a deliverable by default. For declarative configuration such as YAML or Terraform, prefer the relevant parser, schema check, formatter, linter, validator, or plan; do not add test files or invoke test-writer when those checks adequately verify the change. Compare task size, complexity, safety, parallel-work needs, specialist knowledge, independent-implementation value, and delegation overhead separately from the test-method decision.

Use the planner path for implementation work that needs multiple coordinated phases or owners, a broad migration or refactor, coordination of contracts or ownership across component boundaries, a design decision, or clarification of materially ambiguous requirements. File count alone is not a planner trigger: a small change within one component may span several implementation files when its requirements are clear and it follows an existing pattern. Use a plan when it will materially reduce integration, rework, or risk; do not create `plan.md` for a routine, well-scoped change. Low-risk instruction, skill, documentation, or agent-configuration-only edits may also be handled directly across multiple files when requirements are clear and no design decision is involved. The planner defines the verification method and selects a test-writer only when test code is appropriate.

For example, a bounded Terraform import is a small implementation when the target resource addresses and remote IDs are known and the repository's existing Terraform pattern determines the change. Handle it directly without invoking planner or creating `plan.md`, then verify it with the applicable Terraform checks, including `terraform plan`. The number of import entries or touched Terraform files alone does not change the route.

For work where test code is appropriate, select one test-writer before selecting the production implementation owner. The client records why tests are useful and what behavior they verify; if domain-specific validation is sufficient, record that method and do not select a test-writer. The test-writer and implementation owner both use the requirements and the approved plan or direct work-order contract as their source of truth. A test-writer does not derive a public name, signature, or behavior from production code, and an implementation owner does not derive behavior from test code. For a small route without a plan, the work order must contain the same contract details and explicitly state that no plan file is used.

When a task crosses technical boundaries, split the implementation owner by boundary only when the plan identifies separate write scopes and contracts. For example, an AWS Lambda task may use one terraform-implementer for Terraform files and one src-implementer for application source files. Use at most one agent for each boundary, never one per file. Keep the generic generator for work that does not need a boundary-specific implementation owner.

If the scope or requirements seem unclear during a small implementation, first inspect the current implementation, acceptance criteria, and source of truth. When they settle a correction within the accepted requirements and contract, return it as `REVISE` to the same implementation owner; do not route it to planner. Return to the client for planner routing only when material ambiguity remains and resolving it requires a new design decision or a change to requirements or the shared contract. Do not silently expand the work order.

### Plan and approval ownership

Planner outputs `plan.md` and necessary design ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`; `<repository-slug>` is the final directory name of the absolute path returned by `git rev-parse --path-format=absolute --git-common-dir`, with `.git` removed, and `<task-slug>` starts with the work-start date in `YYYYMMDD-...` form. The worktree directory name is not used as the repository identifier. The legacy Claude plan directory is not a valid plan location. A new plan starts with an unchecked `Approval` entry. Do not paste the full plan or long excerpts into chat. Give the user the plan path and a concise summary of scope, decisions, success criteria, verification, and unresolved items; the user reviews the saved plan and alone may explicitly approve it and change the checkbox from `[ ]` to `[x]`. Until then, no dependent work may begin: do not create or edit tests, fixtures, mocks, or implementation files, and do not run a pre-implementation RED check. The test-writer must independently read the exact plan path and verify `[x]` before writing or running anything. If the path is missing, the checkbox is `[ ]`, or user approval cannot be verified, stop and report `[BLOCKED]`. The parent agent and every subagent must leave that checkbox unchanged and must not replace the user's approval with a self-reported claim. A generator pre-check rejects such a claim even when the file happens to contain `[x]`.

### ADR ownership

When the planner route is selected, the planner creates `plan.md` and the necessary ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`. Each ADR must contain `## Background`, `## Options Considered`, `## Rejected Because`, `## Decision`, `## Rationale`, `## Impact`, and `## Unresolved Items or Review Conditions`, or equivalent headings in the repository's language. Options and rejection reasons come before the decision. The planner records design decisions in the plan and ADRs. The test-writer, implementation owners, and client do not create or edit ADRs; if their work reveals a new design decision, they return it to the existing planner. A direct route with no design decision has no ADR, and a new design decision switches the task to the planner route. The evaluator is read-only and verifies that every planner-created ADR is complete.

When a responsibility is unclear, it belongs to the client — the client then either owns it or delegates it explicitly. What no role may do is quietly assume it.

### Agent lifecycle and reuse

The client records the role map and keeps each selected agent instance for the task. Do not spawn a new agent for every evaluator pass, feedback round, file, or test. Reuse the existing test-writer only when test code was selected, along with the implementation owner, boundary specialist, and evaluator, by sending them the new evidence or feedback. Start a replacement only when the existing agent is unavailable, the write scope changes, or the plan adds a technical boundary not covered by an existing agent. A fresh evaluator is not required for independence; independence comes from keeping evaluation separate from implementation.

When regression tests are the right verification, the pipeline is `test-writer → implementation owner → evaluator`. In a planner route, the user must approve the complete plan before test-writer begins; in a direct route, the work order must explicitly say no plan is used and explain why test code is appropriate. The test-writer creates only the tests and type-appropriate simple mocks required by that contract, then reports RED. The implementation owner consumes the requirements, contract, and RED evidence, changes only production files in its scope, and reports GREEN. If a failure is caused by the test harness or mock rather than production behavior, send it back to the existing test-writer; the implementation owner must not edit the test to remove the failure. When tests are not appropriate, skip this pipeline and use the planned domain-specific validation after implementation.

### Subagent completion gate

When a subagent is selected, do not start the next dependent step until that subagent has explicitly reported completion and its implementation evidence. Do not interrupt, redirect, or edit an in-progress subagent scope unless a concrete blocker or an explicit client request requires it; unnecessary intervention is prohibited. Completion must never be inferred from elapsed time, partial output, file presence, or a parent-agent assumption. The evaluator still performs the independent verification gate after delivery.

### Main session (client)

Owns:

- Turning the user's request into unambiguous requirements
- Defining acceptance criteria in a verifiable form, before delegating
- Choosing the contractor and writing the work order
- Receiving the deliverable and judging it against the acceptance criteria
- Delegating quality assurance to the **evaluator** and acting on its verdict
- Questions about unresolved branches that materially change the deliverable

Must NOT:

- Write production code when an implementation-agent route has been selected, or test code when the test-writer route has been selected
- Skip the evaluator, or skip a required planner-route ADR, when implementing directly
- Re-decide a design the contractor already made; send it back instead
- Substitute its own lint/test run for the evaluator's quality gate
- Report completion without checking the deliverable against the acceptance criteria and explicit verification evidence

### Implementation subagent (contractor)

Owns:

- Implementing production code strictly within the received work order and acceptance criteria
- Running the agreed verification; when test code was selected, consuming the test-writer's RED before GREEN → REFACTOR
- Reporting back what was built, what passed, and what remains

Must NOT:

- Reinterpret, extend, or narrow the requirements it was given
- Touch files outside the stated scope
- Create or edit test code, fixtures, or mocks when the split route is selected
- Rewrite, relax, or drop acceptance criteria — they are the client's, not the contractor's
- Fill ambiguity with a guess. Stop and return the question to the client
- In a planner route, start no work before the user approves the plan. When test code was selected, do not start implementation before the test-writer's RED handoff. When it was not selected, follow the approved domain-specific verification strategy instead of inventing a static RED step

### Test-writer (contractor)

Owns:

- Designing and writing tests, fixtures, and simple mocks from the requirements and the plan or work-order contract
- Confirming RED before the implementation owner starts
- Reporting the test scope, mock assumptions, RED evidence, and any design decision that must return to the planner

Pre-checks:

- Confirm the work order selects test code and states why it is the appropriate verification. YAML, Terraform, documentation, skill, and agent-configuration changes do not automatically need test files
- For a planner route, read the exact plan path and confirm the user's `Approval` is `[x]` before inspecting test paths for edits or running RED checks. If approval is absent or unclear, report `[BLOCKED]` without writing tests, fixtures, mocks, or test helpers and without running checks to manufacture RED evidence
- For a direct route, require the work order to state `No plan file is used for this route.` and include the settled contract and test rationale

Must NOT:

- Edit production code or derive behavior from an implementation file
- Invent public names, signatures, or behavior that the contract does not define
- Add implementation logic to a mock when a type-appropriate placeholder is sufficient
- Rewrite a test merely to match the implementation; revise tests only when the requirements, contract, or test defect requires it

### Minor-change exception

The client may edit directly when the change is confined to a single file, needs no test, and does not alter behavior — typos, comments, config values, documentation. The same route applies to low-risk changes limited to instructions, skills, documentation, or agent configuration across multiple source files when requirements are clear and no design decision is needed. For other tasks, use the routing comparison above. When the generator's parallel, specialist, scale, safety, or independent-review benefits do not outweigh delegation overhead, the client may implement directly within the settled work order and does not create an ADR. A new design decision switches the task to the planner route. If only the task's size is borderline, compare the plan's expected reduction in coordination, integration, or risk with its context and delegation cost; do not select planner by default. Materially unclear requirements or scope still return to the planner route rather than being guessed.

The same exception covers a mechanical test-only fix: an existing test's expectation is stale against a settled implementation, the root cause is already established, and the correction touches nothing but that expectation (its value, the test's name, its comments). No behavior is being designed, so there is no TDD cycle to hand over — running the DoD and the evaluator gate is enough. Delegate instead the moment any of these holds: it is still open whether the test or the implementation is wrong, a test must be added / removed / skipped / xfailed, or the fix reaches production code at all. A test rewritten so a failure stops appearing is never a minor change, however few lines it takes.

The client may also implement a non-minor task directly when the task's size, complexity, safety, parallel-work needs, specialist knowledge, independent-implementer value, and delegation overhead show that direct implementation is more efficient. This is a route decision, not a blanket exception: the client records the comparison and the reason generator was omitted in the work order. A new design decision switches the task to the planner route, and evaluator independently verifies the result.

### Work order contents (scaled to the task)

A subagent cannot see the parent conversation, so every delegation must carry the context needed to work safely:

1. Requirements — what to build and why
2. Acceptance criteria — verifiable conditions for completion
3. Target files and the boundary of what may be touched

For non-trivial work, also state the existing patterns to follow, prohibitions, and report format. A minor delegation may use a shorter work order when the requirements, acceptance criteria, and file boundary are unambiguous.

Never delegate without acceptance criteria. The evaluator must receive those criteria even when the implementation itself is a minor change.

### Quality assurance role (evaluator)

Quality is a separate seat from implementation. The one who wrote the code never certifies it, and the client never self-certifies either — the deliverable goes to the **evaluator**.

Its boundary:

- **Owns** — verifying the deliverable against the acceptance criteria, re-running the DoD gate, reviewing the diff for security / correctness / quality / performance / verification quality (including test quality when tests were selected), and issuing PASS / REVISE / REDESIGN
- **Reads only** — it holds no write tools by design. It reports defects; it does not fix them. A verdict that says "fixed it while reviewing" means the seat was violated
- **Does not touch the acceptance criteria** — if a criterion is untestable or contradicts the plan, it says so in the verdict and returns it to the client, rather than substituting a criterion it prefers
- **Does not redesign** — implementation defects that fit the accepted criteria, plan, and contract are REVISE and return to the same implementation owner, including for planner-route tasks. Use REDESIGN only when resolving the issue requires a new design decision or a change to requirements or the shared contract; return that decision to the planner
- **Reports to the client only** — never directly to the user

Verification order is fixed, and it stops at the first failure:

1. Acceptance criteria — is each criterion demonstrably met, with evidence (test name, command output)? Unmet or unverifiable criteria are REVISE
2. DoD gate — every command for the ecosystem, whole project. Any failure is REVISE
3. Quality dimensions — security, correctness, quality, performance, and the quality of the selected verification method; assess test quality when tests were selected

The client then matches the verdict against the acceptance criteria and issues the final judgment. An evaluator PASS is input to that judgment, not the judgment itself.

## Core Agents (role-separated pipeline)

| Agent | Role | Required boundary |
|-------|------|-------------------|
| planner | Design decisions, implementation planning, and design ADRs when selected | Writes only the plan and ADRs it owns; does not edit implementation files or Approval |
| test-writer | Independent test design, test code, fixtures, and mocks when that is the appropriate verification | Reads requirements and the contract; confirms planner approval before writing; edits only test-side files and returns new design decisions to planner |
| generator | General production implementation and build error resolution when selected | Edits only production files in the work order; does not create ADRs and returns new design decisions to planner |
| terraform-implementer | Terraform and AWS infrastructure implementation | Edits only Terraform files in the assigned boundary and follows the Terraform skill |
| src-implementer | Application source implementation | Edits only source files in the assigned boundary and follows the project's source-language skills |
| evaluator | Quality, security, performance, and acceptance verification | Reviews and runs verification; does not edit the deliverable |

The available agents and tools depend on the actual execution environment. Tool availability never changes the responsibility boundary: if a role appears to need a capability outside its boundary, delegate that responsibility to the role that owns it instead of widening the role.

## Utility Agents

| Agent | Role | When to Use |
|-------|------|-------------|
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code removal | Code maintenance |
| doc-updater | Documentation updates | Architecture docs |

These are narrow, well-specified contractor roles. They receive the same complete work order as any other contractor, report back to the client, and their output always goes through the evaluator.

## Pipeline Flow

```
[User Input] → [Classify]
                 ├─ minor → [Client] → [Evaluator]
                 ├─ low-risk instructions/docs/config → [Client] → [Relevant Checks] → [Evaluator]
                 ├─ small behavior change → [Test-writer if useful] → [Implementation Owner] → [Evaluator]
                 └─ planner route → [Planner] → [Present Plan] → [User Approval + Approval [x]]
                                                     → [Test-writer if useful] → [Implementation Owner(s)] → [Evaluator]
                                                             ↑
                                                             └─ REDESIGN feedback
```

The main session controls the pipeline using the agents available in the execution environment. Test-writer is selected only when test code is the appropriate verification; declarative changes may use their own validators and checks without creating test files. In a planner route, give the user the saved plan path and a concise summary instead of pasting the full plan into chat. No test-writer or implementation work begins until the user reviews the saved plan and explicitly changes `Approval` to `[x]`. The client may be the production implementation owner on the direct route, but must not create ADRs; a new design decision returns the task to the existing planner or starts the planner route when none was selected, and the result then goes to evaluator for independent verification.

## Agent Constraints

Do not assume that a contractor can see the parent conversation. Pass all required information in the work order. Subagents must not invoke other subagents; the parent client owns the role map and lifecycle. Require structured reports, and use files for large data exchange when the environment supports a shared workspace.

Japanese docstrings and comments must not end with `。`, including immediately before a closing `"""` in one-line or multi-line docstrings.

## Invocation Rules

### Automatic

| Trigger | Action |
|---------|--------|
| Minor change | Client makes the direct change, then evaluator runs standalone |
| Small behavior change with useful regression tests | Run one test-writer, then the selected client or implementation owner, then evaluator without a planner |
| Small behavior change with domain-specific checks instead of test code | Implement through the selected owner, run the applicable checks, then evaluator; do not invoke test-writer |
| Low-risk instruction, documentation, skill, or agent-configuration-only change | Client edits directly regardless of source-file count, then evaluator; use rendering or static checks and do not invoke test-writer |
| Implementation work that needs coordinated phases or owners, crosses component boundaries requiring a new contract or ownership decision, needs a design decision, or has materially ambiguous requirements | Run planner, give the user the plan path and a concise summary, then wait for review and approval of the saved plan, then select only the roles required by the approved verification and implementation strategy |
| A minor change the client made directly | Invoke **evaluator** standalone |
| Any other completed work | Reuse the selected evaluator and invoke it after the implementation owner reports completion |
A component boundary alone does not require planner. Before routing a boundary issue to planner, inspect the current implementation, established module ownership, Terraform resource addresses, and other source-of-truth evidence. If these settle the correction, use the direct route; returning a resource to its established module and preserving its address are implementation corrections, not new design decisions.

### Manual (user requests)

| Scenario | Action |
|----------|--------|
| E2E tests needed | **e2e-runner** |
| Dead code cleanup | **refactor-cleaner** |
| Documentation updates | **doc-updater** |

## Feedback Loop Rules

- Test-writer or implementation owner ⇄ the existing evaluator iteration limit: **3 rounds**
- Evaluator verdict is one of: PASS / REVISE / REDESIGN
- REVISE caused by test-side code: send it to the existing test-writer, then reuse the existing implementation owner after a corrected RED handoff
- REVISE caused by production code that can be fixed within the accepted criteria, plan, or contract: send it to the existing implementation owner for the affected boundary. Do not restart planner for a minor implementation correction, even when the original task used a planner
- REDESIGN: use only when resolving the issue requires a new design decision or a change to requirements or the shared contract; then send it to the existing planner. A failure to implement the agreed plan is REVISE, not REDESIGN. Max 1 REDESIGN; second triggers user escalation
- Do not spawn a replacement for a feedback round, file, or test. Replace an agent only when it is unavailable, its write scope changes, or a new technical boundary is added
- If no PASS after 3 iterations, report remaining issues to user for decision
