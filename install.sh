#!/usr/bin/env bash
set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${GREEN}✔${NC}  $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
error() { echo -e "${RED}✘${NC}  $*" >&2; exit 1; }
step()  { echo -e "\n${CYAN}${BOLD}▶ $*${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo "  Usage: bash install.sh [--all] [--claude] [--copilot] [--codex] [--gemini]"
  echo ""
  echo "  Options:"
  echo "    --all      Install for all detected tools (default)"
  echo "    --claude   Claude Code only"
  echo "    --copilot  GitHub Copilot (VS Code) only"
  echo "    --codex    OpenAI Codex CLI only"
  echo "    --gemini   Gemini CLI only"
  echo ""
}

# ── Parse flags ───────────────────────────────────────────────────────────────
OPT_CLAUDE=false; OPT_COPILOT=false; OPT_CODEX=false; OPT_GEMINI=false
OPT_ALL=true

for arg in "$@"; do
  case $arg in
    --all)     OPT_ALL=true ;;
    --claude)  OPT_CLAUDE=true;  OPT_ALL=false ;;
    --copilot) OPT_COPILOT=true; OPT_ALL=false ;;
    --codex)   OPT_CODEX=true;   OPT_ALL=false ;;
    --gemini)  OPT_GEMINI=true;  OPT_ALL=false ;;
    --help|-h) usage; exit 0 ;;
    *) warn "Unknown flag: $arg"; usage; exit 1 ;;
  esac
done

if $OPT_ALL; then
  OPT_CLAUDE=true; OPT_COPILOT=true; OPT_CODEX=true; OPT_GEMINI=true
fi

echo ""
echo -e "${BOLD}smart-commit installer${NC}"
echo "────────────────────────────────"

