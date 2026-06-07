#!/usr/bin/env bash
# create_gitlab_issues.sh
# Helper script for the create-gitlab-issues-from-implementation-plan skill.
#
# Usage:
#   bash create_gitlab_issues.sh \
#     --plan path/to/plan.md \
#     [--repo OWNER/REPO] \
#     [--milestone "Sprint 1"] \
#     [--labels "feature,planning"] \
#     [--assignees "alice,bob"] \
#     [--confidential] \
#     [--dry-run]
#
# Requirements:
#   - glab CLI installed and authenticated (glab auth login)
#   - python3 available on PATH for JSON parsing
#
# Output:
#   Prints a Markdown creation report to stdout.
#   Exit code 0 if all issues were created or skipped.
#   Exit code 1 if any issue failed to create.

set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
PLAN_FILE=""
REPO_FLAG=""
MILESTONE=""
LABELS=""
ASSIGNEES=""
CONFIDENTIAL=false
DRY_RUN=false

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)       PLAN_FILE="$2";  shift 2 ;;
    --repo)       REPO_FLAG="$2";  shift 2 ;;
    --milestone)  MILESTONE="$2";  shift 2 ;;
    --labels)     LABELS="$2";     shift 2 ;;
    --assignees)  ASSIGNEES="$2";  shift 2 ;;
    --confidential) CONFIDENTIAL=true; shift ;;
    --dry-run)    DRY_RUN=true;    shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PLAN_FILE" ]]; then
  echo "Error: --plan is required." >&2
  exit 1
fi

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "Error: Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

# ─── Preflight ────────────────────────────────────────────────────────────────
if ! command -v glab &>/dev/null; then
  echo "Error: glab is not installed. Install with: brew install glab" >&2
  echo "       or see: https://gitlab.com/gitlab-org/cli" >&2
  exit 1
fi

if ! glab auth status &>/dev/null; then
  echo "Error: glab is not authenticated. Run: glab auth login" >&2
  exit 1
fi

if [[ -n "$REPO_FLAG" ]]; then
  if ! glab repo view --repo "$REPO_FLAG" &>/dev/null; then
    echo "Error: GitLab project '$REPO_FLAG' is not accessible." >&2
    exit 1
  fi
fi

# ─── Parse plan file ──────────────────────────────────────────────────────────
# Extract plan goal from front matter
PLAN_GOAL=$(awk '/^---/{fm++; next} fm==1 && /^goal:/{sub(/^goal: */,""); print; exit}' "$PLAN_FILE")
PLAN_VERSION=$(awk '/^---/{fm++; next} fm==1 && /^version:/{sub(/^version: */,""); print; exit}' "$PLAN_FILE")
PLAN_STATUS=$(awk '/^---/{fm++; next} fm==1 && /^status:/{sub(/^status: */,""); gsub(/['"'"']*/,""); print; exit}' "$PLAN_FILE")

