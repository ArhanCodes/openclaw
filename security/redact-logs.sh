#!/usr/bin/env bash
# Scrub Anthropic / OpenAI / Google OAuth secrets from openclaw log files.
# Useful before sharing a log for debugging or before pushing logs to a
# bug tracker.
#
# Idempotent — running twice is fine.

set -euo pipefail

LOG_DIR="${OPENCLAW_LOG_DIR:-$HOME/.openclaw/logs}"
TARGET_DIR="${1:-$LOG_DIR}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "✗ Not a directory: $TARGET_DIR" >&2
    exit 1
fi

bold() { printf '\033[1m%s\033[0m\n' "$1"; }

bold "Redacting secrets in: $TARGET_DIR"

# Patterns: Anthropic API + OAuth, OpenAI, Google client/refresh, JWT-ish bearers
sed_in_place() {
    if [[ "$(uname)" == "Darwin" ]]; then sed -i '' "$@"
    else sed -i "$@"
    fi
}

count=0
while IFS= read -r -d '' f; do
    sed_in_place \
        -e 's/sk-ant-api03-[A-Za-z0-9_-]\{8\}[A-Za-z0-9_-]*/sk-ant-api03-<redacted>/g' \
        -e 's/sk-ant-oat01-[A-Za-z0-9_-]\{8\}[A-Za-z0-9_-]*/sk-ant-oat01-<redacted>/g' \
        -e 's/sk-proj-[A-Za-z0-9_-]\{8\}[A-Za-z0-9_-]*/sk-proj-<redacted>/g' \
        -e 's/GOCSPX-[A-Za-z0-9_-]\{8\}[A-Za-z0-9_-]*/GOCSPX-<redacted>/g' \
        -e 's|1//0[A-Za-z0-9_-]\{8\}[A-Za-z0-9_-]*|1//0<redacted-google-refresh-token>|g' \
        -e 's/ya29\.[A-Za-z0-9_-]\{8\}[A-Za-z0-9_-]*/ya29.<redacted>/g' \
        -e 's/Bearer [A-Za-z0-9._-]\{20,\}/Bearer <redacted>/g' \
        "$f"
    count=$((count+1))
done < <(find "$TARGET_DIR" -type f \( -name '*.log' -o -name '*.jsonl' \) -print0)

echo "  ✓ redacted $count log file(s)"
echo
echo "Note: this rewrites in place. If you need pristine logs, copy them"
echo "first. Original key prefixes (sk-ant-api03- etc.) are kept so you can"
echo "still tell which provider issued which masked token."
