---
name: create-gitlab-issues-from-implementation-plan
description: Use when creating GitLab Issues from an implementation plan file. Reads each phase from the plan, checks for existing issues to prevent duplicates, and creates one issue per phase using the glab CLI. Supports milestone assignment, label tagging, assignee mapping, and confidential issues.
version: 1.0.0
last_updated: 2026-06-07
---

# Create GitLab Issues from Implementation Plan

Read the implementation plan at `${input:PlanFile}` and create one GitLab Issue per phase using the `glab` CLI.

## Primary Directive

Parse the implementation plan, map each phase to a structured GitLab issue, check for duplicates, and emit `glab issue create` commands that the agent executes. Produce a creation report at the end.

## Output Language

- Write issue **titles** in the same language as the plan's phase goal.
- Write issue **descriptions** in the same language as the plan's human-readable content (Vietnamese by default if the plan is Vietnamese).
- Keep technical IDs (`TASK-*`, `GOAL-*`, `REQ-*`, `FILE-*`, `TEST-*`, `RISK-*`) unchanged.
- Keep CLI commands, flags, paths, and GitLab identifiers in English.

## When To Use

- After `create-implementation-plan` has produced a `/plan/*.md` file.
- When the user wants to track each implementation phase as a GitLab Issue on a self-hosted or cloud GitLab instance.
- When the user provides a plan file path and optionally a GitLab project path, milestone, labels, and assignees.

## Avoid Using When

- The plan file does not exist or contains no phases.
- The target platform is GitHub — use `create-github-issues-feature-from-implementation-plan` instead.
- The user has not authenticated `glab` (`glab auth status` returns an error).

## Prerequisites

| Requirement | Check Command |
|---|---|
| `glab` installed | `glab --version` |
| Authenticated to GitLab | `glab auth status` |
| Correct project context | `glab repo view` (or use `--repo` flag) |

## Inputs

| Input | Variable | Description |
|---|---|---|
| Plan file path | `${input:PlanFile}` | Path to the `/plan/*.md` implementation plan (e.g. `plan/feature-auth-module-1.md`) |
| GitLab project path | `${input:GitLabRepo}` | Optional. `OWNER/REPO` or `GROUP/NAMESPACE/REPO`. If omitted, uses current repo. |
| Milestone | `${input:Milestone}` | Optional. Milestone title or global ID to assign to all issues. |
| Labels | `${input:Labels}` | Optional. Comma-separated label names applied to all issues (e.g. `feature,planning`). |
| Assignees | `${input:Assignees}` | Optional. Comma-separated GitLab usernames (e.g. `alice,bob`). |
| Confidential | `${input:Confidential}` | Optional. Set `true` to mark all issues confidential. Default: `false`. |
| Dry Run | `${input:DryRun}` | Optional. Set `true` to print commands without executing them. Default: `false`. |

## Process

### Step 1 — Preflight Checks

1. Verify `glab` is installed: `glab --version`.
2. Verify authentication: `glab auth status`.
3. If `${input:GitLabRepo}` is provided, verify the project is reachable:
   ```bash
   glab repo view --repo "${input:GitLabRepo}"
   ```
4. Read the plan file at `${input:PlanFile}`.
5. If the file does not exist, report the error and stop.

### Step 2 — Parse the Implementation Plan

Extract from the plan file:

| Field | Where to Find It |
|---|---|
| `plan_goal` | `goal:` front matter field |
| `plan_version` | `version:` front matter field |
| `plan_status` | `status:` front matter field |
| `plan_tags` | `tags:` front matter field |
| Phases | All `### Implementation Phase N` headings under `## 2. Implementation Steps` |
| Phase goal | The `- GOAL-NNN:` bullet inside each phase |
| Phase tasks | All rows in the phase's task table (`TASK-*`) |
| Phase requirements | `REQ-*` and `CON-*` items from `## 1. Requirements & Constraints` relevant to the phase |
| Phase risks | `RISK-*` items from `## 7. Risks & Assumptions` relevant to the phase |
| Phase files | `FILE-*` items from `## 5. Files` relevant to the phase |
| Phase tests | `TEST-*` items from `## 6. Testing` relevant to the phase |

