/**
 * alpha — image splash for pi, ported from ~/.config/nvim/lua/alex/plugins/alpha.lua.
 *
 * Renders the same braille art alpha-nvim shows, via `ascii-image-converter`, centered
 * above the chat. alpha.lua's `hl = "Statement"` maps onto pi's theme accent color.
 */
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Shared with alpha-nvim, so both welcome screens draw from one set of images. */
const ASSET_DIR = join(homedir(), ".config", "nvim", "lua", "alex", "plugins", "src_imgs");

/**
 * Per-image converter flags. This table is the source of truth for how pi renders each
 * image — alpha.lua keeps its own settings for nvim, and the two are deliberately separate
 * even though both read from src_imgs.
 *
 * `-b` is braille, `-d` is width,height in cells. Two gotchas worth keeping written down:
 *
 *   - `-c` is --complex, not colour, and braille overrides it. Dropped here.
 *   - `--dither` and `--threshold` are mutually exclusive; --dither wins. Dithering suits
 *     photographs, where preserving midtone density matters. On white-on-black line art it
 *     destroys the drawing, so those entries set an explicit threshold instead.
 *   - `-n` inverts the finished dot set, not the source pixels, so it does not shift the
 *     threshold along with it. Adding `-n` flips the rule from "ink where luminance >
 *     threshold" to "ink where luminance < threshold" — needed for dark-on-light sources,
 *     and the threshold is then read the other way round from everything else here.
 *
 * Threshold is then the stroke-weight dial, and it cuts both ways from the 128 default.
 * Downscaling smears each stroke into a soft ramp of dot values; where you cut that ramp
 * decides how much survives. Below 128 thickens lines and rescues faint ones — sparse
 * stipple needs this or it vanishes entirely. Above 128 keeps only the core and thins
 * them. Each line-art entry records where it landed and why.
 */
