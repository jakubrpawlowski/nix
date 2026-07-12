import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { Text } from "@earendil-works/pi-tui";
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
}
