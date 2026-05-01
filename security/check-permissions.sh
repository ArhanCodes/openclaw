#!/usr/bin/env bash
# Verify file permissions on sensitive openclaw files. Auth tokens + API keys
# should be 600 (owner-read-only) or 400 (owner-read-only, no write). World-
# or group-readable is a finding.
#
# Run as: ./security/check-permissions.sh
# Exits 0 if everything is fine, 1 if any finding is reported.

set -euo pipefail

OC_HOME="${OPENCLAW_HOME:-$HOME}/.openclaw"
findings=0

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$1" >&2; findings=$((findings+1)); }
skip() { printf '  · %s\n' "$1"; }

bold "Checking openclaw secrets file modes…"

check() {
    local path="$1"
    local want_mode="$2"
    if [[ ! -e "$path" ]]; then
        skip "$path  (not present — skipping)"
        return
    fi
    local actual
    actual=$(stat -f '%A' "$path" 2>/dev/null || stat -c '%a' "$path" 2>/dev/null)
    if [[ "$actual" == "$want_mode" || "$actual" == "0$want_mode" ]]; then
        ok "$path  ($actual)"
    else
        bad "$path  has mode $actual, want $want_mode"
        chmod "$want_mode" "$path" && ok "    auto-fixed → $want_mode"
    fi
}

# Per-file mode expectations
check "$OC_HOME/openclaw.json"                                600
check "$OC_HOME/agents/main/agent/auth-profiles.json"         600
check "$OC_HOME/agents/main/agent/auth-state.json"            600
check "$OC_HOME/agents/main/agent/models.json"                644
# Optional: Anthropic key file fallback (used by Alfred too)
check "$OC_HOME/anthropic-api-key.txt"                        600

echo
bold "Checking process listing for inadvertent secret exposure…"
if pgrep -af 'sk-ant-api\|sk-proj-\|GOCSPX-\|sk-ant-oat01-' 2>/dev/null | grep -v "$0" >/dev/null; then
    bad "A live process has an API key in its argv (visible to other users via 'ps')"
    pgrep -af 'sk-ant-api\|sk-proj-' | grep -v "$0" | head -3 >&2
else
    ok "No raw API keys in process command-line arguments"
fi

echo
if [[ "$findings" -gt 0 ]]; then
    bold "✗ $findings finding(s)."
    exit 1
else
    bold "✓ All checks passed."
fi
