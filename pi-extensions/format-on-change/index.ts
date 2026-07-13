import type {
  ExtensionAPI,
  ExtensionContext,
  ToolResultEvent,
} from "@earendil-works/pi-coding-agent";

const formatters = [
  { ext: ".nix", cmd: "nixfmt", args: (f: string) => [f] },
  { ext: ".tsx", cmd: "npx", args: (f: string) => ["prettier", "--write", f] },
  { ext: ".ts", cmd: "npx", args: (f: string) => ["prettier", "--write", f] },
  { ext: ".html", cmd: "deno", args: (f: string) => ["fmt", f] },
  { ext: ".js", cmd: "deno", args: (f: string) => ["fmt", f] },
  { ext: ".md", cmd: "deno", args: (f: string) => ["fmt", f] },
  {
    ext: ".mli",
    cmd: "ocamlformat",
    args: (f: string) => ["--enable-outside-detected-project", "-i", f],
  },
  {
    ext: ".ml",
    cmd: "ocamlformat",
    args: (f: string) => ["--enable-outside-detected-project", "-i", f],
  },
  { ext: ".fnl", cmd: "fnlfmt", args: (f: string) => ["--fix", f] },
  { ext: ".lua", cmd: "stylua", args: (f: string) => [f] },
];

export default function (pi: ExtensionAPI) {
  // Format each file right after its write/edit executes. Pi's tool_result fires
  // after the tool runs and carries toolName + input. Mirrors Claude's PostToolUse.
  pi.on(
    "tool_result",
    async (event: ToolResultEvent, ctx: ExtensionContext) => {
      if (event.isError) return undefined;
      if (event.toolName !== "write" && event.toolName !== "edit")
        return undefined;
      const file = (event.input.path as string) || "";
      const fmt = formatters.find((f) => file.endsWith(f.ext));
      if (!fmt) return undefined;
      // Formatting is best-effort: a non-zero exit (formatter ran but failed) or a
      // rejection (binary not on PATH) must never crash the callback or block the edit.
      try {
        const { code, stderr } = await pi.exec(fmt.cmd, fmt.args(file));
        if (code !== 0 && ctx.hasUI)
          ctx.ui.notify(fmt.cmd + " failed: " + stderr.trim(), "warning");
      } catch (err) {
        if (ctx.hasUI)
          ctx.ui.notify(fmt.cmd + " not run: " + String(err), "warning");
      }
      return undefined;
    },
  );
}
