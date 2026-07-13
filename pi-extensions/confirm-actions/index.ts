import type {
  ExtensionAPI,
  ExtensionContext,
  ToolCallEvent,
} from "@earendil-works/pi-coding-agent";

// Read-only git subcommands that may run without confirmation.
const READONLY_GIT = new Set([
  "status",
  "diff",
  "log",
  "show",
  "blame",
  "ls-files",
  "rev-parse",
  "describe",
  "shortlog",
]);

type BashVerdict =
  { verdict: "allow" } | { verdict: "confirm"; reason: string };

function classifyBash(cmd: string): BashVerdict {
  const trimmed = cmd.trim();
  // Any shell operator (pipe, chain, redirect, substitution) -> cannot classify -> ask.
  if (/[|&;<>`]|\$\(|\n/.test(trimmed))
    return { verdict: "confirm", reason: "Run: " + cmd };
  const tokens = trimmed.split(/\s+/);
  const head = tokens[0];

  // Pure-read commands only. Raw `find` is intentionally NOT here: it can mutate
  // via -delete/-exec/-fprint*, and a flag blacklist can't be made exhaustive.
  // Pi's own find tool sidesteps this by running `fd` with a glob, never raw find;
  // file searches should use that tool, which is auto-allowed in READONLY_TOOLS.
  if (head === "ls" || head === "grep") return { verdict: "allow" };

  if (head === "rg") {
    // Only auto-allow flagless rg. Any --flag (e.g. --pre, --hostname-bin)
    // can execute arbitrary commands and must be confirmed.
    if (/\s--/.test(" " + trimmed + " "))
      return { verdict: "confirm", reason: "Run: " + cmd };
    return { verdict: "allow" };
  }

  // These commands have no flags or built-ins that can mutate.
  // Any shell-level mutation (redirect, pipe, subshell) is already
  // caught by the operator regex above.
  if (
    head === "cat" ||
    head === "which" ||
    head === "type" ||
    head === "readlink" ||
    head === "wc" ||
    head === "echo"
  )
    return { verdict: "allow" };

  if (head === "git") {
    const sub = tokens.slice(1).find((t) => !t.startsWith("-"));
    if (sub !== undefined && READONLY_GIT.has(sub)) return { verdict: "allow" };
  }

  return { verdict: "confirm", reason: "Run: " + cmd };
}

// Built-in tools that only read; never need confirmation.
const READONLY_TOOLS = new Set(["read", "ls", "grep", "find"]);

// Extension tools that only read; never need confirmation.
const READONLY_EXT_TOOLS = new Set(["web_search"]);

// Returns a human-readable reason if the call needs confirmation, else null (auto-allow).
function confirmReason(event: ToolCallEvent): string | null {
  const tool = event.toolName;
  if (READONLY_TOOLS.has(tool)) return null;
  if (READONLY_EXT_TOOLS.has(tool)) return null;
  if (tool === "bash") {
    const cmd = (event.input.command as string) || "";
    const v = classifyBash(cmd);
    if (v.verdict === "allow") return null;
    return v.reason;
  }
  if (tool === "write" || tool === "edit") {
    return tool + ": " + ((event.input.path as string) || "");
  }
  return "Tool: " + tool;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    const reason = confirmReason(event);
    if (!reason) return undefined;
    if (!ctx.hasUI)
      return { block: true, reason: "Blocked (no UI to confirm): " + reason };
    await pi.exec("afplay", ["/System/Library/Sounds/Glass.aiff"]);
    const ok = await ctx.ui.confirm("Allow this action?", reason);
    if (!ok) return { block: true, reason: "Denied by user" };
    return undefined;
  });
}
