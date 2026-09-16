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
5. **Output Plan and Design ADRs** - Write `plan.md` to `~/.agents/plan/<repository-slug>/<task-slug>/` and create the design ADRs in the same directory, where `<repository-slug>` identifies the Git common directory rather than the worktree and `<task-slug>` starts with the work-start date in `YYYYMMDD-...` form
6. **Wait for Approval** - MUST receive explicit user approval before the selected test-writer and implementation owner(s) proceed

## When to Use

Use `/plan` when:

- Starting a new feature
- Making significant architectural changes
- Working on complex refactoring
- Multiple files or components will be affected
- A design decision is required
- Requirements are unclear or ambiguous

Do not use `/plan` for a minor change, defined as one implementation file, no test needed, and no behavior change. A small behavior change may also skip `/plan` when it stays within one component and one implementation file, has clear requirements and a shared contract, follows an existing pattern, and needs no new design decision. In that case, invoke one test-writer, then choose the client or an implementation owner by comparing task size, complexity, safety, parallel-work needs, specialist knowledge, independent implementation value, and delegation overhead, and always run evaluator.

## Plan Output Format

When updating an existing `plan.md` or ADR, read the current file and its diff, then use a targeted `apply_patch` edit. Do not reconstruct or replace the entire file, create a temporary full-file copy, or use `cp` or an equivalent whole-file operation for an incremental update. Preserve untouched content, user edits, and the `Approval` checkbox; a full-file rewrite requires an explicit user request.

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
[One planner, one test-writer, one implementation owner per technical boundary, and one evaluator. Reuse each instance for all feedback rounds]

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

## Approval Flow

- The plan is presented to the user in full
- User must explicitly approve ("OK", "go ahead", "LGTM", "approve")
- Ambiguous responses are NOT approval
- Only the user may update the Approval checkbox from `[ ]` to `[x]` after reviewing the full plan
- The parent agent, planner, test-writer, implementation owner, and evaluator must not change the checkbox or replace user approval with a self-reported claim
- After approval, invoke one test-writer and one implementation owner per technical boundary, then reuse those instances and the evaluator for all feedback rounds
- The selected test-writer and implementation owner(s) will not start if the checkbox is unchecked

## Integration with Other Commands

After planning:

- Use `/orchestrate` to run the full `test-writer → implementation owner(s) → evaluator` pipeline (plan is already done)
- Use `/tdd` to implement a single production step with TDD when an implementation owner is selected
- The implementation owner reads the plan file directly

## Related

This command invokes the `planner` agent (model: opus).

## Arguments

$ARGUMENTS: Description of what to plan
