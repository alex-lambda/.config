import { isAbsolute, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Branch glyph, same as POWERLEVEL9K_VCS_BRANCH_ICON in ~/.p10k.zsh. */
const BRANCH_ICON = "";

/** Separator between right-hand segments; matches p10k's multiline gap char. */
const SEP = " · ";

/** The theme ships a color per thinking level — use them instead of a flat one. */
const THINKING_COLORS = {
	off: "thinkingOff",
	minimal: "thinkingMinimal",
	low: "thinkingLow",
	medium: "thinkingMedium",
	high: "thinkingHigh",
	xhigh: "thinkingXhigh",
	max: "thinkingMax",
} as const;

/** Visible width, ignoring ANSI SGR sequences. */
function vw(text: string): number {
	// eslint-disable-next-line no-control-regex
	return text.replace(/\x1b\[[0-9;]*m/g, "").length;
}

/** Match the built-in footer's token formatting. */
function formatTokens(count: number): string {
	if (count < 1000) return count.toString();
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
	return `${Math.round(count / 1000000)}M`;
}

/** Collapse $HOME to ~, leaving paths outside home untouched. */
function formatCwd(cwd: string, home: string | undefined): string {
	if (!home) return cwd;
	const rel = relative(resolve(home), resolve(cwd));
	const insideHome = rel === "" || (rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel));
	if (!insideHome) return cwd;
	return rel === "" ? "~" : `~${sep}${rel}`;
}

export default function (pi: ExtensionAPI) {
	// Set while a footer is mounted, so a thinking-level change repaints right away.
	let requestRender: (() => void) | undefined;

	pi.on("thinking_level_select", async () => {
		requestRender?.();
	});

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter((tui, theme, footerData) => ({
			invalidate() {},

			render(width: number): string[] {
				// --- left: cwd  branch ---
				// Path in the theme's link blue (POWERLEVEL9K_DIR_FOREGROUND=4), leaf
				// bolded so the directory you're actually in reads first.
				const cwd = formatCwd(ctx.sessionManager.getCwd(), process.env.HOME || process.env.USERPROFILE);
				const cut = cwd.lastIndexOf(sep);
				const parent = cut < 0 ? "" : cwd.slice(0, cut + 1);
				const leaf = cut < 0 ? cwd : cwd.slice(cut + 1);
				const path = (parent ? theme.fg("mdLink", parent) : "") + theme.bold(theme.fg("mdLink", leaf));
				let leftPlain = cwd;
				let left = path;

				const branch = footerData.getGitBranch();
				if (branch) {
					// Green for a normal branch, warning for detached HEAD — same
					// convention as POWERLEVEL9K_VCS_CLEAN_FOREGROUND=2.
					const branchText = `${BRANCH_ICON} ${branch}`;
					leftPlain += ` ${branchText}`;
					left += ` ${theme.fg(branch === "detached" ? "warning" : "success", branchText)}`;
				}

				// --- right: model · thinking · context% / window · tokens ---
				// Track plain text alongside colored so we can measure and trim safely.
				// `drop` orders the segments we shed when the line won't fit (highest first).
				const parts: { plain: string; colored: string; drop: number }[] = [];
				const push = (plain: string, colored: string, drop: number) => parts.push({ plain, colored, drop });

				const modelId = ctx.model?.id ?? "no-model";
				push(modelId, theme.fg("accent", modelId), 0);

				if (ctx.model?.reasoning) {
					const level = pi.getThinkingLevel();
					const label = level === "off" ? "thinking off" : level;
					push(label, theme.fg(THINKING_COLORS[level], label), 2);
				}

				const usage = ctx.getContextUsage();
				const window = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
				// percent is null right after compaction, until the next response.
				const pct = usage?.percent ?? null;
				const ctxText = `${pct === null ? "?" : pct.toFixed(1) + "%"}/${formatTokens(window)}`;
				push(
					ctxText,
					pct !== null && pct > 90
						? theme.fg("error", ctxText)
						: pct !== null && pct > 70
							? theme.fg("warning", ctxText)
							: theme.fg("muted", ctxText),
					1,
				);

				let input = 0;
				let output = 0;
				for (const entry of ctx.sessionManager.getEntries()) {
					if (entry.type === "message" && entry.message.role === "assistant") {
						input += entry.message.usage.input;
						output += entry.message.usage.output;
					} else if (entry.type === "message" && entry.message.role === "toolResult" && entry.message.usage) {
						input += entry.message.usage.input;
						output += entry.message.usage.output;
					} else if ((entry.type === "branch_summary" || entry.type === "compaction") && entry.usage) {
						input += entry.usage.input;
						output += entry.usage.output;
					}
				}
				if (input || output) {
					const up = formatTokens(input);
					const down = formatTokens(output);
					push(
						`↑${up} ↓${down}`,
						`${theme.fg("dim", "↑")}${theme.fg("muted", up)} ${theme.fg("dim", "↓")}${theme.fg("muted", down)}`,
						3,
					);
				}

				// Shed segments (tokens, then thinking, then context) until the right side fits.
				const joined = () => parts.reduce((w, p, i) => w + p.plain.length + (i ? SEP.length : 0), 0);
				while (parts.length > 1 && joined() >= width) {
					let worst = 0;
					for (let i = 1; i < parts.length; i++) {
						if (parts[i].drop > parts[worst].drop) worst = i;
					}
					parts.splice(worst, 1);
				}

				const right = parts.map((p) => p.colored).join(theme.fg("dim", SEP));
				const rightW = joined();
				if (rightW >= width) {
					// Only the model is left and it still doesn't fit — hard-truncate it.
					const plain = parts[0].plain.slice(0, Math.max(0, width));
					return [theme.fg("accent", plain)];
				}

				let leftOut = left;
				let leftW = leftPlain.length;
				if (width - rightW - leftW < 1) {
					// Shed the branch first, then keep the tail of the path (the meaningful part).
					leftOut = path;
					leftW = cwd.length;
				}
				if (width - rightW - leftW < 1) {
					const room = width - rightW - 1;
					leftOut = room > 1 ? theme.fg("dim", "…" + cwd.slice(-(room - 1))) : "";
					leftW = vw(leftOut);
				}
				return [leftOut + " ".repeat(Math.max(1, width - leftW - rightW)) + right];
			},

			// Re-render when the branch changes; token/context updates already
			// trigger a render via message events.
			dispose: (() => {
				requestRender = () => tui.requestRender();
				const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
				return () => {
					requestRender = undefined;
					unsubscribe();
				};
			})(),
		}));
	});
}
