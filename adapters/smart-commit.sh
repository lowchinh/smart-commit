#!/usr/bin/env bash
# smart-commit — universal CLI command
# Detects available AI tool and runs smart-commit workflow

set -euo pipefail

PROMPT='Follow the smart-commit workflow exactly:
1. Run git log --oneline -8, git status --short, git diff --stat in parallel
2. Skip: .env*, dist/, .next/, build/, *.tsbuildinfo, .DS_Store, .cursor/, .vscode/, lock files (unless deps changed)
3. Group remaining files by layer: Config/infra → Docs → DB/schema → Lib/utils → API routes → UI components → Tests
4. Detect commit convention from git log (conventional/ticket-prefixed/imperative)
5. For each group: git add <explicit files only — NEVER git add . or git add -A>, then git commit
6. Subject line ≤72 chars. Add Co-Authored-By trailer.
7. Run git log --oneline -10 and git status to confirm clean working tree.'

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

# Must be inside a git repo
if ! git rev-parse --git-dir &>/dev/null 2>&1; then
  echo -e "${RED}✘${NC}  Not a git repository." >&2
  exit 1
fi

# Already clean?
if [ -z "$(git status --short 2>/dev/null)" ]; then
  echo "Working tree is already clean. Nothing to commit."
  exit 0
fi

# ── Detect tool and run ───────────────────────────────────────────────────────

if command -v codex &>/dev/null; then
  echo -e "${CYAN}▶${NC}  Running via Codex CLI..."
  codex --approval-mode auto-edit "$PROMPT"

elif command -v gemini &>/dev/null; then
  echo -e "${CYAN}▶${NC}  Running via Gemini CLI..."
  gemini "$PROMPT"

elif command -v claude &>/dev/null; then
  echo -e "${CYAN}▶${NC}  Running via Claude CLI..."
  claude --print "$PROMPT"

else
  echo -e "${RED}✘${NC}  No AI tool found." >&2
  echo "" >&2
  echo "  Install one of:" >&2
  echo "    Claude Code  →  https://claude.ai/code" >&2
  echo "    Codex CLI    →  npm install -g @openai/codex" >&2
  echo "    Gemini CLI   →  npm install -g @google/gemini-cli" >&2
  echo "" >&2
  echo "  Or use /smart-commit inside Claude Code." >&2
  exit 1
fi
