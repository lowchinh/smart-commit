# Smart Commit

When the user asks to "smart commit", "commit by layer", "commit based on features", "atomic commits", or "commit the changes", execute the following workflow.

## Workflow

### Step 1 — Inspect repo state (run in parallel)
```bash
git log --oneline -8
git status --short
git diff --stat
```
If working tree is already clean, tell the user and stop.

### Step 2 — Identify files to skip (never stage)
- Build artifacts: `tsconfig.tsbuildinfo`, `*.tsbuildinfo`, `.next/`, `dist/`, `build/`
- Local configs: `.omc/`, `.cursor/`, `.vscode/`
- Secrets: `.env*`
- OS noise: `.DS_Store`, `Thumbs.db`
- Lock files: `package-lock.json`, `yarn.lock` (unless dependencies actually changed)

### Step 3 — Group remaining files into atomic commits

| Group | File patterns |
|---|---|
| Config / infra | `.gitignore`, `next.config.*`, `tsconfig.json`, `tailwind.config.*` |
| Docs | `README.md`, `GEMINI.md`, `CLAUDE.md`, `*.md` |
| DB / schema | `schema.sql`, `migrations/`, `prisma/` |
| Lib / utilities | `lib/**`, `utils/**`, `hooks/**` |
| API routes | `app/api/**`, `pages/api/**` |
| UI components | `components/**`, `app/**/page.tsx`, `app/**/layout.tsx` |
| Tests | `**/*.test.*`, `**/*.spec.*`, `__tests__/` |

- ≤ 3 files spanning groups → one commit for the whole feature
- > 3 files → split by layer, each commit named after the layer

### Step 4 — Detect commit convention from git log
- `feat(scope): …` → conventional commits
- `[TICKET-123] …` → ticket-prefixed
- `Add …` / `Fix …` → imperative plain
- Default: `type(scope): short description`

### Step 5 — Stage and commit each group
```bash
git add <file1> <file2> ...    # explicit files only — NEVER git add . or git add -A
git commit -m "<message>"
```

Rules:
- Never use `git add .` or `git add -A`
- Never commit `.env*` files
- Never amend existing commits
- Subject line ≤ 72 characters

### Step 6 — Report results
```bash
git log --oneline -10
git status
```
Show the user the new commits and confirm working tree is clean.
