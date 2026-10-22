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
| Design decisions during implementation | **planner**, through a revised plan and ADR when authorized | Implementation owners stay within the approved plan and return new decisions to the client, which checks the criteria and permission gate before planner handoff |
| ADR ownership and self-review | **planner**, for planner-route design decisions | Planner checks the plan and ADRs against its work order before reporting completion; evaluator does not own or certify their completeness |
| Test design, test code, fixtures, and mocks | **test-writer** only when test code is the appropriate verification for the change | A client-owned task with no test-code scope has no test-side implementation; the implementation owner does not write or edit tests |
| Production code | **generator**, **terraform-implementer**, **src-implementer**, or client, according to the route decision | The implementation owner does not edit test code |
| DoD selection, execution, and evidence | The owner of each work unit, including planner for plan and ADR work | The owner selects applicable checks from the agreed requirements and project instructions, runs them, and reports results |
| Independent quality assurance | **evaluator**, only after all work owners complete and when separate QA materially reduces quality risk | Assesses the completed deliverable and supplied evidence against agreed criteria; it is not a general reviewer or planner/ADR reviewer and does not own DoD, completion, or approval |
| Final accept-or-reject | client | Uses the owner's evidence and any evaluator findings; evaluator's quality assurance result is not the decision |
| Talking to the user (scope-changing questions) | client | Subagents report to the client, never to the user |

### Routing by task size and decision risk

First classify the task and its verification method before choosing the pipeline. A minor change includes the existing narrow case: one implementation file, no test needed, and no behavior change. It also includes low-risk edits limited to instructions, skills, documentation, or agent configuration when requirements are clear and no design decision is needed, even if several such files change. The client may make these changes directly and run the relevant checks; select an evaluator only for quality assurance of a completed deliverable, after all work owners have completed their DoD, and only when separate QA materially reduces risk. Never use an evaluator to assess a plan or ADR or before implementation is complete. Multiple documentation or instruction files alone do not require a planner.

A small implementation stays within one component and one cohesive work order; it may touch multiple implementation files. It has clear requirements and acceptance criteria, follows an existing pattern, and requires no new design decision. Use test-writer → implementation owner when an automated behavior test directly verifies the changed contract and is more useful than the available domain-specific checks. Test code is a quality tool, not a deliverable by default. The implementation owner selects and runs the DoD for its work order. Add an evaluator only when independent quality assurance of the completed deliverable materially reduces quality risk, after all owners report completion and evidence; never use it to assess plan or ADR quality. For declarative configuration such as YAML or Terraform, prefer the relevant parser, schema check, formatter, linter, validator, or plan; do not add test files or invoke test-writer when those checks adequately verify the change. Compare task size, complexity, safety, parallel-work needs, specialist knowledge, independent-implementation value, and delegation overhead separately from the test-method decision.

Use the planner only as an exception to the direct route. A qualifying trigger must be concrete: dependent phases need to be ordered and integrated; multiple technical boundaries need contract or owner coordination; or multiple material design options remain after checking existing implementation, conventions, and sources of truth, and comparing them will reduce a specific integration, rework, or safety risk. Task size, a feature/refactor/migration label, file or module count, the existence of a design decision, the need for tests, or unresolved user intent alone do not qualify. The client asks the user directly when only the user can resolve an ambiguity. Compare the need for planning separately from whether an implementation owner would help; a coherent task may remain direct even when it spans several files or uses an implementation owner.

Before the first handoff of a task to planner, the client must state the qualifying trigger and evidence, why direct handling is insufficient, the risk planning reduces, and the proposed planning scope, then obtain the user's explicit permission through the available question tool. Wait for a clear affirmative answer before sending the task, partial analysis, or source-inspection work to planner, or creating a plan or ADR. A task request, a request for a plan, or later approval of `plan.md` is not this permission. The permission covers continuation and corrections for the same outcome and scope; a new outcome or material scope change needs fresh permission. This gate is separate from the user's later review and `Approval [x]` for the saved plan. If the user declines, gives an unclear answer, or has not answered, do not invoke planner; continue directly if safe, otherwise report or ask about the specific unresolved requirement.

