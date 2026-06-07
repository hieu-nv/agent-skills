---
name: create-gitlab-merge-request-from-current-branch
description: 'Use this skill when you need to create a GitLab Merge Request (MR). It will automatically generate a semantic title, a detailed description from the git diff, and apply appropriate labels.'
---

# Create a GitLab Merge Request from Current Branch

This skill automates the creation of high-quality GitLab Merge Requests (MRs) using the `glab` CLI. It ensures every MR has a clear summary, a categorized list of changes, and appropriate metadata.

## When to Use This Skill

- When you have finished committing your work and want to create an MR in GitLab.
- When you want to target a specific base/target branch (e.g., `develop` or `main`).
- When you want to automatically generate an MR description based on the actual code changes.
- When you need to apply standardized labels, assignees, or reviewers.

## Workflow

### 1. Gather Context
Identify the delta between the current branch and the target branch.
```bash
# Get current branch
git branch --show-current

# Summary of changes
git log <target-branch>..HEAD --oneline
git diff <target-branch>..HEAD --stat
```

### 2. Craft the MR Content
Analyze the diff to generate:
- **Title**: Follows Conventional Commits (e.g., `feat: add user auth`).
- **Description**: 
    - **Summary**: 1-2 sentence overview of the goal.
    - **Changes**: Bulleted list of key technical/functional changes.
- **Labeling**: Select from relevant project labels (e.g., `bug`, `enhancement`, `refactor`, `chore`, `documentation`).

### 3. Execute MR Creation
Ensure your branch is pushed first (`glab mr create` can also do this with `--push` if needed, but it is often safer to push explicitly).
Run the command directly without opening the browser unless requested. Use `--yes` to skip submission confirmation prompts.

```bash
glab mr create \
  --target-branch <target-branch> \
  --source-branch <current-branch> \
  --title "<type>(<scope>): <short summary>" \
  --description "<crafted description>" \
  --label "<label>" \
  --yes
```

## Gotchas

- **Uncommitted Changes**: Ensure the working directory is clean before creating the MR, and that your branch is pushed (or use the `--push` flag with `glab mr create`).
- **Target Branch**: Defaults to the repository's default branch (usually `main` or `master`) unless specified otherwise.
- **Labels**: Ensure the labels exist in the GitLab project.
- **Authentication**: Make sure you are authenticated with GitLab via `glab auth status` before running the command.

## Example Prompts

- "Create a GitLab MR from this branch to main."
- "Open a merge request to develop with a detailed description of my changes."
- "Create a draft MR to master and label it as refactor."
