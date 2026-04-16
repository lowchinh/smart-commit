#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="smart-commit"
MARKETPLACE="claude-plugins-official"
CLAUDE_DIR="${HOME}/.claude"
PLUGINS_DIR="${CLAUDE_DIR}/plugins/marketplaces/${MARKETPLACE}/plugins"
MARKETPLACE_JSON="${CLAUDE_DIR}/plugins/marketplaces/${MARKETPLACE}/.claude-plugin/marketplace.json"
SETTINGS_JSON="${CLAUDE_DIR}/settings.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[smart-commit]${NC} $*"; }
warn()    { echo -e "${YELLOW}[smart-commit]${NC} $*"; }
error()   { echo -e "${RED}[smart-commit]${NC} $*" >&2; exit 1; }

# 1. Check prerequisites
command -v claude &>/dev/null || error "Claude Code not found. Install it first: https://claude.ai/code"
[ -d "${CLAUDE_DIR}" ]        || error "~/.claude not found. Launch Claude Code at least once first."

# 2. Copy plugin files
DEST="${PLUGINS_DIR}/${PLUGIN_NAME}"
info "Installing plugin to ${DEST} ..."
mkdir -p "${DEST}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r "${SCRIPT_DIR}/.claude-plugin" "${DEST}/"
cp -r "${SCRIPT_DIR}/commands"        "${DEST}/"
cp -r "${SCRIPT_DIR}/skills"          "${DEST}/"

# 3. Register in marketplace.json
if [ -f "${MARKETPLACE_JSON}" ]; then
  if grep -q "\"${PLUGIN_NAME}\"" "${MARKETPLACE_JSON}"; then
    warn "Plugin already registered in marketplace.json, skipping."
  else
    info "Registering in marketplace.json ..."
    # Insert entry after the opening "plugins": [ array bracket
    ENTRY=$(cat <<EOF
    {
      "name": "${PLUGIN_NAME}",
      "description": "Atomic git commits grouped by feature/layer — detects commit style from history, skips build artifacts, never uses git add -A",
      "author": {
        "name": "lowchinh",
        "homepage": "https://github.com/lowchinh/smart-commit"
      },
      "source": "./plugins/${PLUGIN_NAME}",
      "category": "productivity",
      "homepage": "https://github.com/lowchinh/smart-commit"
    },
EOF
)
    # Use python3 for reliable JSON editing
    python3 - <<PYEOF
import json, sys

with open("${MARKETPLACE_JSON}", "r") as f:
    data = json.load(f)

# Check if already present
if any(p.get("name") == "${PLUGIN_NAME}" for p in data.get("plugins", [])):
    print("Already registered.")
    sys.exit(0)

entry = {
    "name": "${PLUGIN_NAME}",
    "description": "Atomic git commits grouped by feature/layer — detects commit style from history, skips build artifacts, never uses git add -A",
    "author": {
        "name": "lowchinh",
        "homepage": "https://github.com/lowchinh/smart-commit"
    },
    "source": "./plugins/${PLUGIN_NAME}",
    "category": "productivity",
    "homepage": "https://github.com/lowchinh/smart-commit"
}

data.setdefault("plugins", []).insert(0, entry)

with open("${MARKETPLACE_JSON}", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("Registered.")
PYEOF
  fi
else
  warn "marketplace.json not found — skipping marketplace registration."
fi

# 4. Enable plugin in settings.json
if [ -f "${SETTINGS_JSON}" ]; then
  if grep -q "\"${PLUGIN_NAME}@${MARKETPLACE}\"" "${SETTINGS_JSON}"; then
    warn "Plugin already enabled in settings.json, skipping."
  else
    info "Enabling plugin in settings.json ..."
    python3 - <<PYEOF
import json

with open("${SETTINGS_JSON}", "r") as f:
    data = json.load(f)

data.setdefault("enabledPlugins", {})["${PLUGIN_NAME}@${MARKETPLACE}"] = True

with open("${SETTINGS_JSON}", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("Enabled.")
PYEOF
  fi
else
  warn "settings.json not found — creating it ..."
  python3 -c "
import json
data = {'enabledPlugins': {'${PLUGIN_NAME}@${MARKETPLACE}': True}}
with open('${SETTINGS_JSON}', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
fi

echo ""
info "Installation complete!"
echo ""
echo "  Next step: run  /reload-plugins  inside Claude Code"
echo "  Then use:       /smart-commit"
echo ""