For example, a bounded Terraform import is a small implementation when the target resource addresses and remote IDs are known and the repository's existing Terraform pattern determines the change. Handle it directly without invoking planner or creating `plan.md`, then verify it with the applicable Terraform checks, including `terraform plan`. The number of import entries or touched Terraform files alone does not change the route.

For work where test code is appropriate, select one test-writer before selecting the production implementation owner. The client records why tests are useful and what behavior they verify; if domain-specific validation is sufficient, record that method and do not select a test-writer. The test-writer and implementation owner both use the requirements and the approved plan or direct work-order contract as their source of truth. A test-writer does not derive a public name, signature, or behavior from production code, and an implementation owner does not derive behavior from test code. For a small route without a plan, the work order must contain the same contract details and explicitly state that no plan file is used.

When a task crosses technical boundaries, split the implementation owner by boundary only when the plan identifies separate write scopes and contracts. For example, an AWS Lambda task may use one terraform-implementer for Terraform files and one src-implementer for application source files. Use at most one agent for each boundary, never one per file. Keep the generic generator for work that does not need a boundary-specific implementation owner.

If the scope or requirements seem unclear during a small implementation, first inspect the current implementation, acceptance criteria, and source of truth. When they settle a correction within the accepted requirements and contract, return it as `REVISE` to the same implementation owner; do not route it to planner. If a material question remains, return it to the client. The client either resolves it from evidence, asks the user when their intent is needed, or checks the planner criteria and obtains the required permission before any planner handoff. A new decision or contract change does not automatically trigger planner. Do not silently expand the work order.

### Plan and approval ownership

Planner outputs `plan.md` and necessary design ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`; `<repository-slug>` is the final directory name of the absolute path returned by `git rev-parse --path-format=absolute --git-common-dir`, with `.git` removed, and `<task-slug>` starts with the work-start date in `YYYYMMDD-...` form. The worktree directory name is not used as the repository identifier. The legacy Claude plan directory is not a valid plan location. A new plan starts with an unchecked `Approval` entry. Do not paste the full plan or long excerpts into chat. Give the user the plan path and a concise summary of scope, decisions, success criteria, verification, and unresolved items; the user reviews the saved plan and alone may explicitly approve it and change the checkbox from `[ ]` to `[x]`. Until then, no dependent work may begin: do not create or edit tests, fixtures, mocks, or implementation files, and do not run a pre-implementation RED check. The test-writer must independently read the exact plan path and verify `[x]` before writing or running anything. If the path is missing, the checkbox is `[ ]`, or user approval cannot be verified, stop and report `[BLOCKED]`. No agent may change `[ ]` to `[x]` or replace the user's approval with a self-reported claim. When the planner makes a substantive revision, it must reset the canonical plan's checkbox to `[ ]`; only the user may approve it again. A generator pre-check rejects self-reported approval even when the file happens to contain `[x]`.

Before creating a task directory, the client checks for an existing directory tied to the same ongoing requested outcome. A continuation, changed requirement, review correction, evaluator `REDESIGN`, or later work session for that outcome reuses the original directory and exact `plan.md` path; it does not get a new date-prefixed `<task-slug>`. Create a new directory only for a genuinely independent requested outcome. If the existing records do not establish which directory is canonical, do not create another one; resolve the path from the original work order and approval history first.

Before revising the canonical `plan.md` or an ADR, read it and its diff, then edit the canonical file in the existing task directory with a targeted change. A continuation or changed requirement for the same outcome reuses the same task directory and canonical path; create a new directory only for an independent outcome. Preserve an affected canonical file as a uniquely named `.old` snapshot only when a user change to requirements or requested scope supersedes an existing plan or ADR that records the former requirements. This preserves the old requirement baseline in the same task directory; it does not call for a new canonical file or a snapshot on every edit. Do not archive an in-progress draft, corrections or review feedback within the same requirements, wording changes, or Approval-only updates; edit the existing canonical file in place. Do not copy the task directory or unaffected files, and never overwrite an existing archive. Archived files are historical and do not count as active plans or ADRs. A requirement change that materially revises the current plan resets its `Approval` to `[ ]`; wait for the user to review and explicitly approve that revision. Approval in an archive or evaluator PASS does not approve the current plan. Until then, do not start dependent work or external operations such as registering secrets, changing connection destinations, or running workflows or CI.

### ADR ownership

When the planner route is selected, the planner creates `plan.md` and the necessary ADRs under `~/.agents/plan/<repository-slug>/<task-slug>/`. Each ADR must contain `## Background`, `## Options Considered`, `## Rejected Because`, `## Decision`, `## Rationale`, `## Impact`, and `## Unresolved Items or Review Conditions`, or equivalent headings in the repository's language. Options and rejection reasons come before the decision. The planner records design decisions in the plan and ADRs, then checks its output against the requirements, source evidence, plan/ADR consistency, verification feasibility, unresolved items, canonical paths, and user-owned Approval state before reporting completion. The test-writer, implementation owners, and client do not create or edit ADRs; if their work reveals a decision, they return it to the client. A direct route may document a settled decision without planner; the client reevaluates the planner criteria and permission gate before routing a material unresolved decision to the existing planner. The client handles plan and ADR quality checks with the planner; an evaluator is never used to assess planner output, directly or through the client.