For each phase, build:
- **Issue title**: `[PlanGoal] — Phase N: <GOAL-NNN text>` (truncated to 255 chars if needed)
- **Issue description**: rendered Markdown body (see [Issue Description Template](#issue-description-template))

### Step 3 — Check for Existing Issues

Before creating each issue, search for a duplicate using the phase title substring:

```bash
glab issue list \
  --repo "${input:GitLabRepo}" \
  --search "<phase title substring>" \
  --state opened \
  --output json
```

- If a matching open issue is found, **skip** creation and record it as `SKIPPED (duplicate)` in the report.
- If no match is found, proceed to create.

### Step 4 — Create Issues

For each phase without a duplicate, execute:

```bash
glab issue create \
  --repo "${input:GitLabRepo}" \
  --title "<issue title>" \
  --description "<issue description>" \
  --label "<labels>" \
  --milestone "<milestone>" \
  --assignee "<assignees>" \
  [--confidential]
```

- Omit `--repo` if `${input:GitLabRepo}` was not provided.
- Omit `--label` if `${input:Labels}` is empty.
- Omit `--milestone` if `${input:Milestone}` is empty.
- Omit `--assignee` if `${input:Assignees}` is empty.
- Include `--confidential` only if `${input:Confidential}` is `true`.
- If `${input:DryRun}` is `true`, print the command and skip execution.

Capture the created issue URL from `glab` output for the report.

### Step 5 — Produce Creation Report

After processing all phases, output a Markdown table:

```markdown
## GitLab Issue Creation Report

**Plan**: `<plan file path>`
**Project**: `<GitLab repo path or "current repo">`
**Milestone**: `<milestone or "—">`
**Labels**: `<labels or "—">`
**Assignees**: `<assignees or "—">`
**Dry Run**: `<true | false>`

| # | Phase | Issue Title | Status | URL |
|---|---|---|---|---|
| 1 | Phase 1 | [Plan Goal] — Phase 1: ... | ✅ Created | https://gitlab.com/... |
| 2 | Phase 2 | [Plan Goal] — Phase 2: ... | ⏭️ Skipped (duplicate) | https://gitlab.com/... |
| 3 | Phase 3 | [Plan Goal] — Phase 3: ... | ❌ Failed: <error message> | — |
```

---

## Issue Description Template

Each created issue uses this Markdown body:

```markdown
## Overview

> This issue was auto-generated from the implementation plan: `<plan file path>`
> Plan goal: **<plan_goal>**  
> Plan status: **<plan_status>**  
> Plan version: `<plan_version>`

---

## Phase Goal

<GOAL-NNN text>

---

## Tasks

| Task | Description | Completed |
|------|-------------|-----------|
| TASK-001 | Description of task 1 | ✅ |
| TASK-002 | Description of task 2 |  |

---

## Related Requirements & Constraints

- **REQ-001**: Requirement text
- **CON-001**: Constraint text

---

## Related Files

- **FILE-001**: Description

---

## Related Tests

- **TEST-001**: Description

---

## Risks

- **RISK-001**: Risk text

---

## Traceability

- **Plan file**: `<plan file path>`
- **Phase**: Phase N
- **Phase goal ID**: GOAL-NNN
- **Task IDs**: TASK-001, TASK-002, ...
- **Plan tags**: `<tags>`

---

*Created by `create-gitlab-issues-from-implementation-plan` skill via `glab` CLI.*
```

---

## glab CLI Reference

### Core Commands Used

| Purpose | Command |
|---|---|
| Check version | `glab --version` |
| Check auth | `glab auth status` |
| View repo | `glab repo view [--repo OWNER/REPO]` |
| List issues (dedup check) | `glab issue list --repo OWNER/REPO --search "..." --state opened --output json` |
| Create issue | `glab issue create --repo OWNER/REPO --title "..." --description "..." [flags]` |

### Full Flag Reference for `glab issue create`

| Flag | Short | Description |
|---|---|---|
| `--title` | `-t` | Issue title (required) |
| `--description` | `-d` | Issue description body (Markdown supported) |
| `--label` | `-l` | Label names, comma-separated or repeated |
| `--milestone` | `-m` | Milestone title or global ID |
| `--assignee` | `-a` | GitLab usernames, comma-separated or repeated |
| `--repo` | `-R` | Target project: `OWNER/REPO`, `GROUP/NS/REPO`, or full URL |
| `--confidential` | `-c` | Mark issue confidential (flag, no value needed) |
| `--web` | | Open browser to issue form instead of CLI creation |

### Multi-label and Multi-assignee Examples

```bash
# Multiple labels — comma-separated
glab issue create -t "Phase 1: Auth Module" -l "feature,planning,phase-1"

# Multiple assignees — comma-separated
glab issue create -t "Phase 1" -a "alice,bob"

# Full example
glab issue create \
  --repo mygroup/myproject \
  --title "[Auth Module] — Phase 1: Database schema migration" \
  --description "$(cat /tmp/phase1_body.md)" \
  --label "feature,planning,database" \
  --milestone "Sprint 3" \
  --assignee "alice,bob" \
  --confidential
```

### Passing Long Descriptions Safely

For multi-line descriptions, write the body to a temp file and use command substitution:

```bash
BODY=$(cat <<'EOF'
## Overview
This issue was auto-generated...
EOF
)
glab issue create -t "Title" -d "$BODY"
```

Or pipe via process substitution:

```bash
glab issue create -t "Title" -d "$(cat /tmp/issue_body.md)"
```

---

## Error Handling

| Situation | Action |
|---|---|
| `glab` not found | Stop. Instruct user to install: `brew install glab` or see https://gitlab.com/gitlab-org/cli |
| Not authenticated | Stop. Instruct user to run `glab auth login` |
| Project not found | Stop. Verify `${input:GitLabRepo}` matches `OWNER/REPO` exactly |
| Milestone not found | Warn and continue without milestone. Record in report. |
| Label does not exist | Warn. `glab` will create the label automatically if it does not exist on self-hosted GitLab with label auto-create enabled. Record in report. |
| Issue creation fails | Record as `❌ Failed: <error>` in report. Continue to next phase. |
| Duplicate found | Skip. Record as `⏭️ Skipped (duplicate)` in report. |

---

## Dry Run Mode

When `${input:DryRun}` is `true`:

1. Parse the plan and perform dedup checks normally.
2. Instead of executing `glab issue create`, print each command to stdout prefixed with `[DRY RUN]`.
3. Mark all rows in the report as `🔎 Dry Run`.

Example:

```
[DRY RUN] glab issue create \
  --repo mygroup/myproject \
  --title "[Auth Module] — Phase 1: Database schema migration" \
  --label "feature,planning" \
  --milestone "Sprint 3"
```

---

## Quality Gates

Before submitting the final creation report:

- [ ] All phases in `## 2. Implementation Steps` were processed (not silently skipped).
- [ ] Each created issue has a URL recorded.
- [ ] Duplicate detection ran for every phase.
- [ ] Errors do not silently pass — they appear in the report.
- [ ] Dry-run mode does not mutate any GitLab state.
- [ ] Issue titles do not exceed 255 characters.
- [ ] No secrets, tokens, or credentials appear in issue descriptions.

---

## Handoff

- After issues are created, consider running `create-implementation-plan` to update the plan's status to `In progress`.
- For milestone creation, use `glab milestone create --title "<name>"` on the target project before running this skill.
- For label creation, use `glab label create --name "<name>" --color "#e11d48"`.
