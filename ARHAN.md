# ArhanCodes/openclaw — personal additions

This fork is mirrored to upstream `openclaw/openclaw` hourly. On top of upstream,
it adds a few personal-use bits I wanted out of the box without touching core.

## What's added

### Skills (`skills/`)

- **`morning-brief.md`** — daily 7am summary skill. Plain-text WhatsApp-ready
  formatting (no `**bold**` because WhatsApp shows literal asterisks),
  contact-name resolution for inbound DMs (no raw phone numbers), HEADLINE
  + `---FULL BRIEF---` split so the macOS notification gets a 1-line
  headline and WhatsApp gets the unabbreviated version.
- **`whatsapp-handler.md`** — conventions for sending messages, replying
  to inbound DMs, when to confirm before sending, what NOT to send via
  WhatsApp.

### Extensions (`extensions/`)

- **`news-headlines/`** — RSS-backed news tool. **No API key, no rate limit,
  no per-day quota.** Default sources: BBC World + Khaleej Times (UAE).
  One tool: `news_top_headlines(limit?, source?)`.

### Install helper (`install/`)

- **`arhan-quickstart.sh`** — one-shot installer for macOS. Does:
  - `npm install -g openclaw` (or update)
  - `openclaw onboard --non-interactive --install-daemon` with Anthropic
    + Claude Sonnet 4.5 as default
  - Copies the skills + news-headlines extension into `~/.openclaw/`
  - Registers a daily 7am morning-brief cron job

  Run with:
  ```bash
  export ANTHROPIC_API_KEY='sk-ant-...'
  ./install/arhan-quickstart.sh
  ```

### CI (`.github/workflows/`)

- **`arhan-sync-upstream.yml`** — hourly upstream sync. Fast-forwards when
  possible, opens a CONFLICT.md commit (or an issue if enabled) when a
  real merge conflict happens. Doesn't depend on the repo having issues
  enabled (this fork has them disabled).

## Why no Docker / VPS deploy

I tried a Docker-on-Contabo deploy first and it didn't work — `clack/prompts`
based interactive flows (`paste-token`, `models auth login`, the modern
onboard wizard) need a real TTY which `docker exec` from a non-interactive
SSH doesn't provide. **Local macOS install via `npm i -g openclaw` is the
proven path.** The install helper above wraps it.

## Recommended local setup on macOS

```bash
# 1. Install via the helper
export ANTHROPIC_API_KEY='sk-ant-...'
git clone https://github.com/ArhanCodes/openclaw ~/code/openclaw
cd ~/code/openclaw
./install/arhan-quickstart.sh

# 2. Pair WhatsApp (one-time, needs a real terminal)
openclaw channels login --channel whatsapp --account default
# scan QR with phone

# 3. Test from your phone
# WhatsApp → "Message yourself" → "what's on my calendar today?"
```

After that, the daemon auto-starts at every login, the 7am brief fires
automatically, and inbound WhatsApp DMs route through Claude with full
tool access.