When a responsibility is unclear, it belongs to the client — the client then either owns it or delegates it explicitly. What no role may do is quietly assume it.

### Agent lifecycle and reuse

The client records the role map and keeps each selected agent instance for the task. Do not spawn a new agent for every evaluator pass, feedback round, file, or test. Reuse the existing test-writer only when test code was selected, along with the implementation owner, boundary specialist, and evaluator when one was selected, by sending them the new evidence or feedback. Do not invoke an evaluator while any work owner is active or before all owners have completed their work and DoD. Use one consolidated quality assurance pass after completion; a follow-up is limited to one check of corrected material findings when independent confirmation still materially reduces risk. Never use an evaluator to assess plan or ADR quality. Start a replacement only when the existing agent is unavailable, the write scope changes, or the plan adds a technical boundary not covered by an existing agent. Independence comes from keeping QA separate from implementation, not from repeating it.

Planner reports the completed plan and its self-review to the client first. The client checks plan and ADR quality and routes concrete omissions or contradictions to the same planner. An evaluator is never used to assess planner output, whether through a direct handoff or a client-mediated request.

When regression tests are the right verification, the pipeline is `test-writer → implementation owner`, followed by optional evaluator quality assurance of the completed result only after the implementation owner completes its DoD and reports evidence, when separate QA materially reduces quality risk. Never use evaluator to assess the plan or ADR. In a planner route, the user must approve the complete plan before test-writer begins; in a direct route, the work order must explicitly say no plan is used and explain why test code is appropriate. The test-writer creates only the tests and type-appropriate simple mocks required by that contract, then reports RED. The implementation owner consumes the requirements, contract, and RED evidence, changes only production files in its scope, runs its own DoD, and reports the results. If a failure is caused by the test harness or mock rather than production behavior, send it back to the existing test-writer; the implementation owner must not edit the test to remove the failure. When tests are not appropriate, skip this pipeline and use the planned domain-specific validation after implementation.

### Subagent completion gate

When a subagent is selected, do not start the next dependent step until that subagent has explicitly reported completion and its work evidence. Do not interrupt, redirect, or edit an in-progress subagent scope unless a concrete blocker or an explicit client request requires it; unnecessary intervention is prohibited. A missing file or delayed response while the owner is active is not a blocker and does not justify a duplicate invocation. Completion must never be inferred from elapsed time, partial output, file presence, or a parent-agent assumption. If a deliverable is incomplete after its owner reports completion, return it to that same owner with `REVISE`.

### Main session (client)

Owns:

