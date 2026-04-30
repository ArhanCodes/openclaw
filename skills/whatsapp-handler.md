---
name: whatsapp-handler
description: Conventions for sending WhatsApp messages, replying to inbound DMs, and using contact names instead of raw numbers.
metadata: { "openclaw": { "emoji": "💬" } }
---

# WhatsApp handler

When the user asks you to message someone on WhatsApp, or you receive an
inbound DM that warrants a reply, follow these conventions.

## Sending messages

Tools: `whatsapp_send(to, text)`, `whatsapp_recent_inbound(lookbackHours?, limit?)`.

When the user says *"message X"* / *"text Y"* / *"send Z to A"*:

1. **Resolve who.** If they said a name, search memory or contacts for the number.
   - `memory_search("X phone number")` first
   - If not found, ask the user — don't invent a number
2. **Confirm before sending.** Echo back: "I'll message X (+971…) saying 'Y'. Send?"
   Only skip the confirmation if the user used clearly imperative phrasing
   ("just send it", "send now").
3. **Once you have a confirmed number**, save it via `memory_remember`
   (`content: "X's WhatsApp number is +971…"`, `tags: ["contact", "X"]`)
   so future requests skip the lookup.

## Receiving messages

Inbound DMs come with a `fromName` field — the resolved contact name from
the user's macOS Contacts. **Always use `fromName` in your replies**:

- ✅ "Mom messaged: 'are we going to Zaza?'"
- ❌ "971506345772@s.whatsapp.net messaged: 'are we going to Zaza?'"

If `fromName` is empty (unsaved contact), fall back to the WhatsApp
profile name (`pushName`), then to the number with a `+` prefix.

## Self-chat (Message yourself)

When the inbound DM comes from the user's own JID, that's the user texting
themselves to give Alfred/Clawd a command. Run the agent loop on the message,
reply via the same chat. Self-chat messages on WhatsApp are silenced by
default — that's expected, the user isn't waiting for a notification.

## Things NOT to do

- **Don't send via WhatsApp without confirming**, unless explicitly told to.
- **Don't include 2FA codes, passwords, or financial credentials** in any
  WhatsApp message — the protocol is end-to-end via Meta but treat it as
  not-trusted-enough for secrets.
- **Don't auto-reply to groups.** Auto-agent should only fire on direct DMs
  from trusted senders, never groups.
- **Don't send markdown bold/headers.** WhatsApp shows literal asterisks. Use
  plain text with bullets (`•` or `-`).
