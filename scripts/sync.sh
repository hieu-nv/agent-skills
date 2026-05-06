#!/usr/bin/env bash
set -euo pipefail

# Usage: ./sync.sh [-f]
#   -f    Force copy, overwrite existing files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source directories (searched in order, first match wins)
SOURCE_DIRS=(
    "$REPO_ROOT/anthropics-skills"
    "$REPO_ROOT/google-skills"
    "$REPO_ROOT/awesome-copilot"
    "$REPO_ROOT/antigravity-awesome-skills"
    "$REPO_ROOT"
)

ANTIGRAVITY_DIR="$HOME/.gemini/antigravity"
COPILOT_DIR="$HOME/.copilot"
FORCE=false

# Parse arguments
while getopts "f" opt; do
    case $opt in
        f) FORCE=true ;;
        *) echo "Usage: $0 [-f]" >&2; exit 1 ;;
    esac
done

# ------------------------------------------------------------
# Skills — rescanned for this project stack and upstream availability
# ------------------------------------------------------------
COPY_SKILLS=(
    # General engineering
    "clean-code"
    "code-review-checklist"
    "code-review-excellence"
    "conventional-commit"
    "create-implementation-plan"
    "create-readme"
    "gh-cli"
    "git-commit"
    "git-flow-branch-creator"
    "github-copilot-starter"
    "github-issues"
    "github-release"
    "refactor"
    "refactor-plan"
    "review-and-refactor"
    "tdd-workflow"
    "test-driven-development"
    "create-github-action-workflow-specification"
    "create-github-issue-feature-from-specification"
    "create-github-issues-feature-from-implementation-plan"
    "create-github-issues-for-unmet-specification-requirements"
    "create-github-pull-request-from-specification"
    "commit-staged-changes"
    "gh-pr-automation"
)

# ------------------------------------------------------------
# Agents — rescanned for this project stack
# ------------------------------------------------------------
COPY_AGENTS=(
    # Power modes
    "Thinking-Beast-Mode.agent.md"
    "Ultimate-Transparent-Thinking-Beast-Mode.agent.md"
    # Architecture & design
    "api-architect.agent.md"
    "context-architect.agent.md"
    "implementation-plan.agent.md"
    "principal-software-engineer.agent.md"
    "se-system-architecture-reviewer.agent.md"
    # Development & review
    "debug.agent.md"
    "openapi-to-application.agent.md"
    "python-mcp-expert.agent.md"
    "se-responsible-ai-code.agent.md"
    "se-security-reviewer.agent.md"
    "se-technical-writer.agent.md"
    # TDD workflow
    "tdd-red.agent.md"
    "tdd-green.agent.md"
    "tdd-refactor.agent.md"
    # Polyglot test pipeline
    "playwright-tester.agent.md"
    "polyglot-test-builder.agent.md"
    "polyglot-test-fixer.agent.md"
    "polyglot-test-generator.agent.md"
    "polyglot-test-implementer.agent.md"
    "polyglot-test-linter.agent.md"
    "polyglot-test-planner.agent.md"
    "polyglot-test-researcher.agent.md"
    "polyglot-test-tester.agent.md"
    # Research & planning
    "devops-expert.agent.md"
    "task-researcher.agent.md"
)

# ------------------------------------------------------------
# Instructions — rescanned from upstream + required by this repo
# NOTE: security-and-owasp and fastapi-backend are LOCAL-ONLY
# ------------------------------------------------------------
COPY_INSTRUCTIONS=(
    # Agent/copilot meta
    "agent-safety.instructions.md"
    "agent-skills.instructions.md"
    "agents.instructions.md"
    # Code quality
    "code-review-generic.instructions.md"
    "context-engineering.instructions.md"
    "performance-optimization.instructions.md"
    "self-explanatory-code-commenting.instructions.md"
    # Python / FastAPI
    "playwright-python.instructions.md"
    "python-mcp-server.instructions.md"
    # DevOps / infra
    "containerization-docker-best-practices.instructions.md"
    "devops-core-principles.instructions.md"
    "github-actions-ci-cd-best-practices.instructions.md"
    "shell.instructions.md"
)

# ------------------------------------------------------------
# Workflows
# ------------------------------------------------------------
COPY_WORKFLOWS=(
    "daily-issues-report.md"
    "relevance-check.md"
)

