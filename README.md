# Agent Skills Hub

A curated monorepo of AI agent skills, instructions, and agents aggregated from the best community and official sources. Use the sync script to keep your local AI coding assistant configurations up to date from a single place.

> [!NOTE]
> All sub-collections are managed as Git submodules, so you pull from the authoritative upstream sources and can update them independently.

## What's inside

| Collection | Source | Description |
|---|---|---|
| [awesome-copilot](awesome-copilot/) | [github/awesome-copilot](https://github.com/github/awesome-copilot) | Community agents, instructions, skills, hooks, and workflows for GitHub Copilot |
| [antigravity-awesome-skills](antigravity-awesome-skills/) | [sickn33/antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) | 1,445+ installable skills for Claude Code, Cursor, Gemini CLI, Copilot, and more |
| [anthropics-skills](anthropics-skills/) | [anthropics/skills](https://github.com/anthropics/skills) | Official Anthropic skills for Claude, including document creation and enterprise workflows |
| [google-skills](google-skills/) | [google/skills](https://github.com/google/skills) | Official Google Cloud skills covering GKE, BigQuery, Cloud Run, Firebase, and more |
| [gitlab-cli-skills](gitlab-cli-skills/) | [vince-winkintel/gitlab-cli-skills](https://github.com/vince-winkintel/gitlab-cli-skills) | Skills for GitLab CLI workflows |
| [skills/](skills/) | local | Custom personal skills not found upstream |

## Syncing skills locally

The `sync.sh` script copies a curated selection of skills to your local AI tool configuration directories:

- `~/.copilot/skills/` — picked up by GitHub Copilot
- `~/.gemini/antigravity/skills/` — picked up by Antigravity and Gemini CLI

```bash
# First time: copy skills to both targets
./scripts/sync.sh

# Overwrite existing files (force update)
./scripts/sync.sh -f
```

The script searches sub-collections in order (`anthropics-skills` → `google-skills` → `awesome-copilot` → `antigravity-awesome-skills` → root), and uses the first match found for each skill. Skills not present in any source are removed from the destination.

> [!TIP]
> Edit `COPY_SKILLS`, `COPY_AGENTS`, `COPY_INSTRUCTIONS`, `COPY_WORKFLOWS`, and `COPY_HOOKS` at the top of `scripts/sync.sh` to customize what gets synced.

## Keeping submodules up to date

```bash
# Initialize and clone all submodules on first checkout
git submodule update --init --recursive

# Pull the latest upstream changes for all submodules
git submodule update --remote --merge
```

## Adding a new collection

```bash
git submodule add <repository-url> <local-folder-name>
```

Then add the new folder to the `SOURCE_DIRS` list in `scripts/sync.sh` and pick the specific skills or agents you want to sync.

## Resources

- [agentskills.io](https://agentskills.io) — The Agent Skills specification and ecosystem hub
- [awesome-copilot website](https://awesome-copilot.github.com) — Browse the full Copilot collection with search and filtering
- [Antigravity catalog](https://github.com/sickn33/antigravity-awesome-skills) — Full catalog of 1,445+ skills
- [Anthropic Agent Skills docs](https://support.claude.com/en/articles/12512176-what-are-skills) — Learn how skills work in Claude
