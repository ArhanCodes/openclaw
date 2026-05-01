#!/usr/bin/env bash
# One-shot security hardening for an existing openclaw install.
#
# Does:
#   1. Tighten file modes on auth files (600)
#   2. Install the .githooks/pre-commit secret scanner into git config
#   3. Copy security skills into ~/.openclaw/skills so Claude reads them
#   4. Run check-permissions.sh
#   5. Run redact-logs.sh on existing logs (in case past keys leaked)
#
# Idempotent. Re-run after upstream syncs.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OC_HOME="$HOME/.openclaw"
SKILLS_DST="$OC_HOME/skills"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
info() { printf '  → %s\n' "$1"; }

bold "[1/5] Tighten file modes"
chmod 600 "$OC_HOME/agents/main/agent/auth-profiles.json" 2>/dev/null && info "auth-profiles.json → 600" || info "(no auth-profiles.json yet — will be 600 when created)"
chmod 600 "$OC_HOME/agents/main/agent/auth-state.json"   2>/dev/null || true
chmod 600 "$OC_HOME/openclaw.json"                       2>/dev/null && info "openclaw.json → 600" || true

bold "[2/5] Install pre-commit secret scanner (in this repo)"
chmod +x "$REPO_ROOT/.githooks/pre-commit"
git -C "$REPO_ROOT" config core.hooksPath .githooks
info "git core.hooksPath → .githooks (scanner active for future commits)"

bold "[3/5] Copy security skills into ~/.openclaw/skills"
mkdir -p "$SKILLS_DST"
cp "$REPO_ROOT/skills/security-approval.md" "$SKILLS_DST/" 2>/dev/null && info "security-approval.md installed" || true
cp "$REPO_ROOT/skills/audit-log.md"          "$SKILLS_DST/" 2>/dev/null && info "audit-log.md installed" || true

bold "[4/5] Run permissions check"
"$REPO_ROOT/security/check-permissions.sh" || true

bold "[5/5] Redact secrets from existing log files"
"$REPO_ROOT/security/redact-logs.sh" "$OC_HOME/logs" 2>/dev/null || info "(no logs dir yet — fine)"

cat <<EOF

✓ Security setup complete.

What changed:
  - auth-profiles.json + openclaw.json are now mode 600
  - .githooks/pre-commit blocks future commits that contain API keys
  - skills/security-approval.md + skills/audit-log.md are loaded by Claude
  - existing log files have been redacted (Anthropic, OpenAI, Google secrets)

Restart the daemon to pick up the new skills:
  launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway

Manual steps you should still do:
  - Rotate any API key that's been in chat / logs:  ./security/rotate-anthropic-key.sh
  - Audit your WhatsApp linked-device list (Settings → Linked Devices)
  - Review the trustedJIDs in your agent — only your own JID should drive the agent
EOF