- Turning the user's request into unambiguous requirements
- Defining acceptance criteria in a verifiable form, before delegating
- Choosing the contractor and writing the work order
- Receiving the deliverable and judging it against the acceptance criteria
- Selecting an evaluator without a concrete quality risk that independent QA of completed work would reduce
- Questions about unresolved branches that materially change the deliverable

Must NOT:

- Write production code when an implementation-agent route has been selected, or test code when the test-writer route has been selected
- Skip a required planner-route ADR when implementing directly
- Re-decide a design the contractor already made; send it back instead
- Present an owner's checks as independent evaluator QA, or treat evaluator QA as a substitute for the owner's DoD
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
- Reporting the test scope, mock assumptions, RED evidence, and any design decision that must return to the client for routing

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

The client may edit directly when the change is confined to a single file, needs no test, and does not alter behavior — typos, comments, config values, documentation. The same route applies to low-risk changes limited to instructions, skills, documentation, or agent configuration across multiple source files when requirements are clear and no design decision is needed. For other tasks, use the routing comparison above. When the generator's parallel, specialist, scale, safety, or independent-review benefits do not outweigh delegation overhead, the client may implement directly within the settled work order and does not create an ADR. A new decision does not automatically switch the task to planner; the client checks the qualifying planner criteria and obtains user permission before any handoff. If only the task's size is borderline, compare the plan's expected reduction in coordination, integration, or risk with its context and delegation cost; use the direct route when that benefit is not concrete. If a material requirement remains unclear, ask the user when their intent is needed instead of asking planner to guess.

The same exception covers a mechanical test-only fix: an existing test's expectation is stale against a settled implementation, the root cause is already established, and the correction touches nothing but that expectation (its value, the test's name, its comments). No behavior is being designed, so there is no TDD cycle to hand over; the work owner runs and checks the applicable DoD. Delegate instead the moment any of these holds: it is still open whether the test or the implementation is wrong, a test must be added / removed / skipped / xfailed, or the fix reaches production code at all. A test rewritten so a failure stops appearing is never a minor change, however few lines it takes.

The client may also implement a non-minor task directly when the task's size, complexity, safety, parallel-work needs, specialist knowledge, independent-implementer value, and delegation overhead show that direct implementation is more efficient. This is a route decision, not a blanket exception: the client records the comparison and the reason generator was omitted in the work order. A new decision does not switch the task to planner unless the qualifying criteria apply and the user has authorized that handoff. The client runs the selected DoD and adds an evaluator only when independent QA of the completed deliverable materially reduces quality risk.

### Work order contents (scaled to the task)

A subagent cannot see the parent conversation, so every delegation must carry the context needed to work safely:

1. Requirements — what to build and why
2. Acceptance criteria — verifiable conditions for completion
3. Target files and the boundary of what may be touched

For non-trivial work, also state the existing patterns to follow, prohibitions, and report format. A minor delegation may use a shorter work order when the requirements, acceptance criteria, and file boundary are unambiguous.

Never delegate without acceptance criteria. If the client selects an evaluator, provide the same agreed criteria, completed deliverable, and work-owner DoD evidence. A task's minor status alone neither requires nor justifies evaluator QA.

### Quality assurance role (evaluator)

The evaluator is a quality-assurance agent, not a reviewer. It provides independent, criteria-based QA for a completed deliverable only when separate QA materially reduces risk; it never evaluates a plan or ADR or acts before implementation is complete. The work owner remains responsible for completing the work and checking it against the agreed requirements before reporting done.

Its boundary:

