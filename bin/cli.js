#!/usr/bin/env node
'use strict';

const { spawnSync } = require('child_process');
const path = require('path');
const args = process.argv.slice(2);

// ── --setup flag ──────────────────────────────────────────────────────────────
if (args.includes('--setup') || args.includes('-s')) {
  require('./setup.js');
  process.exit(0);
}

if (args.includes('--help') || args.includes('-h')) {
  console.log(`
  smart-commit — atomic git commits grouped by feature/layer

  Usage:
    smart-commit          Run smart-commit via detected AI tool
    smart-commit --setup  Install configs for Claude Code, Copilot, Codex, Gemini
    smart-commit --help   Show this help

  Supported AI tools (auto-detected in order):
    1. OpenAI Codex CLI   (codex)
    2. Gemini CLI         (gemini)
    3. Claude Code CLI    (claude)
  `);
  process.exit(0);
}

// ── Must be inside a git repo ─────────────────────────────────────────────────
const gitCheck = spawnSync('git', ['rev-parse', '--git-dir'], { stdio: 'pipe' });
if (gitCheck.status !== 0) {
  console.error('✘  Not a git repository.');
  process.exit(1);
}

// ── Already clean? ────────────────────────────────────────────────────────────
const status = spawnSync('git', ['status', '--short'], { stdio: 'pipe' });
if (!status.stdout.toString().trim()) {
  console.log('Working tree is already clean. Nothing to commit.');
  process.exit(0);
}

// ── Prompt ────────────────────────────────────────────────────────────────────
const PROMPT = [
  'Follow the smart-commit workflow exactly:',
  '1. Run git log --oneline -8, git status --short, git diff --stat in parallel.',
  '2. Skip: .env*, dist/, .next/, build/, *.tsbuildinfo, .DS_Store, .cursor/, .vscode/, lock files (unless deps changed).',
  '3. Group remaining files by layer: Config/infra → Docs → DB/schema → Lib/utils → API routes → UI components → Tests.',
  '   - ≤3 files spanning groups → one commit. >3 files → split by layer.',
  '4. Detect commit convention from git log (conventional / ticket-prefixed / imperative).',
  '5. For each group: git add <explicit files only — NEVER git add . or git add -A>, then git commit.',
  '6. Subject line ≤72 chars. Add Co-Authored-By trailer.',
  '7. Run git log --oneline -10 and git status to confirm clean working tree.',
].join('\n');

// ── Detect OS-appropriate "command exists" ────────────────────────────────────
function commandExists(cmd) {
  const check = process.platform === 'win32'
    ? spawnSync('where', [cmd], { stdio: 'pipe', shell: true })
    : spawnSync('which', [cmd], { stdio: 'pipe' });
  return check.status === 0;
}

function run(cmd, cmdArgs) {
  const result = spawnSync(cmd, cmdArgs, {
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  process.exit(result.status ?? 0);
}

// ── Pick AI tool ──────────────────────────────────────────────────────────────
if (commandExists('codex')) {
  console.log('▶  Using Codex CLI...');
  run('codex', ['--approval-mode', 'auto-edit', PROMPT]);

} else if (commandExists('gemini')) {
  console.log('▶  Using Gemini CLI...');
  run('gemini', [PROMPT]);

} else if (commandExists('claude')) {
  console.log('▶  Using Claude CLI...');
  run('claude', ['--print', PROMPT]);

} else {
  console.error('✘  No AI tool found.\n');
  console.error('   Install one of:');
  console.error('     Claude Code  →  https://claude.ai/code');
  console.error('     Codex CLI    →  npm install -g @openai/codex');
  console.error('     Gemini CLI   →  npm install -g @google/gemini-cli\n');
  console.error('   Or use /smart-commit inside Claude Code.');
  process.exit(1);
}
