/**
 * @openclaw/news-headlines
 *
 * Pulls top headlines from public RSS feeds and exposes a single tool the
 * agent can call. Designed for the morning brief but useful any time the
 * user asks "what's in the news".
 *
 * Why RSS instead of NewsAPI/Bing/etc.: free, no API key, no per-day quota,
 * and the BBC World feed alone covers more world news than most paid APIs.
 *
 * Default feeds: BBC World + Khaleej Times (Gulf/UAE focus). Override via
 * config.feeds in openclaw.json.
 */

import { Type } from "typebox";
import { definePluginEntry, type OpenClawPluginApi } from "openclaw/plugin-sdk/core";

type Headline = { source: string; title: string; summary: string; pubDate: string };
type Feed = { name: string; url: string };

const DEFAULT_FEEDS: Feed[] = [
  { name: "BBC World", url: "https://feeds.bbci.co.uk/news/world/rss.xml" },
  { name: "Khaleej Times", url: "https://www.khaleejtimes.com/rss" },
];

export default definePluginEntry({
  id: "news-headlines",
  name: "News Headlines",
  description: "RSS-backed news headlines for the morning brief. No API key required.",

  register(api: OpenClawPluginApi) {
    const cfg = (api.pluginConfig ?? {}) as {
      feeds?: Feed[];
      limitPerFeed?: number;
    };
    const feeds = cfg.feeds && cfg.feeds.length > 0 ? cfg.feeds : DEFAULT_FEEDS;
    const defaultLimit = cfg.limitPerFeed ?? 6;

    api.logger.info(
      `news-headlines: ready (${feeds.length} feeds: ${feeds.map((f) => f.name).join(", ")})`,
    );

    api.registerTool(
      {
        name: "news_top_headlines",
        label: "News Top Headlines",
        description:
          "Fetch top news headlines from configured RSS feeds (default: BBC World + Khaleej Times). " +
          "Use for the morning brief news section, or when the user asks 'what's in the news'.",
        parameters: Type.Object({
          limit: Type.Optional(
            Type.Number({ description: `Headlines per source (default ${defaultLimit})` }),
          ),
          source: Type.Optional(
            Type.String({
              description: "If set, only fetch this one feed by exact name (e.g. 'BBC World').",
            }),
          ),
        }),
        async execute(_id, params) {
          const { limit = defaultLimit, source } = params as { limit?: number; source?: string };
          const targets = source ? feeds.filter((f) => f.name === source) : feeds;
          if (targets.length === 0) {
            return {
              content: [{ type: "text", text: `No matching feed: ${source}` }],
              details: { error: "no_match" },
            };
          }
          const all = await Promise.all(targets.map((f) => fetchFeed(f, limit)));
          const flat = all.flat();
          const text = flat
            .map((h) => `[${h.source}] ${h.title}${h.summary ? " — " + h.summary.slice(0, 160) : ""}`)
            .join("\n");
          return {
            content: [{ type: "text", text: text || "(no headlines)" }],
            details: { count: flat.length, headlines: flat },
          };
        },
      },
      { name: "news_top_headlines" },
    );

    api.registerService({
      id: "news-headlines",
      start: () => api.logger.info("news-headlines: started"),
      stop: () => api.logger.info("news-headlines: stopped"),
    });
  },
});

// ---------------------------------------------------------------------------
// RSS fetching — tiny parser, no XML lib dependency
// ---------------------------------------------------------------------------

async function fetchFeed(feed: Feed, limit: number): Promise<Headline[]> {
  try {
    const res = await fetch(feed.url, {
      headers: { "User-Agent": "openclaw-news-headlines/0.1" },
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) return [];
    const xml = await res.text();
    return parseRSS(xml, feed.name).slice(0, limit);
  } catch {
    return [];
  }
}

function parseRSS(xml: string, source: string): Headline[] {
  const items = xml.split("<item").slice(1).map((s) => "<item" + s);
  const out: Headline[] = [];
  for (const raw of items) {
    const endIdx = raw.indexOf("</item>");
    if (endIdx === -1) continue;
    const body = raw.slice(0, endIdx);
    const title = stripCDATA(extractTag(body, "title") ?? "");
    if (!title) continue;
    out.push({
      source,
      title,
      summary: stripCDATA(extractTag(body, "description") ?? ""),
      pubDate: extractTag(body, "pubDate") ?? "",
    });
  }
  return out;
}

function extractTag(body: string, tag: string): string | null {
  const open = `<${tag}>`;
  const close = `</${tag}>`;
  const s = body.indexOf(open);
  if (s === -1) return null;
  const e = body.indexOf(close, s + open.length);
  if (e === -1) return null;
  return body.slice(s + open.length, e).trim();
}

function stripCDATA(s: string): string {
  let t = s;
  if (t.startsWith("<![CDATA[")) t = t.slice(9);
  if (t.endsWith("]]>")) t = t.slice(0, -3);
  // Strip inline HTML
  t = t.replace(/<[^>]+>/g, "");
  // Decode common entities
  for (const [k, v] of [
    ["&amp;", "&"], ["&lt;", "<"], ["&gt;", ">"], ["&quot;", '"'],
    ["&#39;", "'"], ["&apos;", "'"], ["&nbsp;", " "],
  ] as const) {
    t = t.replaceAll(k, v);
  }
  return t.trim();
}