- **Owns** — independent QA of a completed deliverable and the owner's DoD evidence against agreed criteria for concrete security, correctness, quality, performance, or verification defects; it may report PASS / REVISE / REDESIGN as a QA result, not an acceptance decision
- **Reads only** — it holds no write tools by design. It reports defects; it does not fix them. A verdict that says "fixed it during QA" means the seat was violated
- **Does not own or redefine DoD** — the work owner selects and runs applicable checks from the agreed work order, project instructions, and relevant skills. The evaluator assesses the submitted evidence and does not run or re-run those checks
- **Does not assess planner output** — the planner checks plan/ADR completeness and evidence before reporting; the client addresses omissions or contradictions with the planner. The evaluator never assesses plan or ADR quality
- **Does not touch the acceptance criteria** — if a criterion is untestable or contradicts the plan, it reports the specific conflict to the client rather than substituting a criterion it prefers
- **Does not redesign** — implementation defects that fit the accepted criteria, plan, and contract are REVISE and return to the same implementation owner, including for planner-route tasks. Use REDESIGN only when resolving the issue requires a material design decision or a change to requirements or the shared contract; return it to the client, which checks the planner criteria and permission gate before handoff
- **Reports to the client only** — never directly to the user

Quality-assurance scope is limited to:

1. Confirm that the submitted evidence is relevant to the agreed acceptance criteria; do not invent criteria or infer DoD completion from an unsupported claim
2. Assess the completed deliverable and its diff for concrete security, correctness, quality, performance, or verification defects, using the work owner's checks as evidence
3. Use the approved plan only as context for the implementation contract. Never assess plan or ADR completeness, quality, or correctness

The work owner determines whether its DoD is complete and reports the evidence. The client makes the final acceptance decision against the user's requirements. An evaluator PASS means no material issue was found within the completed-deliverable QA scope; it is neither a quality guarantee, task-completion gate, nor plan approval. Concrete evaluator findings return to the client, who routes them to the owner of the affected deliverable. That owner corrects the issue and re-runs its own applicable checks.

## Core Agents (role-separated pipeline)

| Agent | Role | Required boundary |
|-------|------|-------------------|
| planner | Design decisions, implementation planning, and design ADRs when selected | Writes and self-checks only the plan and ADRs it owns; does not edit implementation files or user-owned Approval |
| test-writer | Independent test design, test code, fixtures, and mocks when that is the appropriate verification | Reads requirements and the contract; confirms planner approval before writing; edits only test-side files and returns new design decisions to the client |
| generator | General production implementation and build error resolution when selected | Edits only production files in the work order; does not create ADRs and returns new design decisions to the client |
| terraform-implementer | Terraform and AWS infrastructure implementation | Edits only Terraform files in the assigned boundary and follows the Terraform skill |
| src-implementer | Application source implementation | Edits only source files in the assigned boundary and follows the project's source-language skills |
| evaluator | Independent quality assurance when justified | Assesses a completed deliverable and owner evidence after all owners finish DoD; never assesses plan/ADR quality, selects or runs DoD, certifies completion, approves plans, or edits the deliverable |

The available agents and tools depend on the actual execution environment. Tool availability never changes the responsibility boundary: if a role appears to need a capability outside its boundary, delegate that responsibility to the role that owns it instead of widening the role.

## Utility Agents

| Agent | Role | When to Use |
|-------|------|-------------|
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code removal | Code maintenance |
| doc-updater | Documentation updates | Architecture docs |

These are narrow, well-specified contractor roles. They receive the same complete work order as any other contractor and report back to the client. The work owner runs the selected DoD; evaluator QA is added only after work completion and when it provides material independent value.

## Pipeline Flow

```
[User Input] → [Classify]
                 ├─ minor → [Client + Relevant Checks] → [Optional Evaluator QA after DoD]
                 ├─ low-risk instructions/docs/config → [Client + Relevant Checks] → [Optional Evaluator QA after DoD]
                 ├─ small behavior change → [Test-writer if useful] → [Implementation Owner + DoD] → [Optional Evaluator QA after DoD]
                 └─ qualifying planner case → [Explain basis + ask permission] → [Planner] → [Present Plan] → [Separate plan review + Approval [x]]
                                                     → [Test-writer if useful] → [Implementation Owner(s) + DoD] → [Optional Evaluator QA after DoD]
                                                             ↑
                                                             └─ REDESIGN feedback
```