const IMAGES = {
	// White stipple on black. The dots are ~3px, so downscaling averages them to a dim
	// grey that the default cutoff drops entirely — hence the low threshold. Lower is denser.
	//
	// This asset is border-cropped by ~/.pi/agent/assets/alpha/crop-border.py. The original
	// 1319x1127 frame was only 55% x 46% content, so ~80% of the dot budget was empty
	// margin; cropping to 776x558 gave the galaxy itself ~4x the pixel area.
	//
	// 114x41 is the aspect, not a ceiling: a braille cell is 2 dots wide by 4 tall, so
	// W chars = 2W dots but H chars = only 4H dots. 114/41 = 2.78 = 2 x (776/558).
	galaxy: { file: "galaxy.png", flags: ["--threshold", "30"], width: 114, height: 41 },
	// Second pass at this drawing (~/Downloads/thickgoldenratio.png), replacing an earlier
	// version whose construction lines (grid, dashed top guide, inner square) were only
	// ~3-5px against the spiral's ~12px stroke — thin enough that downscaling eroded them
	// well before the spiral, needing threshold pulled down to 70 just to rescue the dots.
	// This redraw puts the guides at roughly the spiral's own stroke weight, so there's no
	// thin line left to rescue.
	//
	// Source is 1205x880 with the drawing centered in a huge letterboxed margin (content
	// bbox 552x716, i.e. portrait) rather than framed tight like the original, so this took
	// the dna crop path instead: tight on both axes, then padded back out to a landscape
	// chars-aspect.
	//   crop-border.py ~/Downloads/thickgoldenratio.png <dst> 30 0.06 both 2.73
	// 552x716 -> tight-cropped 618x802 (6% pad) -> padded to 1095x802 to hit 2.73 chars-aspect,
	// matching the original's on-screen size.
	//
	// Threshold: even thick strokes still downscale to a soft ramp, so this isn't a free pass
	// to use the 128 default. Measured at 112x41, default gives 1463 lit dots vs 1741 at 90 —
	// 90 is the value that keeps the grid lines a clean solid double-dot instead of dashing
	// at the corners, without puffing the spiral into a blob (that starts under ~60).
	// 112/41 = 2.73 = 2 x (1095/802).
	goldenratio: { file: "goldenratio.png", flags: ["--threshold", "90"], width: 112, height: 41 },
	// The only portrait drawing here, which makes it the one case where cropping is not enough.
	// fitDimensions fills the height until the aspect clears paneWidth/rows — about 2.1:1 in an
	// 83-col split, 4.2:1 at full width — and a tall image never gets there, so it claimed all
	// 40 rows as a ~27-col ribbon. Cropping the dead sides only made that worse. So this one is
	// cropped tight and then padded back out to the landscape aspect the others already have:
	//   crop-border.py ~/Downloads/dna.png <dst> 30 0.06 x 2.75
	// x-only crop (the y margins were already nil: 0px top, 22px bottom) takes 750x798 down to
	// 272x798, then the trailing 2.75 pads it to 1097x798. That lands it at 83x30 in a split
	// pane, in step with galaxy and goldenratio. At full 170 width height still binds and it
	// fills the pane, same as they do.
	//
	// Threshold is low here for the opposite reason to galaxy: not to rescue faint dots, but
	// because padding shrinks the helix to ~20 cols and thin strokes break up at that size.
	// 60 keeps the strands solid; 100 thins them; past 170 the rungs between them drop out.
	dna: { file: "dna.png", flags: ["--threshold", "60"], width: 110, height: 40 },
	// The one dark-on-light source here, and the only entry that needs `-n`: flat grey field
	// (luminance 114), near-black figures (0-4), white outline around them (229+). Without
	// inversion the grey field is what lights up and the figures come out as holes.
	//
	// With `-n` the threshold reads backwards — ink where luminance is *below* it — so it has
	// to sit between the figures and the field. 95 is near the top of that 4..114 gap, which is
	// what keeps the limbs intact: the white outline is excluded, and downscaling averages it
	// into the figure edge, so a lower cut erodes the thin parts (60 already nibbles the
	// right-hand arm). Anything at or above 114 floods the field.
	//
	// Cropped by ~/.pi/agent/assets/alpha/crop-border.py. The 1152x1152 source was mostly
	// margin — the figures sat in 620x354 of it:
	//   crop-border.py ~/Downloads/whitepeople.png <dst> 120 0.06 both
	// The 120 threshold is doing something specific: it is above the grey field, so the bbox
	// scan latches onto the white outline alone, which traces exactly the figures' extent.
	// 694x396 -> 140/40 = 3.5 = 2 x (694/396).
	people: { file: "people.png", flags: ["-n", "--threshold", "95"], width: 140, height: 40 },
	// White brush line on a black field, so it takes the plain rule — no `-n`, unlike people.
	// The source is portrait (869x1000) but the drawing inside it is not: the penguin and its
	// ring sit in a 741x436 band with the whole bottom third empty. Cropping is what turns it
	// landscape, so no padding is needed here:
	//   crop-border.py ~/Downloads/penguin.png <dst> 120 0.06 both
	// The 120 threshold sits in the empty gap between the black field (0) and the white stroke
	// (255), so the bbox scan traces the ink alone. 829x488 -> 136/40 = 3.4 = 2 x (829/488).
	//
	// Threshold is set by the *smallest* render, not the largest, and SCALE is what decides how
	// small that is. At the sizes 0.6 produces the two ends of the range disagree: around 68x20
	// the plain 128 default and 90 are indistinguishable — the strokes are wide enough that the
	// cut barely matters — but down at the 49x14 of an 83-col split they are only 1-2 dots wide,
	// and 90 keeps the ring's right tip and the head outline solid where 128 leaves them stubby.
	// So 90, which costs nothing at the top of the range and buys the bottom of it.
	//
	// Slack in both directions from there, measured at 136x40: 30 fattens every stroke by a dot
	// and swells the stubs where the ring passes behind the body into blobs, and 190 still holds
	// intact. Raise it only after checking the split-pane size — that is where it breaks first.
	penguin: { file: "penguin.png", flags: ["--threshold", "90"], width: 136, height: 40 },
	spiderlily: { file: "spiderlily4.jpeg", flags: ["--dither"], width: 100, height: 35 },
	butterfly: { file: "butterfly.png", flags: ["--dither"], width: 50, height: 25 },
	koifish: { file: "koifish.png", flags: [], width: 40, height: 20 },
	ghiblicat: { file: "ghiblicat.png", flags: [], width: 45, height: 20 },
	jellyfish: { file: "jellyfish.png", flags: [], width: 100, height: 50 },
} as const;

/** Which image to show. Swap this to change the splash. */
const ACTIVE_IMAGE: keyof typeof IMAGES = "goldenratio";

/** alpha.lua used hl = "Statement" for the art. */
const ART_COLOR = "accent";

/**
 * Air above and below the art. The lower budget includes the quote and one blank row on
 * either side of it. These come out of the row budget in fitDimensions as well as the
 * render, so raising them shrinks the art a little too.
 */
const PADDING_ABOVE = 4;
const PADDING_BELOW = 3;

const LONG_QUOTE = '"Nature does not hurry, yet everything is accomplished." - Laozi';
const SHORT_QUOTE = '"Nature does not hurry." - Laozi';
const QUOTE_COLOR = "dim";

/** Rows left for the editor and footer, so the whole splash lands on first paint. */
const RESERVED_ROWS = 4;

/**
 * Fraction of the available space the art takes. At 1 it fills the pane and reads as a
 * backdrop; below that it pulls in to a piece centered above the chat, and the rows it
 * gives up go back to the conversation. 0.6 puts a 40-row terminal at 58x17.
 */
