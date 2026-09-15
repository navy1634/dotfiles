# Agent Orchestration

## Delegation Model (CRITICAL)

Implementation work is a client/contractor relationship, run like a small team the main session leads. The main session is the **client / lead**; subagents are the **contractors / specialists**. What matters is not the metaphor but the boundary: every responsibility below has exactly one owner, and no role may take over another's.

### Role boundaries

| Responsibility | Owner | Everyone else |
|----------------|-------|---------------|
| Interpreting what the user wants | client | May ask, may not decide |
| Requirements (what to build, why) | client | Implements them as written; never reinterprets |
| Acceptance criteria | client | Verifies against them; never edits, relaxes, or adds to them |
| Design and implementation plan | **planner**, when the planner route is selected | Client states constraints, does not draft the design itself |
| Design decisions during implementation | Implementation owner, within the approved plan or small-task work order | Generator or client records the decision in the ADR; escalate to planner when the work exceeds the selected route |
| Implementation ADR | Test-writer and implementation owner for their respective decisions | Planner records design decisions in the plan; evaluator verifies completeness and never writes |
| Test design, test code, fixtures, and mocks | **test-writer** for behavior changes | A client-owned minor change has no test-side implementation; the implementation owner does not write or edit tests |
| Production code | **generator**, **terraform-implementer**, **src-implementer**, or client, according to the route decision | The implementation owner does not edit test code |
| DoD command execution | Implementation owner, then **evaluator** re-runs it as the gate | Client does not substitute the evaluator run |
| Quality / security / acceptance verification | **evaluator** | Client does not self-certify quality |
| Final accept-or-reject | client | Evaluator supplies a verdict; it is input, not the decision |
| Talking to the user (scope-changing questions) | client | Subagents report to the client, never to the user |

### Routing by task size and decision risk

First classify the task before choosing the pipeline. A minor change is the existing narrow definition: one implementation file, no test needed, and no behavior change. The client may make that change directly, followed by a standalone evaluator check.

A small implementation is larger than a minor change only in behavior, not in design scope. It stays within one component and one implementation file, has clear requirements and acceptance criteria, follows an existing pattern, and requires no new design decision. Compare the task's size, complexity, safety, need for parallel work, specialist knowledge, value of an independent implementer, and delegation overhead when choosing the implementation owner; the behavior-change pipeline remains test-writer → implementation owner → evaluator even when the client owns production implementation.

Use the planner → test-writer → client or implementation owner(s) → evaluator path for medium or larger work, any work spanning multiple components or multiple implementation files, work requiring a design decision, or work with ambiguous requirements. Multiple implementation files trigger the planner regardless of the apparent size. The required ADR is a workflow record and is excluded from this file-count decision.

For all behavior-changing work, select one test-writer before selecting the production implementation owner. The test-writer and implementation owner both use the requirements and the plan or work-order contract as their source of truth. A test-writer does not derive a public name, signature, or behavior from production code, and an implementation owner does not derive behavior from test code. For a small route without a plan, the work order must contain the same contract details.

When a task crosses technical boundaries, split the implementation owner by boundary only when the plan identifies separate write scopes and contracts. For example, an AWS Lambda task may use one terraform-implementer for Terraform files and one src-implementer for application source files. Use at most one agent for each boundary, never one per file. Keep the generic generator for work that does not need a boundary-specific implementation owner.

If the scope or requirements become unclear during a small implementation, stop the small path and return to the client for planner routing. Do not silently expand the work order.

### Plan and approval ownership

