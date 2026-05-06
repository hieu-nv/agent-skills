---
name: gh-pr-automation
description: 'Automate GitHub Pull Request creation using GitHub CLI (gh). Use when asked to create a PR, submit code for review, or merge a feature branch. Automatically crafts semantic titles, detailed descriptions from git diffs, and applies appropriate labels (bug, enhancement, refactor, etc.).'
license: 'MIT'
---

# GitHub PR Automation

This skill automates the creation of high-quality GitHub Pull Requests using the `gh` CLI. it ensures every PR has a clear summary, a categorized list of changes, and appropriate metadata.

## When to Use This Skill

- When you have finished committing your work and want to create a PR.
- When you want to target a specific base branch (e.g., `develop` or `main`).
- When you want to automatically generate a PR description based on the actual code changes.
- When you need to apply standardized labels to help reviewers.

## Workflow

### 1. Gather Context
Identify the delta between the current branch and the target base branch.
```bash
# Get current branch
git branch --show-current

# Summary of changes
git log <base-branch>..HEAD --oneline
git diff <base-branch>..HEAD --stat
```

### 2. Craft the PR Content
Analyze the diff to generate:
- **Title**: Follows Conventional Commits (e.g., `feat: add user auth`).
- **Description**: 
    - **Summary**: 1-2 sentence overview of the goal.
    - **Changes**: Bulleted list of key technical/functional changes.
- **Labeling**: Select from `bug`, `enhancement`, `refactor`, `chore`, or `documentation`.

### 3. Execute PR Creation
Run the command directly without opening the browser unless requested.

```bash
gh pr create \
  --base <base-branch> \
  --head <current-branch> \
  --title "<type>: <short summary>" \
  --body "<crafted description>" \
  --label "<label>"
```

## Gotchas

- **Uncommitted Changes**: Ensure the working directory is clean or changes are pushed before creating the PR.
- **Base Branch**: Defaults to `develop` in this workspace unless specified otherwise.
- **Labels**: Ensure the labels exist in the repository or `gh` will fail.

## Example Prompts

- "Create a PR from this branch to develop."
- "Open a PR for my last changes with a detailed summary."
- "Create a PR to main and label it as a bug fix."