const SCALE = 0.6;

/**
 * Rows the art will not shrink below, taken instead out of the space SCALE was giving back.
 * Braille only has 2x4 dots per cell, so cutting the cell count cuts the linear resolution
 * with it, and a percentage alone bottoms out on short terminals: at 0.6 a 30-row window
 * lands on 37x11, where the penguin's head outline has already broken into dashes. 14 rows
 * (~48 cols at this aspect) is the smallest that still holds it together, and it is the same
 * size an 83-col split arrives at from the other direction.
 *
 * Where this floor belongs depends on the image — sparser art like galaxy bottoms out sooner,
 * so re-check it when swapping ACTIVE_IMAGE. It yields when the budget itself is smaller,
 * so a genuinely tiny window still gets a splash rather than an overflowing one.
 */
const MIN_ART_HEIGHT = 14;

// eslint-disable-next-line no-control-regex
const SGR = /\x1b\[[0-9;]*m/g;

/** Visible width, ignoring ANSI SGR sequences. */
function vw(text: string): number {
	return [...text.replace(SGR, "")].length;
}

/**
 * Size the art to SCALE of the space available, preserving the image's aspect. The configured
 * dimensions are a ratio rather than a ceiling: even at full terminal size the braille grid
 * is well under the source resolution, so a bigger terminal should still buy more detail —
 * SCALE shrinks the box being filled, it does not pin the art to a fixed size.
 */
function fitDimensions(width: number, rows: number): { width: number; height: number } {
	const image = IMAGES[ACTIVE_IMAGE];
	const aspect = image.width / image.height;
	const rowBudget = rows - RESERVED_ROWS - PADDING_ABOVE - PADDING_BELOW;
	const maxHeight = Math.max(
		6,
		Math.min(MIN_ART_HEIGHT, rowBudget),
		Math.round(rowBudget * SCALE),
	);
	const maxWidth = Math.max(16, Math.round((width - 2) * SCALE));

	// Rows are the binding constraint on most terminals; fall back to width when they aren't.
	const fromHeight = Math.round(maxHeight * aspect);
	if (fromHeight <= maxWidth) return { width: fromHeight, height: maxHeight };
	return { width: maxWidth, height: Math.max(6, Math.round(maxWidth / aspect)) };
}

/** Run ascii-image-converter. Returns null when the binary or image is missing. */
async function renderArt(
	pi: ExtensionAPI,
	width: number,
	height: number,
): Promise<string[] | null> {
	const image = IMAGES[ACTIVE_IMAGE];
	const result = await pi.exec(
		"ascii-image-converter",
		[join(ASSET_DIR, image.file), "-b", ...image.flags, "-d", `${width},${height}`],
		{ timeout: 5000 },
	);
	if (result.code !== 0) return null;
	const lines = result.stdout.replace(/\n$/, "").split("\n");
	return lines.length > 0 && lines.some((line) => line.trim() !== "") ? lines : null;
}

export default function alpha(pi: ExtensionAPI) {
	/** Cached art, plus the width it was generated for so resizes can regenerate. */
	let art: string[] | null = null;
	let artWidth = 0;
	let generating = false;

	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		const rows = process.stdout.rows ?? 40;
		const columns = process.stdout.columns ?? 80;
		const initial = fitDimensions(columns, rows);
		art = await renderArt(pi, initial.width, initial.height);
		artWidth = columns;

		ctx.ui.setHeader((tui, theme) => ({
			render(width: number): string[] {
				// Regenerate on resize; render() is sync so paint the stale art meanwhile.
				if (art && width !== artWidth && !generating) {
					generating = true;
					artWidth = width;
					const target = fitDimensions(width, process.stdout.rows ?? 40);
					void renderArt(pi, target.width, target.height)
						.then((next) => {
							if (next) art = next;
						})
						.finally(() => {
							generating = false;
							tui.requestRender();
						});
				}

				if (!art) return [];

				const blockWidth = Math.max(...art.map(vw));
				const leftPad = " ".repeat(Math.max(0, Math.floor((width - blockWidth) / 2)));
				let quote = "";
				if (width >= LONG_QUOTE.length + 2) quote = LONG_QUOTE;
				else if (width >= SHORT_QUOTE.length + 2) quote = SHORT_QUOTE;
				const quotePad = " ".repeat(Math.max(0, Math.floor((width - quote.length) / 2)));

				return [
					...Array(PADDING_ABOVE).fill(""),
					...art.map((line) => leftPad + theme.fg(ART_COLOR, line)),
					"",
					quotePad + theme.fg(QUOTE_COLOR, quote),
					...Array(Math.max(0, PADDING_BELOW - 2)).fill(""),
				];
			},
			invalidate() {},
		}));
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		ctx.ui.setHeader(undefined);
	});
}
