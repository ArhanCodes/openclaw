---
name: morning-brief
description: Daily 7am summary of email, calendar, WhatsApp, news, and reminders. Plain-text formatting for WhatsApp delivery. Designed to be cron-driven.
metadata: { "openclaw": { "emoji": "🌅" } }
---

# Morning brief

Run when the user says "morning brief", "what's going on", "give me my brief",
or fired by a cron job at 07:00 local.

## What to gather (in this order)

1. **Email**: `mail_recent_unread` (limit ~25) — pull unread from every account
2. **Calendar**: `calendar_list_events` for today (timeMin=now, timeMax=end of day)
3. **WhatsApp**: `whatsapp_recent_inbound` (lookbackHours=12) — overnight DMs.
   Each item has a `fromName` field that is the resolved contact name.
   **Use `fromName` when describing who messaged. Never show raw phone numbers
   or `@lid`/`@s.whatsapp.net` JIDs.**
4. **News**: `news_top_headlines` (limit=4) — world + regional headlines
5. **Reminders** (optional): `reminders_list` for what's due today

## Output format

Output TWO parts separated by `---FULL BRIEF---`:

```
HEADLINE: <one line, ≤140 chars, e.g. "3 urgent emails · 5 events today · 2 unread WhatsApps">

---FULL BRIEF---

Morning brief — <today's date, e.g. Sun Apr 26>

Today's schedule
• 9:00am Meeting with Dom
• 1:00pm Lunch
(3-6 lines max, time + title + who. Plain text. No markdown.)

Inbox (URGENT / NEEDS REPLY only — skip newsletters and noise)
• From <person/sender>: subject — one-line context

WhatsApp (only DMs that need a response)
• <fromName>: gist of their message

News
• <source>: headline — one-line gist
(top 3-4 across sources)

Reminders due today (if any)
• <title>
```

## Hard rules for the FULL BRIEF section

- **Plain text only.** No `**bold**`, no `#` headers, no `*` bullets — use `•` (bullet) or `-` (dash). WhatsApp renders these correctly; markdown shows literal asterisks.
- **Always use `fromName`** for WhatsApp senders — never show phone numbers.
- **Under 300 words total.** Omit any empty section entirely.
- **Skip noise**: newsletters, automated alerts, marketing — only flag real action items.

## Why this format exists

The HEADLINE goes into a macOS notification (~140 char budget). The FULL BRIEF goes to WhatsApp as a self-DM and into long-term memory as a journal entry. Splitting via the sentinel keeps both renderings clean.
