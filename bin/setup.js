#!/usr/bin/env node
'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

const SILENT  = process.argv.includes('--silent');
const PKG_DIR = path.join(__dirname, '..');
const HOME    = os.homedir();
const PLATFORM = process.platform; // 'win32' | 'darwin' | 'linux'

function log(msg)  { if (!SILENT) console.log(`  ✔  ${msg}`); }
function warn(msg) { if (!SILENT) console.log(`  ⚠  ${msg}`); }
function head(msg) { if (!SILENT) console.log(`\n▶ ${msg}`); }

// ── Helpers ───────────────────────────────────────────────────────────────────
function readJSON(filePath) {
  try { return JSON.parse(fs.readFileSync(filePath, 'utf8')); }
  catch { return null; }
}

function writeJSON(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

function commandExists(cmd) {
  try {
    const { spawnSync } = require('child_process');
    const r = spawnSync(PLATFORM === 'win32' ? 'where' : 'which', [cmd], { stdio: 'pipe' });
    return r.status === 0;
  } catch { return false; }
}

// ── VS Code paths ─────────────────────────────────────────────────────────────
function vscodeDir() {
  if (PLATFORM === 'win32')  return path.join(process.env.APPDATA || '', 'Code', 'User');
  if (PLATFORM === 'darwin') return path.join(HOME, 'Library', 'Application Support', 'Code', 'User');
  return path.join(HOME, '.config', 'Code', 'User');
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. CLAUDE CODE
// ══════════════════════════════════════════════════════════════════════════════
function setupClaude() {
  head('Claude Code');

  if (!commandExists('claude')) {
    warn('Claude Code not found — skipping');
    return;
  }

  const MARKETPLACE   = 'claude-plugins-official';
  const claudeDir     = path.join(HOME, '.claude');
  const pluginsDir    = path.join(claudeDir, 'plugins', 'marketplaces', MARKETPLACE, 'plugins');
  const marketplaceJSON = path.join(claudeDir, 'plugins', 'marketplaces', MARKETPLACE, '.claude-plugin', 'marketplace.json');
  const settingsJSON  = path.join(claudeDir, 'settings.json');
  const dest          = path.join(pluginsDir, 'smart-commit');

  if (!fs.existsSync(claudeDir)) {
    warn('~/.claude not found — launch Claude Code once first, then re-run setup');
    return;
  }

  // Copy plugin files
  for (const dir of ['.claude-plugin', 'commands', 'skills']) {
    const src = path.join(PKG_DIR, dir);
    if (fs.existsSync(src)) {
      copyDir(src, path.join(dest, dir));
    }
  }
  log(`Plugin copied → ${dest}`);

  // Register in marketplace.json
  if (fs.existsSync(marketplaceJSON)) {
    const data = readJSON(marketplaceJSON) || {};
    const plugins = data.plugins || [];
    if (!plugins.some(p => p.name === 'smart-commit')) {
      plugins.unshift({
        name: 'smart-commit',
        description: 'Atomic git commits grouped by feature/layer',
        author: { name: 'lowchinh', homepage: 'https://github.com/lowchinh/smart-commit' },
        source: './plugins/smart-commit',
        category: 'productivity',
        homepage: 'https://github.com/lowchinh/smart-commit',
      });
      data.plugins = plugins;
      writeJSON(marketplaceJSON, data);
      log('Registered in marketplace.json');
    } else {
      warn('Already in marketplace.json');
    }
  }

  // Enable in settings.json
  const settings = readJSON(settingsJSON) || {};
  const key = 'smart-commit@claude-plugins-official';
  if (!settings.enabledPlugins?.[key]) {
    settings.enabledPlugins = { ...settings.enabledPlugins, [key]: true };
    writeJSON(settingsJSON, settings);
    log('Enabled in settings.json');
  } else {
    warn('Already enabled in settings.json');
  }

  log('Claude Code done — run /reload-plugins, then /smart-commit');
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. GITHUB COPILOT (VS Code settings + keybinding)
// ══════════════════════════════════════════════════════════════════════════════
function setupCopilot() {
  head('GitHub Copilot');

  const dir          = vscodeDir();
  const settingsFile = path.join(dir, 'settings.json');
  const keybindFile  = path.join(dir, 'keybindings.json');
  const copilotMd    = path.join(PKG_DIR, 'adapters', 'copilot.md');

  if (!fs.existsSync(settingsFile) && !commandExists('code')) {
    warn('VS Code not found — skipping Copilot');
    return;
  }

  // Add Copilot Chat instructions
  const settings = readJSON(settingsFile) || {};
  const instructions = settings['github.copilot.chat.codeGeneration.instructions'] || [];
  const alreadySet = instructions.some(i => /smart.?commit/i.test(JSON.stringify(i)));
  if (!alreadySet) {
    instructions.push({ text: fs.readFileSync(copilotMd, 'utf8') });
    settings['github.copilot.chat.codeGeneration.instructions'] = instructions;
    writeJSON(settingsFile, settings);
    log('Added smart-commit to Copilot Chat instructions');
  } else {
    warn('Copilot instructions already set');
  }

  // Add keybinding: Ctrl+Shift+Alt+C → open chat with "smart commit"
  let bindings = [];
  if (fs.existsSync(keybindFile)) {
    try {
      // Strip JS comments
      const raw = fs.readFileSync(keybindFile, 'utf8').replace(/\/\/[^\n]*/g, '');
      bindings = JSON.parse(raw) || [];
    } catch { bindings = []; }
  }
  const KEY = PLATFORM === 'darwin' ? 'cmd+shift+alt+c' : 'ctrl+shift+alt+c';
  const alreadyBound = bindings.some(b => b.key === KEY && b.command === 'workbench.action.chat.open');
  if (!alreadyBound) {
    bindings.push({ key: KEY, command: 'workbench.action.chat.open', args: { query: 'smart commit' } });
    fs.mkdirSync(path.dirname(keybindFile), { recursive: true });
    fs.writeFileSync(keybindFile, JSON.stringify(bindings, null, 2) + '\n', 'utf8');
    log(`Keybinding set: ${KEY} → open Copilot Chat with "smart commit"`);
  } else {
    warn('Keybinding already set');
  }

  const shortcut = PLATFORM === 'darwin' ? 'Cmd+Shift+Alt+C' : 'Ctrl+Shift+Alt+C';
  log(`Copilot done — press ${shortcut} in VS Code`);
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. OPENAI CODEX CLI
// ══════════════════════════════════════════════════════════════════════════════
function setupCodex() {
  head('OpenAI Codex CLI');

  if (!commandExists('codex')) {
    warn('Codex CLI not found — skipping (npm install -g @openai/codex)');
    return;
  }

  const file    = path.join(HOME, '.codex', 'instructions.md');
  const content = fs.readFileSync(path.join(PKG_DIR, 'adapters', 'codex.md'), 'utf8');

  if (fs.existsSync(file) && fs.readFileSync(file, 'utf8').includes('Smart Commit')) {
    warn('Already in ~/.codex/instructions.md');
  } else {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.appendFileSync(file, `\n---\n\n${content}`, 'utf8');
    log('Appended to ~/.codex/instructions.md');
  }

  log('Codex done — type "smart commit" or run: smart-commit');
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. GEMINI CLI
// ══════════════════════════════════════════════════════════════════════════════
function setupGemini() {
  head('Gemini CLI');

  if (!commandExists('gemini')) {
    warn('Gemini CLI not found — skipping (npm install -g @google/gemini-cli)');
    return;
  }

  const file    = path.join(HOME, '.gemini', 'GEMINI.md');
  const content = fs.readFileSync(path.join(PKG_DIR, 'adapters', 'gemini.md'), 'utf8');

  if (fs.existsSync(file) && fs.readFileSync(file, 'utf8').includes('Smart Commit')) {
    warn('Already in ~/.gemini/GEMINI.md');
  } else {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.appendFileSync(file, `\n---\n\n${content}`, 'utf8');
    log('Appended to ~/.gemini/GEMINI.md');
  }

  log('Gemini done — type "smart commit" or run: smart-commit');
}

// ── copyDir helper ────────────────────────────────────────────────────────────
function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, entry.name);
    const d = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(s, d);
    else fs.copyFileSync(s, d);
  }
}

// ── Run all ───────────────────────────────────────────────────────────────────
if (!SILENT) {
  console.log('\n  smart-commit setup\n  ──────────────────');
}

setupClaude();
setupCopilot();
setupCodex();
setupGemini();

if (!SILENT) {
  console.log(`
  Done!

  Terminal          →  smart-commit
  Claude Code       →  /reload-plugins  then  /smart-commit
  VS Code Copilot   →  ${PLATFORM === 'darwin' ? 'Cmd' : 'Ctrl'}+Shift+Alt+C
  Codex / Gemini    →  smart-commit  or  say "smart commit"
`);
}
