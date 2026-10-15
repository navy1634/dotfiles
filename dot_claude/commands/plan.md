---
name: plan
description: planner起動条件に該当する作業の要件分析・設計判断・実装計画を作成。ユーザーの明示的な承認を待ってから実装に進む。
---

# Plan Command

This command invokes the **planner** agent only when the task meets the planner triggers. It creates a comprehensive implementation plan before implementation starts.

## What This Command Does

1. **Analyze Requirements** - Restate and clarify what needs to be built
2. **Read Codebase** - Identify existing patterns and affected components
3. **Make Design Decisions** - Document choices with rationale
4. **Define Shared Contract** - Record public names, paths, argument and return types, inputs, outputs, external boundaries, and implementation write scopes. Split `terraform` and `src` scopes when both are involved
5. **Output Plan and Design ADRs** - For a new task, write `plan.md` to `~/.agents/plan/<repository-slug>/<task-slug>/` and create the design ADRs in the same directory, where `<repository-slug>` identifies the Git common directory rather than the worktree and `<task-slug>` starts with the work-start date in `YYYYMMDD-...` form. For a continuation or revised requirement for the same outcome, inspect and reuse the original task directory and exact `plan.md` path instead of creating another `<task-slug>`
6. **Wait for Approval** - MUST receive explicit user approval before the selected test-writer and implementation owner(s) proceed

## When to Use

Use `/plan` when:

- Starting a new feature
- Making significant architectural changes
- Working on complex refactoring
- Multiple files or components will be affected
- A design decision is required
- Requirements are unclear or ambiguous

Do not use `/plan` for a minor change, defined as one implementation file, no test needed, and no behavior change. A small behavior change may also skip `/plan` when it stays within one component and one implementation file, has clear requirements and a shared contract, follows an existing pattern, and needs no new design decision. In that case, invoke one test-writer only when useful, then choose the client or an implementation owner by comparing task size, complexity, safety, parallel-work needs, specialist knowledge, independent implementation value, and delegation overhead. The work owner runs its DoD; the client selects evaluator only for optional quality assurance of completed deliverables after all owners finish their DoD, when it materially reduces quality risk.

## Plan Output Format

Before revising an existing `plan.md` or ADR, read the current file and its diff, then use a targeted `apply_patch` edit on the canonical file; do not replace it wholesale or create a temporary copy. Reuse the same task directory and canonical path for a continuation or changed requirement. Follow the shared `AGENTS.md` rule: preserve an affected `.old` snapshot only when a user change to requirements or requested scope supersedes an existing plan or ADR that records the former requirements. Do not archive in-progress drafts, corrections within the same requirements, wording changes, or Approval-only updates. Never overwrite an existing archive. Archived files are historical only. A requirement change that materially revises the canonical plan resets its `Approval` to `[ ]`. Only the user may approve the revised plan, and evaluator PASS is not approval. Do not begin dependent work or external operations such as registering secrets or running workflows before that approval.

The plan is written to `~/.agents/plan/<repository-slug>/<task-slug>/plan.md` with this structure:

```markdown
# Plan: [Title]

## Approval
- [ ] User reviewed and explicitly approved

## Overview
[2-3 sentences]

## Design Decisions
[Each decision with rationale]

## Shared Contract
[Public names, paths, argument and return types, inputs, outputs, external boundaries, and implementation write scopes]

## Role Map
[One planner, one test-writer only when test code is appropriate, one implementation owner per technical boundary, and an optional evaluator only for quality assurance of completed deliverables after all owners finish their DoD, when it materially reduces quality risk. Reuse selected instances.]

## Steps (ordered)
1. [Step]: [file path]
   - What: specific action
   - Why: reason
   - Test: how to verify

## Test Strategy
[test-writer's independent test scope, mock policy, RED evidence, and handoff to implementation owner(s)]
## Risks
## Success Criteria
```

When the planner route is selected, planner creates the necessary design ADRs in the task directory. The test-writer, implementation owners, and client do not create or edit ADRs; they return new design decisions to the existing planner. A direct route with no design decision has no ADR.

## Planner Completion and Approval Flow

- Planner completes and self-checks the saved plan and active ADRs before reporting to the client
- Planner returns the exact paths, Approval state, self-review evidence, and unresolved items to the client first; a direct planner-to-evaluator handoff is prohibited
- The client returns concrete omissions, unsupported claims, or inconsistencies to the same planner. It does not complete the planner's self-review
- Do not invoke evaluator for plan or ADR assessment. The client checks plan quality and returns concrete omissions or unsupported claims to the same planner
- Give the user the saved plan path and a concise summary of scope, decisions, success criteria, verification, and unresolved items; do not paste the full plan into chat
- User must explicitly approve ("OK", "go ahead", "LGTM", "approve")
- Ambiguous responses are NOT approval
- Only the user may update the Approval checkbox from `[ ]` to `[x]` after reviewing the saved plan
- No agent may change the checkbox from `[ ]` to `[x]` or replace user approval with a self-reported claim; when the planner makes a substantive revision, it must reset the canonical plan's checkbox to `[ ]`
- After approval, invoke one test-writer only when appropriate and one implementation owner per technical boundary. Each work owner completes its DoD; evaluator is not invoked for every correction round
- The selected test-writer and implementation owner(s) will not start if the checkbox is unchecked

## Integration with Other Commands

After planning:

- Use `/orchestrate` for implementation and work-owner DoD; `/orchestrate` selects evaluator only for optional quality assurance after all work owners finish their DoD, when separate QA materially reduces risk
- Use `/tdd` to implement a single production step with TDD when an implementation owner is selected
- The implementation owner reads the plan file directly

## Related

This command invokes the `planner` agent (model: opus).

## Arguments

$ARGUMENTS: Description of what to plan
