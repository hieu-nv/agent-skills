# GitLab Issue Field Mapping Reference

This document defines how implementation plan fields map to GitLab issue fields
when `create-gitlab-issues-from-implementation-plan` is executed.

---

## Front Matter → Issue Metadata

| Plan Front Matter Field | Maps To | Notes |
|---|---|---|
| `goal` | Issue title prefix in brackets `[<goal>]` | Truncated to 60 chars if long |
| `version` | Traceability section in description | |
| `status` | Traceability section in description | |
| `tags` | Optional additional labels | Only if user opts in |
| `owner` | Optional default assignee | Only if `${input:Assignees}` is empty |

---

## Phase → Issue Mapping

| Plan Field | Issue Field | Example |
|---|---|---|
| Phase heading `### Implementation Phase N` | Issue title suffix | `Phase 1` |
| `GOAL-NNN:` bullet | Phase goal section in description | `GOAL-001: Implement DB schema` |
| Task table rows (`TASK-*`) | Tasks table in description | `TASK-001`, `TASK-002` |
| Completed column (`✅`) | Pre-filled completion state in task table | |
| `REQ-*` / `CON-*` from Section 1 | Related Requirements section | Include only items relevant to phase tasks |
| `FILE-*` from Section 5 | Related Files section | |
| `TEST-*` from Section 6 | Related Tests section | |
| `RISK-*` from Section 7 | Risks section | |
| `ASSUMPTION-*` from Section 7 | Included in Risks section as assumption note | |

---

## Phase Relevance Heuristic

To decide which `REQ-*`, `FILE-*`, `TEST-*`, and `RISK-*` items belong to a phase:

1. **Explicit reference**: The task description or goal text mentions the ID literally (e.g., `see REQ-003`).
2. **Keyword overlap**: Key nouns in the requirement/file/test description overlap with the phase goal or task descriptions.
3. **Sequential block**: If the plan groups items by phase section and the items appear within the phase block, include them.
4. **Fallback**: Include all items in the last phase if none could be resolved. Note the assumption in the issue description.

---

## Title Construction Rules

```
[<plan_goal_abbreviated>] — Phase <N>: <GOAL-NNN text>
```

- `plan_goal_abbreviated`: first 50 characters of `goal` front matter, with `...` appended if truncated.
- `N`: 1-indexed phase number.
- `GOAL-NNN text`: full text of the `GOAL-NNN:` bullet after the colon. Strip the `GOAL-NNN:` prefix.
- Total title length must not exceed **255 characters**. Truncate GOAL text if needed.

**Example**:
```
[Upgrade Authentication Module] — Phase 1: Migrate user table to bcrypt hashing
```

---

## Label Strategy

Labels applied to every issue created from this run:

| Source | Label |
|---|---|
| `${input:Labels}` | All user-provided labels |
| Plan `tags` | Applied only if `tags` are present in front matter AND user sets `${input:UsePlanTags}` to `true` |

Recommended label conventions for implementation plan issues:

| Label | Meaning |
|---|---|
| `planning` | Issue is part of an implementation plan |
| `phase-N` | Which phase (e.g. `phase-1`, `phase-2`) — add automatically if user agrees |
| `feature` / `chore` / `refactor` | From plan `tags` |
| `auto-generated` | Marks issues created by this skill |

---

## Milestone Strategy

- Use the plan's `version` field as a milestone name suggestion if `${input:Milestone}` is empty.
- Do not create milestones automatically. Instruct the user to create missing milestones with:
  ```bash
  glab milestone create --title "v1.0" --repo OWNER/REPO
  ```

---

## Deduplication Logic

A phase is considered a **duplicate** if an existing open issue:

1. Has a title that contains the exact phase title substring, OR
2. Has a title that starts with the same `[plan_goal_abbreviated] — Phase N:` prefix.

Check using:
```bash
glab issue list \
  --repo "${REPO}" \
  --search "[${PLAN_GOAL_ABBREVIATED}] — Phase ${N}" \
  --state opened \
  --output json | python3 -c "import sys,json; issues=json.load(sys.stdin); print(len(issues))"
```

If count > 0, skip and log `SKIPPED (duplicate: #<issue_iid>)`.

---

## Description Length Limits

GitLab issue descriptions support up to **1,048,576 characters** (1 MB).
Generated descriptions are unlikely to exceed this limit, but truncate task
tables to 50 rows if a phase has unusually many tasks.
