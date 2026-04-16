---
allowed-tools: Bash(git log:*), Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*)
description: Atomic git commits grouped by feature/layer, auto-detects commit style
---

## Context

- Recent commits (for style detection): !`git log --oneline -8`
- Changed files: !`git status --short`
- Diff stats: !`git diff --stat`

## Your task

Automatically stage and commit all pending changes as atomic commits grouped by architectural layer or feature.

### Step 1 — Check if there's anything to commit
If `git status` is already clean, tell the user and stop.

### Step 2 — Identify files to SKIP (never stage these)
- Build artifacts: `tsconfig.tsbuildinfo`, `*.tsbuildinfo`, `.next/`, `dist/`, `build/`
- Local tool configs: `.omc/`, `.cursor/`, `.vscode/`
- Secrets: `.env*`
- OS noise: `.DS_Store`, `Thumbs.db`
- Lock files (`package-lock.json`, `yarn.lock`) unless dependencies actually changed

### Step 3 — Group remaining files into atomic commits

| Group | File patterns |
|---|---|
| **Config / infra** | `.gitignore`, `next.config.*`, `tsconfig.json`, `tailwind.config.*` |
| **Docs** | `CLAUDE.md`, `README.md`, `*.md` |
| **DB / schema** | `schema.sql`, `migrations/`, `prisma/` |
| **Lib / utilities** | `lib/**`, `utils/**`, `hooks/**` |
| **API routes** | `app/api/**`, `pages/api/**` |
| **UI components** | `components/**`, `app/**/page.tsx`, `app/**/layout.tsx` |
| **Tests** | `**/*.test.*`, `**/*.spec.*`, `__tests__/` |

If a single feature spans multiple groups:
- ≤ 3 files total → one commit for the whole feature
- > 3 files → split by layer, each commit named after the layer

### Step 4 — Detect commit message convention from git log

- `feat(scope): description` → conventional commits
- `[TICKET-123] description` → ticket-prefixed
- `feat: description` → conventional without scope
- `Add …` / `Fix …` → imperative plain
- Default: `type(scope): short description`

### Step 5 — Stage and commit each group

For each group, use explicit file paths only — **never** `git add .` or `git add -A`:
```bash
git add <file1> <file2> ...
git commit -m "$(cat <<'EOF'
<type(scope): concise subject line, ≤72 chars>

<optional body: what changed and why, if non-obvious>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

Rules:
- **Never** commit `.env*` files
- **Never** amend existing commits
- Subject line ≤ 72 characters

### Step 6 — Report results

Run `git log --oneline -10` and `git status`, show the user the new commits and confirm working tree is clean.