# ══════════════════════════════════════════════════════════════════════════════
# SHELL COMMAND — installs `smart-commit` to PATH (all tools benefit)
# ══════════════════════════════════════════════════════════════════════════════
install_shell_command() {
  step "Global shell command"

  # Find writable bin dir in PATH
  if [ -d "${HOME}/.local/bin" ]; then
    BIN_DIR="${HOME}/.local/bin"
  elif [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    BIN_DIR="/usr/local/bin"
  else
    mkdir -p "${HOME}/.local/bin"
    BIN_DIR="${HOME}/.local/bin"
  fi

  cp "${SCRIPT_DIR}/adapters/smart-commit.sh" "${BIN_DIR}/smart-commit"
  chmod +x "${BIN_DIR}/smart-commit"

  # Make sure BIN_DIR is in PATH
  if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    warn "${BIN_DIR} is not in your PATH."
    warn "Add this to your ~/.bashrc or ~/.zshrc:"
    warn "  export PATH=\"\$PATH:${BIN_DIR}\""
  fi

  info "Installed: ${BIN_DIR}/smart-commit"
}

# ══════════════════════════════════════════════════════════════════════════════
# CLAUDE CODE
# ══════════════════════════════════════════════════════════════════════════════
install_claude() {
  step "Claude Code"

  CLAUDE_DIR="${HOME}/.claude"
  MARKETPLACE="claude-plugins-official"
  PLUGINS_DIR="${CLAUDE_DIR}/plugins/marketplaces/${MARKETPLACE}/plugins"
  MARKETPLACE_JSON="${CLAUDE_DIR}/plugins/marketplaces/${MARKETPLACE}/.claude-plugin/marketplace.json"
  SETTINGS_JSON="${CLAUDE_DIR}/settings.json"
  PLUGIN_NAME="smart-commit"

  if ! command -v claude &>/dev/null; then
    warn "Claude Code not found — skipping. Install: https://claude.ai/code"
    return
  fi

  [ -d "${CLAUDE_DIR}" ] || error "~/.claude not found. Launch Claude Code at least once first."

  # Copy plugin files
  DEST="${PLUGINS_DIR}/${PLUGIN_NAME}"
  mkdir -p "${DEST}"
  cp -r "${SCRIPT_DIR}/.claude-plugin" "${DEST}/"
  cp -r "${SCRIPT_DIR}/commands"        "${DEST}/"
  cp -r "${SCRIPT_DIR}/skills"          "${DEST}/"
  info "Plugin files → ${DEST}"

  # Register in marketplace.json
  if [ -f "${MARKETPLACE_JSON}" ]; then
    python3 - <<PYEOF
import json, sys
with open("${MARKETPLACE_JSON}") as f: data = json.load(f)
if any(p.get("name") == "${PLUGIN_NAME}" for p in data.get("plugins", [])):
    print("  already in marketplace.json")
    sys.exit(0)
entry = {
    "name": "${PLUGIN_NAME}",
    "description": "Atomic git commits grouped by feature/layer",
    "author": {"name": "lowchinh", "homepage": "https://github.com/lowchinh/smart-commit"},
    "source": "./plugins/${PLUGIN_NAME}",
    "category": "productivity",
    "homepage": "https://github.com/lowchinh/smart-commit"
}
data.setdefault("plugins", []).insert(0, entry)
with open("${MARKETPLACE_JSON}", "w") as f: json.dump(data, f, indent=2, ensure_ascii=False); f.write("\n")
print("  registered in marketplace.json")
PYEOF
  fi

  # Enable in settings.json
  python3 - <<PYEOF
import json, os
path = "${SETTINGS_JSON}"
data = {}
if os.path.exists(path):
    with open(path) as f: data = json.load(f)
key = "${PLUGIN_NAME}@${MARKETPLACE}"
if data.get("enabledPlugins", {}).get(key):
    print("  already enabled in settings.json")
else:
    data.setdefault("enabledPlugins", {})[key] = True
    with open(path, "w") as f: json.dump(data, f, indent=2, ensure_ascii=False); f.write("\n")
    print("  enabled in settings.json")
PYEOF

  info "Claude Code → /reload-plugins, then use /smart-commit"
}

# ══════════════════════════════════════════════════════════════════════════════
# GITHUB COPILOT — adds instructions + VS Code keybinding Ctrl+Shift+Alt+C
# ══════════════════════════════════════════════════════════════════════════════
install_copilot() {
  step "GitHub Copilot"

  case "$(uname -s)" in
    Darwin) VSCODE_SETTINGS="${HOME}/Library/Application Support/Code/User/settings.json"
            VSCODE_KEYBINDINGS="${HOME}/Library/Application Support/Code/User/keybindings.json" ;;
    Linux)  VSCODE_SETTINGS="${HOME}/.config/Code/User/settings.json"
            VSCODE_KEYBINDINGS="${HOME}/.config/Code/User/keybindings.json" ;;
    MINGW*|CYGWIN*|MSYS*)
            VSCODE_SETTINGS="${APPDATA}/Code/User/settings.json"
            VSCODE_KEYBINDINGS="${APPDATA}/Code/User/keybindings.json" ;;
    *) warn "Unsupported OS — skipping Copilot"; return ;;
  esac

  if ! command -v code &>/dev/null && [ ! -f "${VSCODE_SETTINGS}" ]; then
    warn "VS Code not found — skipping Copilot"
    return
  fi

  mkdir -p "$(dirname "${VSCODE_SETTINGS}")"

  # 1. Add Copilot Chat instructions
  python3 - <<PYEOF
import json, os
path = "${VSCODE_SETTINGS}"
data = {}
if os.path.exists(path):
    with open(path) as f:
        try: data = json.load(f)
        except: data = {}
instructions = data.setdefault("github.copilot.chat.codeGeneration.instructions", [])
if any("smart commit" in str(i).lower() or "smart-commit" in str(i).lower() for i in instructions):
    print("  Copilot instructions already set")
else:
    instructions.append({"text": open("${SCRIPT_DIR}/adapters/copilot.md").read()})
    with open(path, "w") as f: json.dump(data, f, indent=2, ensure_ascii=False); f.write("\n")
    print("  added smart-commit to Copilot instructions")