Planner output is written only to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md`; `<repository-slug>` is the final directory name of the absolute path returned by `git rev-parse --path-format=absolute --git-common-dir`, with `.git` removed, and `<task-slug>` starts with the work-start date in `YYYYMMDD-...` form. The worktree directory name is not used as the repository identifier. The legacy Claude plan directory is not a valid plan location. A new plan starts with an unchecked `Approval` entry. The full plan must be shown to the user, and only the user may explicitly approve it and change the checkbox from `[ ]` to `[x]`. The parent agent and every subagent must leave that checkbox unchanged and must not replace the user's approval with a self-reported claim. A generator pre-check rejects such a claim even when the file happens to contain `[x]`.

### ADR ownership

Every task has multiple implementation ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`. The test-writer and implementation owner create separate ADRs for their decisions, whether the owner is a boundary specialist or the client. Each ADR must contain `## Background`, `## Options Considered`, `## Rejected Because`, `## Decision`, `## Rationale`, `## Impact`, and `## Unresolved Items or Review Conditions`, or equivalent headings in the repository's language. Options and rejection reasons come before the decision. The planner's design decisions belong in `plan.md`, while the test-writer's, implementation owner's, or client's decisions and the reason for omitting delegation belong in the ADR collection. The evaluator is read-only and verifies that every ADR is complete.

When a responsibility is unclear, it belongs to the client — the client then either owns it or delegates it explicitly. What no role may do is quietly assume it.

### Agent lifecycle and reuse

The client records the role map and keeps each selected agent instance for the task. Do not spawn a new agent for every evaluator pass, feedback round, file, or test. Reuse the existing test-writer, implementation owner, boundary specialist, and evaluator by sending them the new evidence or feedback. Start a replacement only when the existing agent is unavailable, the write scope changes, or the plan adds a technical boundary not covered by an existing agent. A fresh evaluator is not required for independence; independence comes from keeping evaluation separate from implementation.

The default behavior-change pipeline is `test-writer → implementation owner → evaluator`. The test-writer creates the tests and type-appropriate simple mocks, then reports RED. The implementation owner consumes the requirements, contract, and RED evidence, changes only production files in its scope, and reports GREEN. If a failure is caused by the test harness or mock rather than production behavior, send it back to the existing test-writer; the implementation owner must not edit the test to remove the failure.

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
- Skip the ADR or evaluator when implementing directly
- Re-decide a design the contractor already made; send it back instead
- Substitute its own lint/test run for the evaluator's quality gate
- Report completion without checking the deliverable against the acceptance criteria and explicit verification evidence

### Implementation subagent (contractor)

Owns:

- Implementing production code strictly within the received work order and acceptance criteria
- Running the GREEN → REFACTOR part of the TDD cycle after the test-writer has reported RED
- Reporting back what was built, what passed, and what remains

Must NOT:

- Reinterpret, extend, or narrow the requirements it was given
- Touch files outside the stated scope
- Create or edit test code, fixtures, or mocks when the split route is selected
- Rewrite, relax, or drop acceptance criteria — they are the client's, not the contractor's
- Fill ambiguity with a guess. Stop and return the question to the client
- Start implementation without the test-writer's failing test or applicable static RED evidence

### Test-writer (contractor)

Owns:

- Designing and writing tests, fixtures, and simple mocks from the requirements and the plan or work-order contract
- Confirming RED before the implementation owner starts
- Recording test-design decisions in the ADR collection and reporting the test scope, mock assumptions, and RED evidence

Must NOT:

- Edit production code or derive behavior from an implementation file
- Invent public names, signatures, or behavior that the contract does not define
- Add implementation logic to a mock when a type-appropriate placeholder is sufficient
- Rewrite a test merely to match the implementation; revise tests only when the requirements, contract, or test defect requires it

### Minor-change exception

The client may edit directly when the change is confined to a single file, needs no test, and does not alter behavior — typos, comments, config values, documentation. For other tasks, use the routing comparison above. When the generator's parallel, specialist, scale, safety, or independent-review benefits do not outweigh delegation overhead, the client may implement directly and must record that choice in the ADR. When it is unclear which side of the line a change falls on, use planner or ask the client to resolve the scope rather than guessing.

The same exception covers a mechanical test-only fix: an existing test's expectation is stale against a settled implementation, the root cause is already established, and the correction touches nothing but that expectation (its value, the test's name, its comments). No behavior is being designed, so there is no TDD cycle to hand over — running the DoD and the evaluator gate is enough. Delegate instead the moment any of these holds: it is still open whether the test or the implementation is wrong, a test must be added / removed / skipped / xfailed, or the fix reaches production code at all. A test rewritten so a failure stops appearing is never a minor change, however few lines it takes.

