---
name: commit-staged-changes
description: 'Tool for creating safe, conventional-commit-style git commits from staged changes. Use when files are already staged and you want to generate a commit message, verify the diff, and commit. Supports auto-detection of type/scope/subject, human-in-the-loop confirmation, and co-author attribution.'
license: 'MIT'
---

# Commit Staged Changes

This skill helps you create high-quality, standardized git commits following the Conventional Commits specification. It focus on committing what is already staged, ensuring a clean and intentional commit history.

## When to Use This Skill

- When you have files staged (`git add`) and are ready to commit.
- When you want to ensure your commit message follows the `feat:`, `fix:`, `docs:`, etc., convention.
- When you want to automatically generate a semantic commit message based on the staged diff.
- When you need to add co-authors to a commit.

## Workflow

### 1. Verify Staged Files
Check what is currently in the staging area to ensure no secrets or unintended files are included.
```bash
git status --porcelain
git diff --staged --stat
```

### 2. Generate Semantic Commit Message
Analyze the staged diff to propose a message in the format:
`<type>([optional scope]): <description>`

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes that affect the build system or external dependencies
- `ci`: Changes to CI configuration files and scripts
- `chore`: Other changes that don't modify src or test files

**Description rules:**
- Use the imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No dot (.) at the end
- Separate the subject and body of the commit message with a blank line.

### 3. Confirmation (Safety First)
Before executing the commit, present the:
1. List of staged files.
2. A summary of the changes.
3. The proposed commit message.

### 4. Execute Commit
Once approved, run the commit command. Avoid using `-n` or `--no-verify` to ensure git hooks are executed.

Use multiple `-m` flags to properly separate the subject and body — git inserts a blank line between them automatically:

```bash
git commit -m "<subject>" -m "<body>"
```

## Output Format

Always respond in **Markdown format**:
- Use headers (`##`, `###`) to separate sections (staged files, summary, proposed message).
- Use code blocks (` ``` `) for the proposed commit message and any shell commands.
- Use bullet lists for staged files and change summaries.

## Gotchas

- **Secrets**: Always scan the diff for API keys, passwords, or PII before committing.
- **Large Commits**: If the diff is too large, suggest breaking it down into smaller, logical commits by un-staging some files.
- **Hooks**: Never bypass pre-commit hooks unless explicitly instructed by the user.

## Example Prompts

- "Commit my staged changes using conventional commits."
- "Suggest a commit message for the currently staged files."
- "Commit staged changes and add @user as a co-author."
