# news-headlines

Pulls news headlines from public RSS feeds. Designed for the morning brief
but useful anywhere you'd want world/regional news inside an agent loop.

## Why this exists

Most "news API" services charge a per-month subscription, rate-limit you to
~100 requests/day on free tiers, and often have worse coverage than a
public RSS feed. RSS is **free, no key, no quota, decades-stable**.

Default sources:
- BBC World — `https://feeds.bbci.co.uk/news/world/rss.xml`
- Khaleej Times — `https://www.khaleejtimes.com/rss` (Gulf/UAE focus)

Override via config:
```json
{
  "news-headlines": {
    "feeds": [
      {"name": "Hacker News", "url": "https://hnrss.org/frontpage"},
      {"name": "Reuters", "url": "https://www.reutersagency.com/feed/"}
    ],
    "limitPerFeed": 8
  }
}
```

## Tool

`news_top_headlines(limit?, source?)` — fetch top headlines.

- `limit`: per-feed cap (default 6)
- `source`: optional filter to one feed by exact name

Returns the headlines as both a Markdown-friendly text block and structured
`details.headlines` for the agent to reformat.

## Use in skills

The bundled `morning-brief.md` skill calls this with `limit=4` for a tight
news section in the daily brief. Add it to any other skill the same way.
