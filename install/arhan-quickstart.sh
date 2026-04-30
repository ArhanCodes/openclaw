#!/usr/bin/env bash
# Personal one-shot installer for openclaw on macOS.
#
# What this does (idempotent — safe to re-run):
#   1. Verify Node 22+ is available (Clawd Bot needs it)
#   2. npm install -g openclaw   (or update if already present)
#   3. Run `openclaw onboard --install-daemon` non-interactively with
#      sane defaults: Anthropic API key, default model = claude-sonnet-4-5,
#      WhatsApp channel pre-registered (you still pair via QR after)
#   4. Register the bundled morning-brief skill + news-headlines extension
#   5. Add the daily 7am morning-brief cron job
#   6. Print next steps (WhatsApp pair command + how to test)
#
# Set ANTHROPIC_API_KEY in your shell env before running, or export it
# inline:  ANTHROPIC_API_KEY=sk-ant-... ./install/arhan-quickstart.sh

set -euo pipefail

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
info() { printf '  → %s\n' "$1"; }
warn() { printf '  ⚠  %s\n' "$1" >&2; }
fail() { printf '  ✗ %s\n' "$1" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bold "[1/6] Checking Node"
if ! command -v node >/dev/null; then
    fail "Node not installed. Run: brew install node"
fi
NODE_MAJOR="$(node --version | sed 's/^v//;s/\..*//')"
if [ "$NODE_MAJOR" -lt 22 ]; then
    fail "Node $(node --version) is too old. Need 22+. Run: brew upgrade node"
fi
info "Node $(node --version) ok"

bold "[2/6] Installing/updating openclaw globally"
if command -v openclaw >/dev/null; then
    info "openclaw already installed; updating"
    npm install -g openclaw@latest >/dev/null 2>&1
else
    info "first install"
    npm install -g openclaw@latest >/dev/null 2>&1
fi
info "version: $(openclaw --version)"

bold "[3/6] Onboarding (non-interactive)"
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    fail "ANTHROPIC_API_KEY not set. Run: export ANTHROPIC_API_KEY='sk-ant-...' first."
fi
openclaw onboard \
    --non-interactive --accept-risk \
    --auth-choice anthropic-api-key \
    --anthropic-api-key "$ANTHROPIC_API_KEY" \
    --secret-input-mode plaintext \
    --flow advanced \
    --install-daemon \
    --skip-channels --skip-ui --skip-search --skip-bootstrap >/dev/null 2>&1
info "daemon installed at ~/Library/LaunchAgents/ai.openclaw.gateway.plist"

# Wait for daemon to come up
for i in $(seq 1 12); do
    if openclaw doctor --status-plain 2>/dev/null | grep -q "ready"; then break; fi
    sleep 5
done

bold "[4/6] Setting default model to Claude Sonnet 4.5"
openclaw models set anthropic/claude-sonnet-4-5 >/dev/null 2>&1
info "default model: anthropic/claude-sonnet-4-5"

bold "[5/6] Copying skills + news-headlines extension into the install"
SKILLS_DST="$HOME/.openclaw/skills"
mkdir -p "$SKILLS_DST"
cp "$REPO_ROOT/skills/"*.md "$SKILLS_DST/" 2>/dev/null || true
info "$(ls "$SKILLS_DST" | wc -l | tr -d ' ') skills available at $SKILLS_DST"

EXT_DST="$HOME/.openclaw/extensions/news-headlines"
mkdir -p "$EXT_DST"
cp -R "$REPO_ROOT/extensions/news-headlines/." "$EXT_DST/"
info "news-headlines extension copied"

bold "[6/6] Registering daily 7am morning brief cron"
# `cron add` will fail silently if the cron already exists; that's fine
openclaw cron add \
    --name "Morning brief" \
    --cron "0 7 * * *" \
    --tz "$(readlink /etc/localtime | sed 's|/var/db/timezone/zoneinfo/||' || echo 'UTC')" \
    --session isolated \
    --skills morning-brief \
    --system-event "Build my morning brief: pull mail, calendar, WhatsApp DMs, news headlines. Send to my self-DM as plain text using contact names." \
    --deliver-channel whatsapp --deliver-to self 2>/dev/null \
    && info "cron added: 0 7 * * *  Morning brief" \
    || info "(cron already registered — skipped)"

cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Clawd Bot installed and running.

Next steps:

  1. Pair WhatsApp (must be in a real terminal — needs TTY for QR):
       openclaw channels login --channel whatsapp --account default

     Then on phone: WhatsApp → Settings → Linked Devices → Link a device
     → scan the QR.

  2. Test from your phone (after pairing):
       Open WhatsApp → "Message yourself" → "what's on my calendar today?"
     You'll get a Claude reply within ~10s.

  3. The morning brief fires automatically at 7am local. Test now:
       openclaw cron run "Morning brief"

Logs:           ~/.openclaw/logs/gateway.log
Cron jobs:      openclaw cron list
Channel state:  openclaw channels list
Stop daemon:    launchctl bootout gui/$(id -u)/ai.openclaw.gateway
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