PYEOF

  # 2. Add VS Code keybinding: Ctrl+Shift+Alt+C → open Copilot Chat with "smart commit"
  python3 - <<PYEOF
import json, os
path = "${VSCODE_KEYBINDINGS}"
bindings = []
if os.path.exists(path):
    with open(path) as f:
        content = f.read().strip()
        if content:
            # Strip JS comments before parsing
            import re
            content = re.sub(r'//[^\n]*', '', content)
            try: bindings = json.loads(content)
            except: bindings = []

KEY = "ctrl+shift+alt+c"
CMD = "workbench.action.chat.open"

if any(b.get("key") == KEY and b.get("command") == CMD for b in bindings):
    print("  keybinding already set")
else:
    bindings.append({
        "key": KEY,
        "command": CMD,
        "args": {"query": "smart commit"}
    })
    with open(path, "w") as f: json.dump(bindings, f, indent=2, ensure_ascii=False); f.write("\n")
    print("  added keybinding Ctrl+Shift+Alt+C → smart commit")
PYEOF

  info "Copilot → Ctrl+Shift+Alt+C in VS Code (or say 'smart commit' in Chat)"
}

# ══════════════════════════════════════════════════════════════════════════════
# OPENAI CODEX CLI
# ══════════════════════════════════════════════════════════════════════════════
install_codex() {
  step "OpenAI Codex CLI"

  CODEX_DIR="${HOME}/.codex"
  INSTRUCTIONS_FILE="${CODEX_DIR}/instructions.md"

  if ! command -v codex &>/dev/null; then
    warn "Codex CLI not found — skipping. Install: npm install -g @openai/codex"
    return
  fi

  mkdir -p "${CODEX_DIR}"

  if [ -f "${INSTRUCTIONS_FILE}" ] && grep -q "Smart Commit" "${INSTRUCTIONS_FILE}"; then
    warn "smart-commit already in ${INSTRUCTIONS_FILE}"
  else
    { echo ""; echo "---"; echo ""; cat "${SCRIPT_DIR}/adapters/codex.md"; } >> "${INSTRUCTIONS_FILE}"
    info "Appended to ${INSTRUCTIONS_FILE}"
  fi

  info "Codex CLI → type 'smart commit' or run: smart-commit"
}

# ══════════════════════════════════════════════════════════════════════════════
# GEMINI CLI
# ══════════════════════════════════════════════════════════════════════════════
install_gemini() {
  step "Gemini CLI"

  GEMINI_DIR="${HOME}/.gemini"
  GEMINI_FILE="${GEMINI_DIR}/GEMINI.md"

  if ! command -v gemini &>/dev/null; then
    warn "Gemini CLI not found — skipping. Install: npm install -g @google/gemini-cli"
    return
  fi

  mkdir -p "${GEMINI_DIR}"

  if [ -f "${GEMINI_FILE}" ] && grep -q "Smart Commit" "${GEMINI_FILE}"; then
    warn "smart-commit already in ${GEMINI_FILE}"
  else
    { echo ""; echo "---"; echo ""; cat "${SCRIPT_DIR}/adapters/gemini.md"; } >> "${GEMINI_FILE}"
    info "Appended to ${GEMINI_FILE}"
  fi

  info "Gemini CLI → type 'smart commit' or run: smart-commit"
}

# ══════════════════════════════════════════════════════════════════════════════
# Run
# ══════════════════════════════════════════════════════════════════════════════
install_shell_command   # always install the shell command

$OPT_CLAUDE  && install_claude
$OPT_COPILOT && install_copilot
$OPT_CODEX   && install_codex
$OPT_GEMINI  && install_gemini

echo ""
echo -e "${BOLD}All done!${NC}"
echo ""
echo "  Terminal (any tool)   →  smart-commit"
echo "  Claude Code           →  /reload-plugins, then /smart-commit"
echo "  VS Code Copilot       →  Ctrl+Shift+Alt+C"
echo "  Codex / Gemini        →  smart-commit  or  say 'smart commit'"
echo ""
