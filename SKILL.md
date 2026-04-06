---
name: smart-commit
description: Atomic git commits grouped by feature/layer — detects commit style from history, skips build artifacts, never uses git add -A
---

# Smart Commit

Automatically stage and commit all pending changes as atomic commits grouped by architectural layer or feature. Detects the project's existing commit message convention from git history.

## Trigger
Use when the user says any of:
- `/smart-commit`
- "commit based on features"
- "commit by layer"
- "atomic commits"
- "commit the changes"

## Workflow

### Step 1 — Inspect repo state
Run these in parallel:
```bash
git log --oneline -8          # detect commit style/convention
git status --short            # list all changed and untracked files
git diff --stat               # understand scope of modifications
```

### Step 2 — Identify files to skip
Never stage these — skip silently:
- Build artifacts: `tsconfig.tsbuildinfo`, `*.tsbuildinfo`, `.next/`, `dist/`, `build/`
- Local tool configs: `.omc/`, `.cursor/`, `.vscode/` (unless user explicitly asks)
- Secrets: `.env*`
- OS noise: `.DS_Store`, `Thumbs.db`
- Lock file changes unless dependencies actually changed: `package-lock.json`, `yarn.lock`

### Step 3 — Group remaining files into atomic commits

Group by this priority order:

| Group | Examples |
|---|---|
| **Config / infra** | `.gitignore`, `next.config.*`, `tsconfig.json`, `tailwind.config.*` |
| **Docs** | `CLAUDE.md`, `README.md`, `*.md` |
| **DB / schema** | `schema.sql`, `migrations/`, `prisma/` |
| **Lib / utilities** | `lib/**`, `utils/**`, `hooks/**` |
| **API routes** | `app/api/**`, `pages/api/**` |
| **UI components** | `components/**`, `app/**/page.tsx`, `app/**/layout.tsx` |
| **Tests** | `**/*.test.*`, `**/*.spec.*`, `__tests__/` |

If a single feature spans multiple groups (e.g., a new `lib/feeCalculation.ts` + `app/api/invoice/route.ts` + `components/InvoiceCard.tsx`), use judgment:
- ≤ 3 files total → one commit for the whole feature
- > 3 files → split by layer, each commit named after the layer

### Step 4 — Detect commit message convention

Read the git log output from Step 1 and match the style:
- `feat(scope): description` → conventional commits
- `[TICKET-123] description` → ticket-prefixed
- `feat: description` (no scope) → conventional without scope
- `Add description` / `Fix description` → imperative plain
- Default if ambiguous: `type(scope): short description`

### Step 5 — Stage and commit each group

For each group:
```bash
git add <file1> <file2> ...   # explicit files only, NEVER git add . or git add -A
git commit -m "$(cat <<'EOF'
<type(scope): concise subject line>

<optional body: what changed and why, if non-obvious>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### Step 6 — Report
After all commits, run:
```bash
git log --oneline -10
git status
```
Show the user the new commits and confirm working tree is clean.

## Rules
- **Never** use `git add .` or `git add -A`
- **Never** commit `.env*` files
- **Never** amend existing commits
- If `git status` is already clean, tell the user and stop
- If a file's group is ambiguous, prefer fewer larger commits over many tiny ones
- Commit message subject line: ≤ 72 characters
- Always add `Co-Authored-By` trailer

## Success criteria
- `git status` shows clean working tree after all commits
- Each commit contains only logically related files
- Commit messages match the project's existing convention
- No build artifacts or secrets in any commit