The client may also implement a non-minor task directly when the task's size, complexity, safety, parallel-work needs, specialist knowledge, independent-implementer value, and delegation overhead show that direct implementation is more efficient. This is a route decision, not a blanket exception: the client records the comparison, the reason generator was omitted, and the implementation decisions in the ADR, and evaluator independently verifies the result.

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

- **Owns** — verifying the deliverable against the acceptance criteria, re-running the DoD gate, reviewing the diff for security / correctness / quality / performance / test quality, and issuing PASS / REVISE / REDESIGN
- **Reads only** — it holds no write tools by design. It reports defects; it does not fix them. A verdict that says "fixed it while reviewing" means the seat was violated
- **Does not touch the acceptance criteria** — if a criterion is untestable or contradicts the plan, it says so in the verdict and returns it to the client, rather than substituting a criterion it prefers
- **Does not redesign** — design objections go back as REDESIGN, addressed to the planner
- **Reports to the client only** — never directly to the user

Verification order is fixed, and it stops at the first failure:

1. Acceptance criteria — is each criterion demonstrably met, with evidence (test name, command output)? Unmet or unverifiable criteria are REVISE
2. DoD gate — every command for the ecosystem, whole project. Any failure is REVISE
3. Quality dimensions — security, correctness, quality, performance, test quality

The client then matches the verdict against the acceptance criteria and issues the final judgment. An evaluator PASS is input to that judgment, not the judgment itself.

## Core Agents (role-separated pipeline)

| Agent | Role | Required boundary |
|-------|------|-------------------|
| planner | Design decisions and implementation planning when selected | Writes only the plan it owns; does not edit implementation files or Approval |
| test-writer | Independent test design, test code, fixtures, and mocks | Reads requirements and the contract; edits only test-side files and creates test-design ADRs |
| generator | General production implementation and build error resolution when selected | Edits only production files in the work order and creates implementation ADRs |
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
                 ├─ behavior change → [Test-writer] → [Implementation Owner] → [Evaluator]
                 └─ medium+ / risk → [Planner] → [Test-writer] → [Implementation Owner(s)] → [Evaluator]
                                                             ↑
                                                             └─ REDESIGN feedback
```

The main session controls the pipeline using the agents available in the execution environment. For behavior changes, test-writer is mandatory even when the client owns production implementation. The client may be the production implementation owner on the direct route, but must still create the ADR collection and hand the result to evaluator for independent verification.

## Agent Constraints

Do not assume that a contractor can see the parent conversation. Pass all required information in the work order. Subagents must not invoke other subagents; the parent client owns the role map and lifecycle. Require structured reports, and use files for large data exchange when the environment supports a shared workspace.

## Invocation Rules

### Automatic

| Trigger | Action |
|---------|--------|
| Minor change | Client makes the direct change, then evaluator runs standalone |
| Small behavior change | Run one test-writer, then the selected client or implementation owner, then evaluator without a planner |
| Small behavior change when direct production implementation is more efficient | Run one test-writer, have client implement production code, then evaluator |
| Medium or larger work, multiple components/files, design decision, or ambiguous requirement | Run planner, one test-writer, and one implementation owner per planned technical boundary, then evaluator |
| A minor change the client made directly | Invoke **evaluator** standalone |
| Any other completed work | Reuse the selected evaluator and invoke it after the implementation owner reports completion |

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
- REVISE caused by production code: send it to the existing implementation owner for the affected boundary
- REDESIGN: send it to the existing planner for design revision. Max 1 REDESIGN; second triggers user escalation
- Do not spawn a replacement for a feedback round, file, or test. Replace an agent only when it is unavailable, its write scope changes, or a new technical boundary is added
- If no PASS after 3 iterations, report remaining issues to user for decision
