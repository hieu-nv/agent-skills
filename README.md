# Agent Skills Hub

A collection of custom, production-grade AI agent skills to automate software engineering workflows. These skills are designed for modern AI coding assistants (like **Antigravity**, **Claude Code**, and **GitHub Copilot**) that support local skill execution.

> [!NOTE]
> These skills leverage official command-line interfaces (`gh`, `glab`) to perform actions directly within your local workspace, maintaining security and speed.

## Available Skills

| Skill Name | Target CLI | Description |
| :--- | :--- | :--- |
| [`create-github-pull-request-from-current-branch`](skills/create-github-pull-request-from-current-branch/) | `gh` | Automates PR creation with Conventional Commits titles, semantic change summaries, and labels. |
| [`create-gitlab-issues-from-implementation-plan`](skills/create-gitlab-issues-from-implementation-plan/) | `glab` | Parses a markdown implementation plan and batch-creates issues on GitLab (deduplicating existing ones). |
| [`create-gitlab-merge-request-from-current-branch`](skills/create-gitlab-merge-request-from-current-branch/) | `glab` | Automates GitLab MR creation with structured descriptions, change summaries, and labels. |

---

## Installation & Setup

To make these skills available to your AI coding assistant, copy or symlink their directories into your local tools configuration folder.

### Configuration Targets
- **Antigravity / Gemini CLI**: `~/.gemini/config/skills/`
- **GitHub Copilot**: `~/.copilot/skills/`

### 1. Manual Copy
You can copy the specific skills you want directly to the target directory:

```bash
# Ensure target directories exist
mkdir -p ~/.gemini/config/skills
mkdir -p ~/.copilot/skills

# Example: Copy the GitHub PR creation skill
cp -R skills/create-github-pull-request-from-current-branch ~/.gemini/config/skills/
cp -R skills/create-github-pull-request-from-current-branch ~/.copilot/skills/
```

### 2. Symlink (Recommended)
Using symlinks ensures that any updates to this repository are immediately reflected in your AI tools without recopying.

```bash
# Symlink all skills to Antigravity
for skill in skills/*; do
  ln -sf "$(pwd)/$skill" "$HOME/.gemini/config/skills/$(basename "$skill")"
done
```

> [!TIP]
> After installing a skill, verify your AI coding assistant has detected it. In Antigravity, you can verify by checking if the skill is listed in your active skills context or by prompting: *"Can you use the create-github-pull-request-from-current-branch skill?"*

---

## Prerequisites

Ensure you have the required CLI tools installed and authenticated on your machine:

- **GitHub CLI**: `brew install gh` & `gh auth login`
- **GitLab CLI**: `brew install glab` & `glab auth login`

