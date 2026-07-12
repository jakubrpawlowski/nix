import { describe, it } from "node:test";
import assert from "node:assert";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  clean,
  decodeUrl,
  scrapeSnippets,
  scrapeTitles,
  zipResults,
} from "../ddg-parser.js";

const html = readFileSync(
  join(import.meta.dirname, "ddg-fixture.html"),
  "utf8",
);

describe("ddg-parser", () => {
  it("parses real DDG results correctly", () => {
    const titles = scrapeTitles(html);
    const snippets = scrapeSnippets(html, titles.length);
    const results = zipResults(snippets)(titles);

    assert.ok(results.length >= 2, "expected at least 2 results");

    assert.deepEqual(results[0], {
      title: "Nix Flakes, Part 1: An introduction and tutorial - Tweag",
      url: "https://www.tweag.io/blog/2020-05-25-flakes/",
      snippet:
        "An introduction to Nix flakes and a tutorial on how to use them.",
    });

    assert.deepEqual(results[1], {
      title: "Nix flakes",
      url: "https://zero-to-nix.com/concepts/flakes/",
      snippet:
        "1. Get Nix running on your system 2. Run a program with Nix 3. Explore Nix development environments 4. Build a package using Nix 5. Search for Nix packages 6. Turn your project into a flake 7. Uninstall Nix (if necessary) 8. Learn more",
    });
  });

  it("decodeUrl extracts real URL from DDG redirect", () => {
    assert.equal(
      decodeUrl("//duckduckgo.com/l/?uddg=https://example.com&rut=abc"),
      "https://example.com",
    );
    // Plain URL without DDG redirect — passes through unchanged
    assert.equal(decodeUrl("https://plain.com"), "https://plain.com");
  });

  it("clean strips tags and decodes entities", () => {
    assert.equal(clean("<b>hello</b> <i>world</i>"), "hello world");
    assert.equal(clean("a &amp; b &#x27;24"), "a & b '24");
  });
});
