# smart-commit

A Claude Code plugin that automatically stages and commits pending changes as **atomic commits grouped by architectural layer or feature**.

- Detects your project's existing commit message convention from git history
- Skips build artifacts, secrets, and lock files automatically
- Never uses `git add -A` — always stages explicit files

## Install

```bash
git clone https://github.com/lowchinh/smart-commit.git
cd smart-commit
bash install.sh
```

Then inside Claude Code:

```
/reload-plugins
```

## Usage

In any git repository, type:

```
/smart-commit
```

Or say: `"commit based on features"`, `"commit by layer"`, `"atomic commits"`

## What it does

1. Inspects `git log`, `git status`, and `git diff` in parallel
2. Skips files that should never be committed (`.env*`, `dist/`, `.next/`, `*.tsbuildinfo`, etc.)
3. Groups remaining files by layer: Config → Docs → DB → Lib → API → UI → Tests
4. Detects your commit style (conventional, ticket-prefixed, imperative)
5. Commits each group with an appropriate message
6. Reports the result and confirms the working tree is clean

## File grouping

| Group | Examples |
|---|---|
| Config / infra | `.gitignore`, `next.config.*`, `tsconfig.json` |
| Docs | `README.md`, `CLAUDE.md`, `*.md` |
| DB / schema | `schema.sql`, `migrations/`, `prisma/` |
| Lib / utilities | `lib/**`, `utils/**`, `hooks/**` |
| API routes | `app/api/**`, `pages/api/**` |
| UI components | `components/**`, `app/**/page.tsx` |
| Tests | `**/*.test.*`, `**/*.spec.*`, `__tests__/` |

≤ 3 files spanning groups → one commit. > 3 files → split by layer.

## Uninstall

Remove the plugin directory and entry from `settings.json`:

```bash
rm -rf ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/smart-commit
```

Then remove `"smart-commit@claude-plugins-official"` from `~/.claude/settings.json` and run `/reload-plugins`.
