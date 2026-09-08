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
4. **Output Plan File** - Write to `.agents/plan/<slug>/plan.md`, where `<slug>` starts with the work-start date in `YYYYMMDD-...` form
5. **Wait for Approval** - MUST receive explicit user approval before the selected implementation owner proceeds

## When to Use

Use `/plan` when:

- Starting a new feature
- Making significant architectural changes
- Working on complex refactoring
- Multiple files or components will be affected
- A design decision is required
- Requirements are unclear or ambiguous

Do not use `/plan` for a minor change, defined as one implementation file, no test needed, and no behavior change. A small implementation may also skip `/plan` when it stays within one component and one implementation file, has clear requirements, follows an existing pattern, and needs no new design decision. In that case, choose client direct implementation or generator by comparing task size, complexity, safety, parallel-work needs, specialist knowledge, independent implementation value, and delegation overhead, then always run evaluator.

## Plan Output Format

The plan is written to `.agents/plan/<slug>/plan.md` with this structure:

```markdown
# Plan: [Title]

## Approval
- [ ] User reviewed and explicitly approved

## Overview
[2-3 sentences]

## Design Decisions
[Each decision with rationale]

## Steps (ordered)
1. [Step]: [file path]
   - What: specific action
   - Why: reason
   - Test: how to verify

## Test Strategy
## Risks
## Success Criteria
```

The plan directory may also contain multiple implementation ADRs in Markdown. The implementation owner creates those ADRs; planner creates only `plan.md` and does not edit the ADR collection.

## Approval Flow

- The plan is presented to the user in full
- User must explicitly approve ("OK", "go ahead", "LGTM", "approve")
- Ambiguous responses are NOT approval
- Only the user may update the Approval checkbox from `[ ]` to `[x]` after reviewing the full plan
- The parent agent, planner, generator, and evaluator must not change the checkbox or replace user approval with a self-reported claim
- The selected implementation owner will not start if the checkbox is unchecked

## Integration with Other Commands

After planning:

- Use `/orchestrate` to run the full pipeline (plan is already done)
- Use `/tdd` to implement a single step with TDD when generator is selected
- The implementation owner reads the plan file directly

## Related

This command invokes the `planner` agent (model: opus).

## Arguments

$ARGUMENTS: Description of what to plan
