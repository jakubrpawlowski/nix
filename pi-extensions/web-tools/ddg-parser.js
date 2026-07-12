/**
 * DDG HTML result page (simplified):
 *   <h2 class="result__title">
 *     <a href="//ddg.co/l/?uddg=https://example.com">Example Site</a>
 *
 * m[1] = href value (DDG redirect URL)
 * m[2] = text inside <a> tag (the title)
 */
const titleRe =
  /class="result__title"[^>]*>\s*<a[^>]*href="([^"]+)"[^>]*>([^<]+)/g;

/**
 * DDG snippet HTML:
 *   <a class="result__snippet" href="...">The snippet text here</a>
 *
 * m[1] = everything inside the <a> tag up to </a>
 */
const snipRe = /class="result__snippet"[^>]*>([\s\S]*?)<\/a>/g;

/**
 * @typedef {{ title: string; url: string; snippet: string }} Result
 */

const entityMap = {
  "&amp;": "&",
  "&lt;": "<",
  "&gt;": ">",
  "&quot;": '"',
  "&#39;": "'",
  "&#x27;": "'",
};

/**
 * Strip HTML tags and decode common entities.
 * "<b>hello</b> &amp; world &#39;24" → "hello & world '24"
 * @param {string} s
 * @returns {string}
 */
export function clean(s) {
  return s
    .replace(/<[^>]+>/g, "")
    .replace(/&(?:amp|lt|gt|quot|#x27|#39);/g, (m) => entityMap[m] ?? m)
    .trim();
}

/**
 * DDG wraps result URLs in its own redirect. Extract the real one.
 * @param {string} raw
 * @returns {string}
 */
export function decodeUrl(raw) {
  return new URL(raw, "https://duckduckgo.com").searchParams.get("uddg") ?? raw;
}

/**
 * Extract title + URL from raw DDG results HTML.
 * @param {string} html
 * @returns {Omit<Result, "snippet">[]}
 */
export function scrapeTitles(html) {
  return [...html.matchAll(titleRe)].slice(0, 10).map((m) => ({
    title: clean(m[2]),
    url: decodeUrl(m[1]),
  }));
}

/**
 * Extract snippets from raw DDG results HTML.
 * @param {string} html
 * @param {number} count - how many snippets to return
 * @returns {string[]}
 */
export function scrapeSnippets(html, count) {
  return [...html.matchAll(snipRe)]
    .slice(0, count)
    .map((m) => clean(m[1]));
}

/**
 * Zip titles with their corresponding snippets.
 * @param {string[]} snippets
 * @returns {(titles: Omit<Result, "snippet">[]) => Result[]}
 */
export function zipResults(snippets) {
  return (titles) =>
    titles.map((t, i) => ({ ...t, snippet: snippets[i] ?? "" }));
}
