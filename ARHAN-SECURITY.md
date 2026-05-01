# ArhanCodes/openclaw — security additions

Hardening on top of upstream openclaw for a personal-assistant install.
None of this changes openclaw's core security model — additive guardrails
only. Upstream's `SECURITY.md` (vulnerability reporting) is unchanged.

## Threat model

A personal-assistant openclaw install on a user's Mac (or VPS) faces five
realistic threats, in roughly this order of impact:

1. **Hallucinated outbound action** — Claude sends an email to the wrong
   person, deletes the wrong calendar event, WhatsApps the wrong number.
   Mitigated by `skills/security-approval.md`.
2. **API key leak via logs / commits / process argv** — keys end up on
   GitHub, in shared logs, in `ps aux`. Mitigated by:
   - `.githooks/pre-commit` blocks commits that contain key-shaped strings
   - `security/redact-logs.sh` scrubs existing log files
   - `security/check-permissions.sh` verifies file modes 600 on secret files
   - `security/rotate-anthropic-key.sh` updates everywhere on rotation
3. **Inbound channel impersonation** — someone spoofs a WhatsApp DM to drive
   the agent. Mitigated by openclaw's built-in `dmPolicy: pairing` plus a
   trusted-JID allowlist on the agent code path.
4. **Tool-call abuse during long-running sessions** — runaway loop where
   Claude calls the same tool repeatedly. Mitigated by openclaw's built-in
   `maxRounds` cap.
5. **Dependency supply-chain compromise** — an npm package update ships
   malicious code. Mitigated by pinning `pluginApi` ranges in plugin
   manifests.

## What this fork adds

```
ARHAN-SECURITY.md                        ← this file
.githooks/pre-commit                     ← block key commits
install/security-setup.sh                ← one-shot hardening
security/check-permissions.sh            ← verify file modes
security/rotate-anthropic-key.sh         ← rotate key everywhere
security/redact-logs.sh                  ← scrub existing logs
skills/security-approval.md              ← Claude confirms before destructive ops
skills/audit-log.md                      ← Claude logs important actions
```

## Setup

After cloning the fork:

```bash
./install/security-setup.sh
```

Idempotent. Re-run after upstream syncs.

## Key rotation

```bash
./security/rotate-anthropic-key.sh
# Paste the new key when prompted (input is hidden)
# Old key revoke: https://console.anthropic.com/settings/keys
```

Updates: `auth-profiles.json`, Alfred file fallback, macOS Keychain entry,
launchctl env. Restarts the daemon.

## What's intentionally NOT here

- **Encryption of `memory.json`** — already mode 600 in your home
  directory; adding a passphrase kills the always-on feel.
- **Tool-call rate limiting** — openclaw's `maxRounds` already caps loops.
- **TLS for localhost gateway** — gateway binds to 127.0.0.1; if a malicious
  process is already on your machine, TLS doesn't save you.
- **Two-person approval** — overkill for a personal assistant.
