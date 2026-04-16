# Smart Commit — GitHub Copilot Instructions

When the user asks to "smart commit", "commit by layer", "commit based on features", "atomic commits", or "commit the changes", follow this workflow exactly.

## Workflow

### Step 1 — Inspect repo state
Run in parallel:
```bash
git log --oneline -8
git status --short
git diff --stat
```

### Step 2 — Files to NEVER stage
- Build artifacts: `tsconfig.tsbuildinfo`, `*.tsbuildinfo`, `.next/`, `dist/`, `build/`
- Local tool configs: `.omc/`, `.cursor/`, `.vscode/`
- Secrets: `.env*`
- OS noise: `.DS_Store`, `Thumbs.db`
- Lock files (`package-lock.json`, `yarn.lock`) unless dependencies actually changed

### Step 3 — Group files into atomic commits

| Group | File patterns |
|---|---|
| Config / infra | `.gitignore`, `next.config.*`, `tsconfig.json`, `tailwind.config.*` |
| Docs | `CLAUDE.md`, `README.md`, `*.md` |
| DB / schema | `schema.sql`, `migrations/`, `prisma/` |
| Lib / utilities | `lib/**`, `utils/**`, `hooks/**` |
| API routes | `app/api/**`, `pages/api/**` |
| UI components | `components/**`, `app/**/page.tsx`, `app/**/layout.tsx` |
| Tests | `**/*.test.*`, `**/*.spec.*`, `__tests__/` |

- ≤ 3 files spanning groups → one commit
- > 3 files → split by layer

### Step 4 — Detect commit convention from git log
- `feat(scope): …` → conventional commits
- `[TICKET-123] …` → ticket-prefixed
- `Add …` / `Fix …` → imperative plain
- Default: `type(scope): short description`

### Step 5 — Stage and commit each group
```bash
git add <file1> <file2> ...   # explicit files only — NEVER git add . or git add -A
git commit -m "<message>"
```

Rules:
- Never use `git add .` or `git add -A`
- Never commit `.env*` files
- Never amend existing commits
- Subject line ≤ 72 characters

### Step 6 — Report
Run `git log --oneline -10` and `git status`. Show new commits and confirm working tree is clean.
