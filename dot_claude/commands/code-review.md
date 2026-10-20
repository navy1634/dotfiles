---
name: code-review
description: メインセッションでコミット前の変更を確認し、セキュリティ・品質上の問題を報告します。
---

# Code Review

Perform this check in the current session. Do not invoke the evaluator agent; it provides optional quality assurance for completed deliverables after their owners finish DoD, not on-demand code review. Inspect uncommitted changes:

1. Run `git diff --name-only HEAD` to get changed files

2. For each changed file, evaluate:

**Security (CRITICAL):**

- Hardcoded credentials, API keys, tokens
- SQL/Command injection vulnerabilities
- XSS vulnerabilities
- Missing input validation
- Path traversal risks
- Authentication/authorization bypasses

**Code Quality (HIGH):**

- Functions > 50 lines
- Files > 800 lines
- Nesting depth > 4 levels
- Missing error handling
- Mutation patterns (should be immutable)
- Missing type hints
- Missing tests for new code

**Performance (MEDIUM):**

- O(n^2) where O(n log n) possible
- N+1 queries
- Unnecessary allocations

3. Generate report with:
   - Severity: CRITICAL, HIGH, MEDIUM
   - File location and line numbers
   - Issue description
   - Specific fix instruction

4. Verdict: PASS / REVISE based on the findings above. Do not treat this result as task completion or an evaluator QA result.

## Related

This command runs in the main session and does not invoke evaluator. Evaluator is reserved for optional post-completion quality assurance when it materially reduces risk.

## Arguments

$ARGUMENTS: Optional scope (e.g. "security only", "performance focus")