The main session controls the pipeline using the agents available in the execution environment. Test-writer is selected only when test code is the appropriate verification; declarative changes may use their own validators and checks without creating test files. In a planner route, planner must complete and self-check its plan and ADRs before reporting; give the user the saved plan path and a concise summary instead of pasting the full plan into chat. The client checks plan omissions or source conflicts and returns them to the same planner; evaluator is never used to assess planner output. No test-writer or implementation work begins until the user reviews the saved plan and explicitly changes `Approval` to `[x]`. The work owner runs its selected DoD and reports evidence. The client may be the production implementation owner on the direct route, but must not create ADRs; a new decision returns to the client, which checks the planner criteria and obtains explicit user permission before any new planner handoff. Select an evaluator only for independent QA of completed deliverables, after every work owner finishes DoD, when it materially reduces quality risk.

## Agent Constraints

Do not assume that a contractor can see the parent conversation. Pass all required information in the work order. Subagents must not invoke other subagents; the parent client owns the role map and lifecycle. Require structured reports, and use files for large data exchange when the environment supports a shared workspace.

Japanese docstrings and comments must not end with `。`, including immediately before a closing `"""` in one-line or multi-line docstrings.

## Invocation Rules

### Automatic

| Trigger | Action |
|---------|--------|
| Minor change | Client makes the direct change and runs applicable checks; optional evaluator QA only after the deliverable and DoD are complete, when a concrete risk justifies it |
| Small behavior change with useful regression tests | Run one test-writer, then the selected client or implementation owner, who runs the work-order DoD; add evaluator only for post-completion QA when a concrete risk justifies it |
| Small behavior change with domain-specific checks instead of test code | Implement through the selected owner and have that owner run the applicable checks; do not invoke test-writer; add evaluator only for post-completion QA when a concrete risk justifies it |
| Low-risk instruction, documentation, skill, or agent-configuration-only change | Client edits directly, then runs rendering or static checks; do not invoke test-writer or evaluator by default |
| Work that meets a concrete planner criterion | State the evidence, why direct handling is insufficient, the risk planning reduces, and the scope; obtain the user's explicit permission before sending any task or analysis to planner. After planner completes, give the user the plan path and summary and wait for the separate plan review and `Approval [x]` before dependent work |
| Any completed work | The work owner reports its DoD evidence. Invoke evaluator only for independent QA of completed deliverables after all owners finish DoD, and never to assess plans or ADRs |
A component boundary alone does not require planner. Before routing a boundary issue to planner, inspect the current implementation, established module ownership, Terraform resource addresses, and other source-of-truth evidence. If these settle the correction, use the direct route; returning a resource to its established module and preserving its address are implementation corrections, not new design decisions.

### Manual (user requests)

| Scenario | Action |
|----------|--------|
| E2E tests needed | **e2e-runner** |
| Dead code cleanup | **refactor-cleaner** |
| Documentation updates | **doc-updater** |

## Feedback Loop Rules

- The work owner completes corrections and reruns its own checks; evaluator is not invoked for each correction round
- Evaluator QA result is one of: PASS / REVISE / REDESIGN, and does not decide task acceptance or completion
- Do one consolidated QA assessment after completion; allow at most one follow-up check when corrected material findings still need independent confirmation
- REVISE caused by test-side code: send it to the existing test-writer, then reuse the existing implementation owner after a corrected RED handoff
- REVISE caused by a completed production deliverable that can be fixed within the accepted criteria, plan, or contract: send it to the existing implementation owner. The owner corrects it, reruns its DoD, and reports evidence. Plan or ADR deficiencies go from the client to the existing planner; evaluator never assesses planner output
- REDESIGN: use only when resolving the issue requires a material design decision or a change to requirements or the shared contract; return it to the client. The client rechecks the planner criteria and permission gate before sending it to the existing planner. A failure to implement the agreed plan is REVISE, not REDESIGN. Max 1 REDESIGN; second triggers user escalation
- Do not spawn a replacement for a feedback round, file, or test. Replace an agent only when it is unavailable, its write scope changes, or a new technical boundary is added
- If the work owner cannot complete its corrections after 3 rounds, report remaining issues and evidence to the user; do not add evaluator rounds to reach PASS
