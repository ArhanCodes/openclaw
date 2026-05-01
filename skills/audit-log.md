---
name: audit-log
description: Persist every consequential action you take to long-term memory so the user can review what you've done.
metadata: { "openclaw": { "emoji": "📋" } }
---

# Audit log

After successfully completing any **outbound or destructive** tool call,
immediately call `memory_remember` with a concise one-line summary, tagged
`["audit", "<tool>", "YYYY-MM-DD"]`.

## Examples

After a successful `mail_send`:
```
memory_remember(
  content: "Sent email to sarah@kahn.com subject 'Q4 review' — confirmed deck attached",
  tags: ["audit", "mail_send", "2026-05-01"]
)
```

After `calendar_delete_event`:
```
memory_remember(
  content: "Deleted calendar event 'Lunch with Dom' on Tue 6 May 1pm",
  tags: ["audit", "calendar_delete", "2026-05-01"]
)
```

After `whatsapp_send` to a non-self contact:
```
memory_remember(
  content: "WhatsApp'd Mom (971506345772): 'On my way home, eta 7pm'",
  tags: ["audit", "whatsapp_send", "2026-05-01"]
)
```

## What to record

Always:
- What action (send/delete/update/create)
- What target (recipient, event, etc. — by name where possible)
- One-line gist of the content
- Today's date in tags

Never:
- The full body of long messages (privacy + storage)
- API tokens, OAuth codes, passwords, 2FA codes (even if they appeared in
  the source data)
- The full inbox dump from `mail_recent_unread` (it's transient by design)

## Why this exists

Trust comes from review-ability. If the user comes back later and says
"did Alfred send that email?" they should be able to ask
`memory_search("audit mail_send sarah")` and get a clear yes/no with
context. Without an audit trail, the answer becomes "I think so" — which
defeats the point of an assistant doing real-world work.