# Abbreviate plan goal to 50 chars
GOAL_ABBREV="${PLAN_GOAL:0:50}"
if [[ ${#PLAN_GOAL} -gt 50 ]]; then GOAL_ABBREV="${GOAL_ABBREV}..."; fi

# Extract phase headings and their GOAL lines
mapfile -t PHASE_LINES < <(grep -n "^### Implementation Phase" "$PLAN_FILE" | awk -F: '{print $1}')
mapfile -t GOAL_LINES  < <(grep -n "^- GOAL-" "$PLAN_FILE" | awk -F: '{print $1}')
mapfile -t GOAL_TEXTS  < <(grep "^- GOAL-" "$PLAN_FILE" | sed 's/^- GOAL-[0-9]*: *//')

PHASE_COUNT=${#PHASE_LINES[@]}

# ─── Report header ────────────────────────────────────────────────────────────
echo ""
echo "## GitLab Issue Creation Report"
echo ""
echo "**Plan**: \`${PLAN_FILE}\`"
echo "**Project**: ${REPO_FLAG:-"current repo"}"
echo "**Milestone**: ${MILESTONE:-—}"
echo "**Labels**: ${LABELS:-—}"
echo "**Assignees**: ${ASSIGNEES:-—}"
echo "**Dry Run**: ${DRY_RUN}"
echo ""
echo "| # | Phase | Issue Title | Status | URL |"
echo "|---|---|---|---|---|"

FAILED=0

for (( i=0; i<PHASE_COUNT; i++ )); do
  PHASE_NUM=$(( i + 1 ))
  GOAL_TEXT="${GOAL_TEXTS[$i]:-Phase ${PHASE_NUM} goal not found}"

  # Build title
  TITLE="[${GOAL_ABBREV}] — Phase ${PHASE_NUM}: ${GOAL_TEXT}"
  # Truncate to 255 chars
  if [[ ${#TITLE} -gt 255 ]]; then TITLE="${TITLE:0:252}..."; fi

  SEARCH_PREFIX="[${GOAL_ABBREV}] — Phase ${PHASE_NUM}:"

  # ── Dedup check ──────────────────────────────────────────────────────────
  REPO_ARG=()
  if [[ -n "$REPO_FLAG" ]]; then REPO_ARG=(--repo "$REPO_FLAG"); fi

  EXISTING_COUNT=0
  EXISTING_URL=""
  if EXISTING_JSON=$(glab issue list "${REPO_ARG[@]}" \
        --search "$SEARCH_PREFIX" \
        --state opened \
        --output json 2>/dev/null); then
    EXISTING_COUNT=$(echo "$EXISTING_JSON" | python3 -c "import sys,json; issues=json.load(sys.stdin); print(len(issues))" 2>/dev/null || echo "0")
    if [[ "$EXISTING_COUNT" -gt 0 ]]; then
      EXISTING_URL=$(echo "$EXISTING_JSON" | python3 -c "import sys,json; issues=json.load(sys.stdin); print(issues[0].get('web_url',''))" 2>/dev/null || echo "")
    fi
  fi

  if [[ "$EXISTING_COUNT" -gt 0 ]]; then
    echo "| ${PHASE_NUM} | Phase ${PHASE_NUM} | ${TITLE} | ⏭️ Skipped (duplicate) | ${EXISTING_URL} |"
    continue
  fi

  # ── Build description ─────────────────────────────────────────────────────
  DESCRIPTION=$(cat <<EOF
## Overview

> This issue was auto-generated from the implementation plan: \`${PLAN_FILE}\`
> Plan goal: **${PLAN_GOAL}**
> Plan status: **${PLAN_STATUS}**
> Plan version: \`${PLAN_VERSION}\`

---

## Phase Goal

${GOAL_TEXT}

---

## Traceability

- **Plan file**: \`${PLAN_FILE}\`
- **Phase**: Phase ${PHASE_NUM}
- **Plan goal**: ${PLAN_GOAL}

---

*Created by \`create-gitlab-issues-from-implementation-plan\` skill via \`glab\` CLI.*
EOF
)

  # ── Build glab command ────────────────────────────────────────────────────
  CMD=(glab issue create)
  [[ -n "$REPO_FLAG" ]]   && CMD+=(--repo "$REPO_FLAG")
  CMD+=(--title "$TITLE")
  CMD+=(--description "$DESCRIPTION")
  [[ -n "$LABELS" ]]      && CMD+=(--label "$LABELS")
  [[ -n "$MILESTONE" ]]   && CMD+=(--milestone "$MILESTONE")
  [[ -n "$ASSIGNEES" ]]   && CMD+=(--assignee "$ASSIGNEES")
  [[ "$CONFIDENTIAL" == true ]] && CMD+=(--confidential)

  # ── Execute or dry-run ────────────────────────────────────────────────────
  if [[ "$DRY_RUN" == true ]]; then
    echo "| ${PHASE_NUM} | Phase ${PHASE_NUM} | ${TITLE} | 🔎 Dry Run | — |"
    echo ""
    echo "[DRY RUN] ${CMD[*]}"
    echo ""
  else
    if OUTPUT=$("${CMD[@]}" 2>&1); then
      URL=$(echo "$OUTPUT" | grep -oE 'https?://[^ ]+' | head -1 || echo "—")
      echo "| ${PHASE_NUM} | Phase ${PHASE_NUM} | ${TITLE} | ✅ Created | ${URL} |"
    else
      echo "| ${PHASE_NUM} | Phase ${PHASE_NUM} | ${TITLE} | ❌ Failed: ${OUTPUT} | — |"
      FAILED=$(( FAILED + 1 ))
    fi
  fi
done

echo ""
if [[ "$FAILED" -gt 0 ]]; then
  echo "> ⚠️ ${FAILED} issue(s) failed to create. Review errors above."
  exit 1
else
  echo "> ✅ All phases processed successfully."
  exit 0
fi
