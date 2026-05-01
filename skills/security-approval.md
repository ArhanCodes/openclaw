---
name: security-approval
description: Confirmation gates for destructive tool calls — sending email/messages, deleting calendar events, granting access. Stops Claude from acting on hallucinated facts.
metadata: { "openclaw": { "emoji": "🛡️" } }
---

# Security: confirmation gates

Before calling **any** destructive or outbound-communication tool, you MUST
echo what you're about to do back to the user in plain English and wait for
explicit confirmation. The phrasing must include:

- **The action** (send / delete / move / share / pay)
- **The target** (recipient / event title / amount)
- **The content** (one-line gist of the message body, the new event time, etc.)

## Tools that require confirmation

| Tool | What to confirm |
|---|---|
| `mail_send` | "I'll email **<to>** with subject **<subject>**: <one-line body>. Send?" |
| `mail_reply` | "I'll reply to <sender>'s thread '<subject>': <one-line draft>. Send?" |
| `whatsapp_send` (to anyone other than self) | "I'll WhatsApp **<contact name>** (+<digits>): <one-line text>. Send?" |
| `calendar_delete_event` | "I'll delete **<title>** on **<date/time>**. Confirm?" |
| `calendar_update_event` (changing time or attendees on an event with attendees) | "I'll move **<title>** from **<old>** to **<new>**, notifying attendees. Confirm?" |
| `reminders_create` (large batches) | OK without confirm for single items; for >5 in one batch, summarise first |
| Any new tool added later that performs a real-world write | Confirm by default |

## When to skip the confirmation

- The user used clearly imperative phrasing in the SAME turn ("just send it",
  "do it now", "go ahead")
- The action is read-only (`mail_recent_unread`, `calendar_list_events`,
  `whatsapp_recent_inbound`, `memory_search`, `news_top_headlines`)
- The action targets ONLY the user themselves (writing to their own memory,
  sending a self-DM brief on schedule)

## Why this exists

LLMs occasionally hallucinate facts (wrong phone number, wrong recipient,
wrong dates). For read-only tools that's harmless. For send/delete tools
it's a real-world cost (embarrassing email, deleted meeting, money out).
The confirmation gate makes hallucinations cost ~5 seconds of friction
instead of ~5 hours of recovery.

## Confirmation phrasing rules

- Use the **resolved name** for contacts, not raw phone numbers
- Use **plain English times** ("Tomorrow 3pm" not "2026-05-02T15:00:00Z")
- Use **truncated previews** for long bodies: first ~80 chars + "…"
- Always finish with a literal question: "Send?", "Confirm?", "Proceed?"

A `Yes` / `y` / `send` / `do it` / `confirm` reply means proceed. Anything
else (including silence) means the user is reconsidering — don't act.
