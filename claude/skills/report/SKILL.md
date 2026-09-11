---
name: report
description: "Generate a status report from the quarterback deal memory in the Deals SharePoint library — one deal's status, or what happened across all deals over a timeframe: meetings, decisions, commitments completed and added, open loops. Use when the user says /report, asks for a deal status, pipeline review, or weekly summary."
---

# Report

Summarize deal state, from memory. Two modes, chosen from the request:

- **Deal report** — "/report acme": one deal, in depth.
- **Pipeline report** — "/report" or "this week": all active deals, one section each. Default timeframe: last 7 days.

## Procedure

0. **Read from the store** — deal memory lives in the `Deals` SharePoint library
   (system.md → **System of record**). Load
   `mcp__claude_ai_Microsoft_365__read_resource`, `read_resource` on
   `file:///<driveId>/root` — `driveId`
   `b!l2R0y-p-LESRJrrr4BrlFoXlTVlDYktLvWdfbA8m3CVbj43emVdkSJngia29tzfQ` — then list
   `deals/` **and `misc/`** for their folder names. **Do not descend into any
   `communications/`
   folder in step 0.** Read only the `memory.md` files the report's scope needs
   (step 3 picks them — one for a named entry, the live deals plus all of `misc/`
   for pipeline mode).
   Each `memory.md`'s `## Documents` section indexes that deal's documents (under
   `communications/`, or at the deal root for older ones — README → **Layout**);
   step 4 opens one by its path only when the user asks for depth. Ignore
   `internal-testing/` if present. The connector is the only way in; if
   unavailable, stop and say so.
1. **Corrections** — read `~/quarterback/CORRECTIONS.md` first. Never report a
   corrected, disputed, or `Needs verification` claim as fact. Attendance is not
   ownership.
2. **Scope** — parse deal/timeframe from the request; state it at the top.
3. **Shortlist** — list the `deals/` and `misc/` folders; match names across
   both. A **named deal** is
   reported at whatever stage it sits, including `closed-won` and `nurture` — the
   user asked for it. **Pipeline mode** covers the live stages (`prospect`,
   `proposal`, `committed`) plus unstaged legacy files (`status:` and no `stage:`),
   ordered down the ladder, and gives `closed-won` / `nurture` one summary line at
   the end rather than a section each (system.md → **Stages**). Filter by `updated:`
   for the timeframe (an ISO-8601 UTC timestamp; older files may still carry a
   bare `YYYY-MM-DD`). If a named entry doesn't match a folder, scan memory.md
   files in both trees for the term.

   **`misc/` in each mode.** Named — report it like any other entry, minus the
   stage and score it has none of. Pipeline mode — `misc/` is not pipeline, so it
   does not read down the stage ladder with the deals; give it its own **Misc
   (external, not deals)** section after them, holding only entries with activity
   in the timeframe or open items with dates. A pipeline review that buries the
   deals under vendor housekeeping has the emphasis backwards; one that drops an
   expiring survey window has it worse.
3a. **Band** — score each **deal** in scope on **value** and **heat** (system.md →
   **Scoring**), from the `memory.md` you already read. `misc/` entries are not
   scored and print no band (system.md → **Scoring**); do not invent one, and do
   not print `?` in its place — the axis does not apply. Bands are derived, never
   written, and never reorder this report: a pipeline review reads down the stage
   ladder, and a band is a column in it, not the sort key. Report them with their
   working (`pursue · 42MW · committed · 5/6 · DM ✓ · cold 34d` — components read
   left to right in system.md → **Scoring**) so a band that looks wrong can be
   traced to the input that made it. Close the report with the same one-line band
   legend `/nextstep` carries, for the same reason: a reader who has not read the
   doctrine takes `maintain` for "dead".
4. **Gather** — each entry's memory.md is the primary source, in both trees. Open
   individual documents only when the user asks for depth on something specific.
   A timeframe reaches everything that is filed; only purely internal material
   is outside the store entirely (system.md → **Scope: external work**), so a
   report never covers Quarterback's own build or a weekly update.
5. **Write the report:**

```
## Report — <scope>

### <Deal> (stage, owner, last updated)
- Score: pursue · 42MW · committed · 5/6 · DM ✓ · cold 34d
- Where it stands: <from Summary>
- Qualification gaps: <UNKNOWN keys — omit when all six are answered>
- Awaiting a human: <unticked pending approvals — omit when there are none>
- Decisions: ...
- Completed / New commitments: ...
- At risk: <overdue items, stale loops, no movement in 14+ days>

Closed / nurture: Bolt Data (won 2026-06-30), Acme Corp (nurture)
```

One line per item, cite `deals/<deal>/<file>` paths. Pipeline mode ends with an
**Across deals** section: totals, stage distribution, the value/heat spread, and
what's most at risk — naming the `pursue` and `watch` deals sitting `cold`,
longest quiet first. Empty sections say "none".

**Awaiting a human** lists every unticked entry under that deal's `## Pending
human approvals` — a proposed stage change, a proposed role — with its proposal
date and how long it has sat (`proposed 2026-07-14, 10 days`). A question nobody
has answered is part of where the deal stands: the stage may read `proposal`
only because the move to `committed` is still waiting, and the report is what a
human reads to find that out. Report it; never resolve it — answering is
`/nextstep`'s job (or a reply the next `/triage` harvests), and this skill
writes nothing. Pipeline mode carries the same line per deal, and its **Across
deals** section counts what is outstanding, oldest first.

Three flags belong under **At risk**:

- A deal at `proposal` or later still carrying `UNKNOWN` power or land — the
  design and quote rest on facts nobody has confirmed (system.md → **Qualification**).
- A deal at `committed` with no movement in 14+ days — intent to buy that nothing
  is acting on. This stays stricter than `cold` (21 days) deliberately.
- A `pursue`- or `watch`-value deal at `cold` heat — the pipeline's real exposure,
  and the one flag here that fires on deals nothing else in this report is worried
  about.

Bands qualify what a section already says; they never overrule it. A `maintain`
deal with an overdue commitment is still overdue, and no band is a reason to
recommend `nurture` — `maintain` in particular is arithmetic over six
qualification keys, not a finding that the deal is dead. That is a stage change:
it needs a human and quoted evidence (system.md → **Stages**, **Scoring**).

Never report a stage the memory doesn't carry. An unstaged legacy deal is reported
as `unstaged`, not as a stage you inferred; if the stage looks wrong for what the
documents show, say so and suggest `/triage` — which proposes the change — rather
than describing the deal as though the stage were already right.

6. **Read-only** — never write to the library. If a deal's memory.md looks stale
   (updated long before its latest documents), suggest running `/triage`.
