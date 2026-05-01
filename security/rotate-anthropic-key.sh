#!/usr/bin/env bash
# Rotate your Anthropic API key in one shot.
#
# Steps:
#   1. Prompts you to paste the new key (read silently — no echo, no shell
#      history, no env-var leak through ps).
#   2. Updates the key in:
#        - ~/.openclaw/agents/main/agent/auth-profiles.json (openclaw)
#        - ~/Library/Application Support/Alfred/anthropic-api-key.txt (if exists)
#        - macOS Keychain entry com.alfred.butler/anthropic-api-key (if exists)
#        - launchctl env (current login session)
#   3. Restarts the openclaw daemon so it picks up the new key.
#   4. Reminds you to revoke the old key at console.anthropic.com.
#
# Doesn't write the new key to disk anywhere it isn't already used. Doesn't
# echo it to stdout. Cleans the variable on exit.

set -euo pipefail

if [[ -t 0 ]]; then
    printf "Paste new Anthropic API key (input hidden): " >&2
    read -rs NEW_KEY
    echo >&2
else
    NEW_KEY=$(cat)
fi

if [[ -z "${NEW_KEY:-}" ]]; then
    echo "✗ No key provided." >&2
    exit 1
fi
if [[ ! "$NEW_KEY" =~ ^sk-ant- ]]; then
    echo "✗ Key doesn't look like an Anthropic key (expected sk-ant-…)." >&2
    exit 1
fi

trap 'unset NEW_KEY' EXIT

# 1. openclaw auth-profiles.json
PROFILES="$HOME/.openclaw/agents/main/agent/auth-profiles.json"
if [[ -f "$PROFILES" ]]; then
    python3 - "$PROFILES" <<'PY' "$NEW_KEY" >/dev/null
import json, sys, os
path, key = sys.argv[1], sys.argv[2]
data = json.loads(open(path).read())
profiles = data.setdefault("profiles", {})
prof = profiles.setdefault("anthropic:manual", {"provider": "anthropic", "type": "api_key"})
prof["apiKey"] = key
prof["type"] = "api_key"
prof["provider"] = "anthropic"
open(path, "w").write(json.dumps(data, indent=2))
os.chmod(path, 0o600)
PY
    echo "  ✓ updated $PROFILES"
fi

# 2. Alfred file fallback
ALFRED_KEY_FILE="$HOME/Library/Application Support/Alfred/anthropic-api-key.txt"
if [[ -f "$ALFRED_KEY_FILE" ]]; then
    printf '%s' "$NEW_KEY" > "$ALFRED_KEY_FILE"
    chmod 600 "$ALFRED_KEY_FILE"
    echo "  ✓ updated $ALFRED_KEY_FILE"
fi

# 3. macOS Keychain entry (if exists)
if security find-generic-password -s "com.alfred.butler" -a "anthropic-api-key" -w >/dev/null 2>&1; then
    security delete-generic-password -s "com.alfred.butler" -a "anthropic-api-key" >/dev/null 2>&1 || true
    security add-generic-password \
        -s "com.alfred.butler" -a "anthropic-api-key" \
        -w "$NEW_KEY" -U
    echo "  ✓ updated Keychain (com.alfred.butler/anthropic-api-key)"
fi

# 4. launchctl env (current login session)
launchctl setenv ANTHROPIC_API_KEY "$NEW_KEY"
echo "  ✓ updated launchctl ANTHROPIC_API_KEY"

# 5. Restart openclaw daemon if installed
if [[ -f "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" ]]; then
    launchctl kickstart -k "gui/$(id -u)/ai.openclaw.gateway" 2>/dev/null && \
        echo "  ✓ restarted openclaw gateway daemon"
fi

cat <<EOF

✓ Key rotated.

Next:
  1. Verify openclaw still works:
       openclaw agent --agent main --message "say PONG"
  2. Revoke the OLD key at https://console.anthropic.com/settings/keys
EOF
