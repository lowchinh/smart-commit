# smart-commit

Automatically stages and commits pending changes as **atomic commits grouped by architectural layer or feature** — works with Claude Code, GitHub Copilot, OpenAI Codex CLI, and Gemini CLI.

- Detects your project's existing commit message convention from git history
- Skips build artifacts, secrets, and lock files automatically
- Never uses `git add -A` — always stages explicit files

## Install

```bash
git clone https://github.com/lowchinh/smart-commit.git
cd smart-commit
bash install.sh
```

Installs for **all detected tools** automatically. To target a specific tool:

```bash
bash install.sh --claude    # Claude Code only
bash install.sh --copilot   # GitHub Copilot only
bash install.sh --codex     # OpenAI Codex CLI only
bash install.sh --gemini    # Gemini CLI only
bash install.sh --all       # all tools (default)
```

## Usage by tool

| Tool | How to trigger |
|---|---|
| **Claude Code** | `/smart-commit` or say "commit by layer" |
| **GitHub Copilot** | say "smart commit" in Copilot Chat |
| **OpenAI Codex CLI** | say "smart commit" |
| **Gemini CLI** | say "smart commit" |

> After installing for Claude Code, run `/reload-plugins` inside Claude Code.

## What it does

1. Inspects `git log`, `git status`, and `git diff`
2. Skips files that should never be committed (`.env*`, `dist/`, `.next/`, `*.tsbuildinfo`, lock files, etc.)
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

## Repo structure

```
smart-commit/
├── .claude-plugin/            # Claude Code plugin metadata
├── commands/
│   └── smart-commit.md        # /smart-commit slash command
├── skills/
│   └── smart-commit/
│       └── SKILL.md           # Claude Code context-aware skill
├── adapters/
│   ├── copilot.md             # GitHub Copilot instructions
│   ├── codex.md               # OpenAI Codex CLI instructions
│   └── gemini.md              # Gemini CLI instructions
├── install.sh                 # Universal installer
└── SKILL.md                   # Original skill definition
```

## Uninstall

**Claude Code:**
```bash
rm -rf ~/.claude/plugins/marketplaces/claude-plugins-official/plugins/smart-commit
# Remove "smart-commit@claude-plugins-official" from ~/.claude/settings.json
# Run /reload-plugins
```

**Copilot:** Remove the smart-commit entry from `github.copilot.chat.codeGeneration.instructions` in VS Code settings.

**Codex:** Remove the smart-commit section from `~/.codex/instructions.md`.

**Gemini:** Remove the smart-commit section from `~/.gemini/GEMINI.md`.
