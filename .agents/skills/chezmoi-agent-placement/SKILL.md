---
name: chezmoi-agent-placement
description: この chezmoi dotfiles リポジトリで、エージェントの指示・設定・skill を追加、移設、整理するときに正本と配置先を決め、移設前後の意味と展開結果を照合する。
---

# Chezmoi Agent Placement

Use this skill when changing where agent instructions or skills live in this dotfiles repository.
Use `orchestrate` first to select the repository work route.
This skill decides ownership and verifies a relocation; it does not replace the behavior rules in the destination.

## Inspect before choosing a destination

Read the current text, nearby conventions, all execution entrypoints, and scoped Git status and diffs.
Check `.gitignore`, `.chezmoiignore`, and `chezmoi managed` before treating a tracked source as deployed.
Read the package-placement section of this repository's README before changing package configuration.
For a proposed plugin destination, inspect that plugin's README and existing skills as well.
Identify the intended readers, affected agents, activation timing, and whether a rule applies across projects.
Check how the source is rendered and whether its intended agents can load the destination.
Do not use file length alone to decide that a rule is redundant.

## Place each rule at its owner

- Put rules intended for both Codex and Claude in `.chezmoitemplates/agents/AGENTS.md`.
  Check its `dot_codex/AGENTS.md.tmpl` and `dot_claude/CLAUDE.md.tmpl` wrappers.
- Keep instructions only for this dotfiles checkout in root `AGENTS.md`.
  Chezmoi ignores that file; it is not a deployed home file.
- Put agent routing and delegation lifecycle in `.chezmoitemplates/agents/skills/orchestrate/SKILL.md`.
  Check the Codex wrapper and every Claude command that can invoke the same procedure.
- Put a subagent's role, write boundary, pre-check, and reporting contract in `.chezmoitemplates/agents/agents/<role>.md`.
  Check the relevant Codex and Claude agent wrappers.
- Put a reusable procedure for multiple repositories in an existing suitable `plugin-agent-toolbox` skill.
  Create a new plugin skill only for a distinct capability.
- Put a procedure specific to this dotfiles checkout in `.agents/skills/<name>/SKILL.md`.
  Do not deploy it through `.chezmoitemplates/agents/skills/` or `dot_codex/skills/`.
- Put Codex-only loading or runtime configuration under `dot_codex/`.
  Do not change shared Claude material for a Codex-only setting.

Check the actual template references before editing.
A path in `.chezmoitemplates/` is a source, not proof that Codex or Claude loads it.
Keep a short entrypoint in an always-on instruction when skill discovery alone would not reliably trigger a required rule.
Do not copy a long procedure into that entrypoint.
Do not make a task-specific plugin skill carry agent roles, approval ownership, or other always-on rules.

## Preserve behavior when relocating

Before removing text, map each obligation, condition, exception, owner, and approval gate to a reachable destination.
Include restrictions on agent counts, reuse, completion reports, and correction routing when moving delegation rules.
Check both the skill entrypoint and any references it links to.
Search for conflicting wording and stale references in the source, wrappers, agent definitions, and plugin references.
When a plugin skill changes, bump its plugin and marketplace versions together and compare the installed cache with the new source.
Confirm that rules left in `AGENTS.md` remain effective without depending on optional skill selection.
If two rules disagree, resolve the conflict from current user instructions and the repository's source of truth before claiming equivalence.
Preserve the user's uncommitted changes and do not edit rendered home files.

## Verify the delivered source

Render each changed chezmoi wrapper with `chezmoi execute-template --file <wrapper>`.
Validate a new or changed skill with the skill creator's `quick_validate.py` and any relevant plugin validator.
Run `git diff --check` in each changed repository.
Read the final source and diff for meaning, line breaks, dangling references, and unrelated edits.
State separately what the source and rendering checks proved and whether the live Codex installation has been updated.
Report any source that `.chezmoiignore` excludes from deployment.
Do not treat successful rendering as `chezmoi apply` or a plugin update.
