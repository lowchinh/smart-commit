# Smart Commit Instructions

When asked to "smart commit", "commit by layer", "commit based on features", "atomic commits", or "commit the changes", follow this workflow.

## Workflow

### Step 1 — Inspect repo state
```bash
git log --oneline -8    # detect commit style
git status --short      # list changed files
git diff --stat         # understand scope
```

### Step 2 — Never stage these files
- Build artifacts: `tsconfig.tsbuildinfo`, `*.tsbuildinfo`, `.next/`, `dist/`, `build/`
- Tool configs: `.omc/`, `.cursor/`, `.vscode/`
- Secrets: `.env*`
- OS noise: `.DS_Store`, `Thumbs.db`
- Lock files: `package-lock.json`, `yarn.lock` (unless deps changed)

### Step 3 — Group remaining files by layer

| Group | Patterns |
|---|---|
| Config / infra | `.gitignore`, `next.config.*`, `tsconfig.json`, `tailwind.config.*` |
| Docs | `README.md`, `CLAUDE.md`, `*.md` |
| DB / schema | `schema.sql`, `migrations/`, `prisma/` |
| Lib / utilities | `lib/**`, `utils/**`, `hooks/**` |
| API routes | `app/api/**`, `pages/api/**` |
| UI components | `components/**`, `app/**/page.tsx`, `app/**/layout.tsx` |
| Tests | `**/*.test.*`, `**/*.spec.*`, `__tests__/` |

- ≤ 3 files → one commit for the feature
- > 3 files → one commit per layer

### Step 4 — Detect commit message style from git log
- `feat(scope): …` → conventional
- `[TICKET-123] …` → ticket-prefixed
- `Add …` / `Fix …` → imperative
- Default: `type(scope): description`

### Step 5 — Commit each group
```bash
git add <explicit files only>    # NEVER git add . or git add -A
git commit -m "<message>"
```

- Subject line ≤ 72 chars
- Never commit `.env*`
- Never amend existing commits

### Step 6 — Verify
```bash
git log --oneline -10
git status
```
Confirm the working tree is clean.