# ------------------------------------------------------------
# Command hooks (operational automation)
# ------------------------------------------------------------
COPY_HOOKS=(
    "dependency-license-checker"
    "governance-audit"
    "secrets-scanner"
    "session-auto-commit"
    "session-logger"
    "tool-guardian"
)

# ------------------------------------------------------------
# Helper: copy_items <src_subdir> <dest_subdir> <items...>
# ------------------------------------------------------------
copy_items() {
    local src_subdir="$1"
    local dest_subdir="$2"
    shift 2
    local items=("$@")

    echo "  Syncing to $ANTIGRAVITY_DIR/$dest_subdir..."
    sync_to_target "$src_subdir" $ANTIGRAVITY_DIR "$dest_subdir" "${items[@]}"

    echo "  Syncing to $COPILOT_DIR/$dest_subdir..."
    sync_to_target "$src_subdir" $COPILOT_DIR "$dest_subdir" "${items[@]}"

    # echo "  Syncing to .gemini/$dest_subdir..."
    # sync_to_target "$src_subdir" "$GEMINI_DIR" "$dest_subdir" "${items[@]}"
    # echo ""
}

# ------------------------------------------------------------
# Internal Helper: sync_to_target <src_subdir> <base_dest_dir> <dest_subdir> <items...>
# ------------------------------------------------------------
sync_to_target() {
    local src_subdir="$1"
    local base_dest_dir="$2"
    local dest_subdir="$3"
    shift 3
    local items=("$@")

    local dest_path="$base_dest_dir/$dest_subdir"
    mkdir -p $dest_path

    local copied=0 skipped=0 notfound=0

    for item in "${items[@]}"; do
        local dest_item="$dest_path/$item"
        local source_item=""

        for src_dir in "${SOURCE_DIRS[@]}"; do
            local candidate="$src_dir/$src_subdir/$item"
            if [[ -e "$candidate" ]]; then
                source_item="$candidate"
                break
            fi
            local candidate2="$src_dir/$item"
            if [[ -e "$candidate2" ]]; then
                source_item="$candidate2"
                break
            fi
        done

        if [[ -z "$source_item" ]]; then
            if [[ -e "$dest_item" ]]; then
                rm -rf "$dest_item"
                echo "    - Removed:   $item (not found upstream)"
            else
                echo "    X Not found: $item"
            fi
            ((notfound++)) || true
            continue
        fi

        if [[ -e "$dest_item" && "$FORCE" == false ]]; then
            echo "    = Exists:    $item (use -f to overwrite)"
            ((skipped++)) || true
            continue
        fi

        [[ -e "$dest_item" ]] && rm -rf "$dest_item"
        echo $dest_item
        cp -r "$source_item" $dest_item
        echo "    + Copied:    $item"
        ((copied++)) || true
    done

    echo "    -> Copied: $copied | Skipped: $skipped | Not found: $notfound"
}

# ------------------------------------------------------------
# Guard: at least one source directory must exist
# ------------------------------------------------------------
found_source=false
for src_dir in "${SOURCE_DIRS[@]}"; do
    if [[ -d "$src_dir" ]]; then
        found_source=true
        break
    fi
done

if [[ "$found_source" == false ]]; then
    echo "Error: No source directories found:"
    for src_dir in "${SOURCE_DIRS[@]}"; do echo "  - $src_dir"; done
    exit 1
fi

echo ""

echo "=================================================="
echo "  Targets: $ANTIGRAVITY_DIR | $COPILOT_DIR"
echo "  Force:   $FORCE"
echo "=================================================="
echo ""

echo "SKILLS -> skills/"
copy_items "skills" "skills" "${COPY_SKILLS[@]}"

# echo "AGENTS -> agents/"
# copy_items "agents" "agents" "${COPY_AGENTS[@]}"

# echo "INSTRUCTIONS -> instructions/"
# copy_items "instructions" "instructions" "${COPY_INSTRUCTIONS[@]}"

# echo "WORKFLOWS -> workflows/"
# copy_items "workflows" "workflows" "${COPY_WORKFLOWS[@]}"

# echo "HOOKS -> hooks/"
# copy_items "hooks" "hooks" "${COPY_HOOKS[@]}"

echo "=================================================="
echo "Sync complete!"
echo "=================================================="
