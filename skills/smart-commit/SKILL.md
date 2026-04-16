---
name: smart-commit
description: Atomic git commits grouped by feature/layer — detects commit style from history, skips build artifacts, never uses git add -A. Use when the user says "/smart-commit", "commit based on features", "commit by layer", "atomic commits", or "commit the changes".
version: 1.0.0
---

# Smart Commit

Automatically stage and commit all pending changes as atomic commits grouped by architectural layer or feature. Detects the project's existing commit message convention from git history.

## When to activate

Use this skill when the user says:
- `/smart-commit`
- "commit based on features"
- "commit by layer"
- "atomic commits"
- "commit the changes"

## Workflow

### Step 1 — Inspect repo state
Run in parallel:
```bash
git log --oneline -8
git status --short
git diff --stat
```

### Step 2 — Identify files to skip
Never stage:
- Build artifacts: `tsconfig.tsbuildinfo`, `.next/`, `dist/`, `build/`
- Local tool configs: `.omc/`, `.cursor/`, `.vscode/`
- Secrets: `.env*`
- OS noise: `.DS_Store`, `Thumbs.db`
- Lock files unless dependencies changed: `package-lock.json`, `yarn.lock`

### Step 3 — Group remaining files into atomic commits

| Group | Examples |
|---|---|
| **Config / infra** | `.gitignore`, `next.config.*`, `tsconfig.json`, `tailwind.config.*` |
| **Docs** | `CLAUDE.md`, `README.md`, `*.md` |
| **DB / schema** | `schema.sql`, `migrations/`, `prisma/` |
| **Lib / utilities** | `lib/**`, `utils/**`, `hooks/**` |
| **API routes** | `app/api/**`, `pages/api/**` |
| **UI components** | `components/**`, `app/**/page.tsx`, `app/**/layout.tsx` |
| **Tests** | `**/*.test.*`, `**/*.spec.*`, `__tests__/` |

≤ 3 files spanning groups → one commit. > 3 files → split by layer.

### Step 4 — Detect commit convention
- `feat(scope): …` → conventional commits
- `[TICKET-123] …` → ticket-prefixed
- `Add …` / `Fix …` → imperative plain
- Default: `type(scope): short description`

### Step 5 — Stage and commit each group
```bash
git add <file1> <file2> ...   # explicit files only, NEVER git add . or git add -A
git commit -m "..."
```
Always add `Co-Authored-By` trailer.

### Step 6 — Report
Show `git log --oneline -10` and confirm working tree is clean.

## Rules
- Never use `git add .` or `git add -A`
- Never commit `.env*` files
- Never amend existing commits
- Subject line ≤ 72 characters
