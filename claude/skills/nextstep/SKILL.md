---
name: nextstep
description: Prioritized next actions from the quarterback deal memory in the Deals SharePoint library plus today's calendar — overdue and due-soon commitments across deals, stale open loops to nudge, and prep for upcoming meetings. Use when the user says /nextstep, asks what to do next, "what's on my plate", or for their daily brief.
---

# Nextstep

Tell a person what to do next, in priority order, across
all deals and misc entries plus today's calendar.

## Prerequisites

Load in ONE ToolSearch call:
`select:mcp__claude_ai_Microsoft_365__outlook_calendar_search,mcp__claude_ai_Microsoft_365__read_resource,mcp__claude_ai_Microsoft_365__sharepoint_search,mcp__claude_ai_Microsoft_365__sharepoint_update_file`

(`sharepoint_search` only to read `lastModifiedDateTime` for the hand-edit
backstop when ticking an item off — the tree walk stays `read_resource`.)

If the calendar is unavailable, build the list from memory files only and note
the meetings section was skipped.

## Who the brief is for

This is one person's day, so it has to know whose. Identity lives in
`~/quarterback/person.md` — local to this machine, gitignored, never in the store
(system.md → **Who the brief is for**). Read it first, before step 0: without it
this skill has every deal's open items and no way to tell which name is the
user's.

**If it is missing, or still carries the `<Your Name>` placeholders, ask — this
run, before the list.** Two questions in one turn:

- Your name?
- The email address(es) commitments and invites reach you at?

Derive the owner token yourself from the answer, and show what you derived and
why. It is the lowercase first name (`sarah`), because that is how commitments
are filed (system.md → **Commitment format**) — **unless** GLOSSARY.md → **Name
collisions** lists that first name, in which case use the qualified form from the
address (`alex.lam@skyv.ai` → `alex.lam`). Never write a bare colliding token:
that is precisely what puts a colleague's work on the user's list every morning,
and `CORRECTIONS.md` already carries one retraction of exactly that mistake.

Write `~/quarterback/person.md` from `~/quarterback/templates/person.md`, name
the path back, and continue into the brief in the same run. Asking is a one-time
cost and never a reason to hand back no list. If the user declines to answer,
build the brief unfiltered (below) rather than stopping.

**Unattended runs never ask and never guess.** A brief `/triage` builds for
emailing is for its recipient, and that address is the identity: the first name
from it is the token, and a collision it cannot resolve stays in the list marked
inline rather than becoming a question nobody is there to answer (triage → the
brief). With neither a person.md nor a resolvable recipient, build the brief
**unfiltered** — every owner's items — and say so in one line at the top. An
unfiltered brief is honest; a brief silently filtered to a guessed name is not.

## Procedure

0. **Read from the store** — deal memory lives in the `Deals` SharePoint library
   (system.md → **System of record**). `read_resource` on `file:///<driveId>/root`
   — `driveId` `b!l2R0y-p-LESRJrrr4BrlFoXlTVlDYktLvWdfbA8m3CVbj43emVdkSJngia29tzfQ`
   — then list `deals/` **and `misc/`** for their folder names and read **only**
   each entry's `memory.md`. **Never descend into a `communications/` folder:**
   `memory.md`
   carries every commitment, loop, and qualification key this skill ranks, and its
   `## Documents` section is the entry's document index if a specific file is ever
   needed. Ignore `internal-testing/` if present, and
   never read the library root's `triage-state.md` — that marker belongs to
   `/triage` alone (system.md → **The triage cutoff**). The connector is the only way
   in; if unavailable, stop and say so. Note each `memory.md`'s `revision:` as
   you read it — step 6 compares against it before this skill writes anything.

   **`misc/` entries are external work with no opportunity attached** — a broker,
   an audit firm, a landlord (system.md → **Scope: external work**). Their
   commitments and open loops rank in steps 2–5 exactly like a deal's, by
   urgency alone. What they do not have: no `stage:`, so step 1a never suppresses
   one; no qualification checklist, so step 5's qualification-gap pass skips
   them; and no value/heat band, so they print without one.
1. **Corrections first** — read `~/quarterback/CORRECTIONS.md`; corrected or
   unverified claims must never appear as obligations.
1a. **Drop the deals that are over** — read each deal `memory.md`'s `stage:`
   (system.md → **Stages**) and set aside every deal at `closed-won` or `nurture`.
   Their commitments, loops, and nudges do not enter steps 2–5. Chasing a customer
   who already said no, or who already signed, is the failure this prevents.
   **This step never touches `misc/`**: those entries carry no `stage:`, so there
   is nothing to suppress them, and their items ride until they are closed
   (system.md → **Stages**). A `misc/` entry is also never listed under **Not
   shown** — nothing was hidden.

   A file with legacy `status:` and no `stage:` is **unstaged** — treat it as live
   and keep it. Never infer a stage here: a deal is only over when its `stage:`
   says so, and `/nextstep` has no business deciding that (it is `/triage`'s
   proposal and the user's call). Silence is not a loss.

   List what you set aside at the bottom of the output — one line, deal and stage
   (`Acme — nurture`, `Bolt — closed-won`). Suppressed must never mean invisible:
   if a stage is wrong, the only way the user finds out is by seeing the deal
   named there instead of quietly missing from their day.

   **Exception: unticked `## Pending human approvals` entries surface even from a
   set-aside deal** (step 1b) — an approval is a question only the human can
   answer, and a deal suppressed by the very stage change awaiting their answer
   must not hide the question.
1b. **Pending approvals** — collect every unticked entry under `## Pending human
   approvals` across the deal `memory.md` files read in step 0. These are stage
   changes and role proposals; nothing else waits on approval (a new deal is
   created outright by `/triage`, never proposed — system.md → **Stages**).
   These outrank everything in step 5's list: each is a decision only the user
   can make, another run has already done the reading behind it, and until it is
   answered the system keeps chasing (or ignoring) a deal on possibly stale
   terms. Show each with what it proposes (a stage transition or a person's
   role), quoted evidence, proposal date, and — for a stage change — what
   confirming would suppress. Batch role entries one line per deal so a single
   answer can settle every name on it, listed after the stage questions —
   cheaper calls last.
1c. **Score the live deals** — band each deal that survived step 1a on **value**
   and **heat** (system.md → **Scoring**), from the `memory.md` files already read
   in step 0. This costs no extra reads: every input — `stage:`, the six
   qualification keys, a `confirmed` decisionmaker, the largest cited MW figure,
   the newest dated line in `## Documents` — is in the file you have. Fold step 4's
   calendar into heat: a deal with a meeting today or tomorrow is `hot` whatever
   its last document says.

   The bands **order** steps 2–5; they never shorten them. Nothing is dropped for
   scoring low — a `maintain` deal's overdue commitment is still overdue, and
   there is no band that means "stop working this" (that is `nurture`, and only a
   human sets it). This skill never writes a band anywhere: a score is derived,
   not state (system.md → **Scoring**).

   **`misc/` entries are not scored** (system.md → **Scoring**). Three of the
   four value inputs do not exist on them and MW is meaningless for an audit
   firm. Their items rank on urgency alone — a date is a date — and their tag
   carries the entry name with no band: `[Marsh Builders Risk · misc]`. When an
   unbanded item ties with a banded one, the due date decides; where neither has
   a date, the deal goes first, because a `misc/` item with no date is
   housekeeping and a deal without one is a relationship going quiet.
2. **Commitments across deals** — scan each remaining `memory.md` for
   `- [ ] <token>:` under Commitments/Open, and sort each one against the
   `owner-tokens:` in person.md (**Who the brief is for**):

   - **Yours** — the token matches. These are the numbered list. Bucket:
     overdue, due within 3 days, undated.
   - **Someone else's** — the token is another name, with no collision against
     yours. Not your work, and not dropped either: the overdue and due-within-3
     ones go to **Owed by others** in step 5, one line each. Undated ones are
     left out — say how many in that section's line rather than letting the
     omission pass silently.
   - **Ambiguous** — a bare first name that GLOSSARY.md → **Name collisions**
     says could be you or a colleague (`alex:` where your token is `alex.lam`).
     Never assume either way. These go to **Whose is this?** in step 5, and when
     the user answers, record it in `~/quarterback/person.md` under `## Whose is
     this? — answered` so the item is never asked about twice. That file is the
     only thing this step writes; an answer about ownership is not evidence about
     the deal, so nothing goes to the store.

   A token matches a line only as written: `alex.lam` is **yours** on an
   `- [ ] alex.lam:` line and **ambiguous** on a bare `- [ ] alex:` one. Since
   `/triage` files bare first names (system.md → **Commitment format**), a
   qualified token means the first runs raise more of these than later ones —
   each answer is permanent, so the section shrinks as it is used. Do not "fix"
   this by matching the bare form silently; that is the mistake, not the friction.

   On an unfiltered run there is no split: every open commitment is in the
   numbered list, under the one-line notice from **Who the brief is for**.
3. **Open loops** — from the same memory.md files: loops whose owner token is
   yours, plus any loop that names you as the one it is blocked on. Flag anything
   open more than 7 days as needing a nudge. Another person's loop is theirs to
   nudge; it rides in **Owed by others** only when it is blocking you.
3a. **Qualification gaps** — for deals at `prospect`, an `UNKNOWN` in the
   Qualification checklist (land, power, money, GPUs, RFS, location) is the work
   of the stage: surface the gaps as actions ("find out Acme's power position"),
   ranked with stale loops. For a deal at `proposal` or later, an `UNKNOWN` on a
   design-relevant key (power, land) is a flag, not a task — say so.
4. **Today/tomorrow's meetings** — `outlook_calendar_search`; match attendees/
   subject to deals (People sections), and prep from that deal's memory.md:
   where it stands, open commitments to these attendees, unresolved questions.
5. **Output a prioritized list:**

```
## Next steps — <date>

### Awaiting your approval
- Acme Corp: stage change proposal → committed — "we're ready to talk
  timelines" (communications/2026-07-12-acme-followup.md), proposed 2026-07-14
  → yes / no moves it; until then the stage stays `proposal`.
- Acme Corp: Raj Patel → stakeholder — "security signs off, Sarah decides"
  (communications/2026-07-20-acme-security-call.md), proposed 2026-07-21
  → yes / correct it; once answered it is never asked again.

1. <action> — why now (due date / blocker / meeting at HH:MM) [<deal> · pursue/warm]
2. ...

### Whose is this?
- Lambda: "Add Skyler to the proposal review" — filed `alex:`, overdue 4 days.
  You are `alex.lam`; on this deal the design work is Alex Wang.
  → mine / not mine — either way I stop asking.

### Owed by others
- andy: Send Gulf the revised quote — overdue 3 days [Gulf · pursue/warm]
- jonathan: Confirm CoreWeave site visit — due tomorrow [CoreWeave · pursue/cold]
- 6 more open with no date, not shown.

### Going quiet
- CoreWeave — pursue · 42MW · committed · 5/6 · DM ✓ · cold 34d — nothing due,
  nobody blocked, no contact since 2026-06-24. Biggest deal on the board.

### Meeting prep
- <meeting @ time> [<deal>]: <2-3 prep bullets>

### Not shown
- Acme Corp — nurture (3 open commitments, 1 loop)
- Bolt Data — closed-won (2 open commitments)

---
Bands: pursue / watch / qualify / maintain = what the deal is worth doing about ·
hot / warm / cold = time since it last produced a document. Neither is a stage,
and none of them means "drop it".
```

**Awaiting your approval** lists step 1b's finds and leads the brief — omit the
section only when nothing is pending. An entry that has sat unanswered more than
7 days says so (`pending 9 days`): a proposal aging in place is itself a loop
going stale.

**Whose is this?** carries step 2's ambiguous items — omit it when there are
none, and on an unfiltered run. Give each one the deal, the item, the token it
was filed under, its due state, and what the collision is (GLOSSARY.md → **Name
collisions**), so the answer takes a word. Say plainly when an ambiguous item is
overdue: it could not be ranked in the list above, and an unowned overdue item is
the one this section must not let pass as housekeeping. An answer settles that
item only — never the person — and is recorded locally, so the same line is never
raised twice.

**Owed by others** is what other people owe, dated and close: it is not the
user's work and never enters the numbered list, but a colleague's overdue item on
a live deal is often the thing actually blocking it. Name the owner, the item,
its due state and the deal — no "why now" line, because the answer is always
"someone else's". Close it with the count of undated items left out, and omit the
whole section when there is nothing dated. On an unfiltered run it does not
appear at all — everything is in the list.

Rank by: overdue > needed for today's meetings > due soon > stale loops to
nudge > qualification gaps on `prospect` deals > everything else. One line of
"why now" per item, and the deal's bands in its tag (`[CoreWeave · pursue/cold]`).

**Value breaks ties inside a bucket** — of two overdue items, the one on the
`pursue` deal goes first, and of two `pursue` deals, the `cold` one goes first:
silence on a big deal is the risk nothing else in this brief surfaces. Ties inside
a band break on the underlying total, not the word. Bands only ever reorder: a
`maintain`/`cold` item still gets its line, at the bottom (system.md →
**Scoring**).

**The legend is not optional**, and it is one line. This output is also the body
of the emailed daily brief (`/triage` builds it by running this procedure), so it
reaches someone who has no doctrine open in front of them — and `maintain` reads
as "dead deal" to anyone without the key, which is the one misreading that would
make this brief actively harmful. Print it whenever any band appears; omit it only
on a brief carrying none. The `DM ✓ / ? / —` components are glossed in system.md →
**Scoring**; a brief showing them is not obliged to re-explain them.

**Going quiet** names every `pursue`- or `watch`-value deal at `cold` heat that produced no
item in the numbered list — no due commitment, no stale loop, nobody waiting.
That combination is invisible to every other step here, and it is the one this
section exists for: a deal is not fine because it is silent, and the bigger it is
the longer the silence can run before anything else notices. Give each its bands
with their working, the date of its newest document, and how long it has been
quiet; omit the section when nothing qualifies. A deal already carrying an action
above is not repeated here — the list has it.

**Not shown** lists every deal step 1a set aside, with its stage and how much it
was holding — omit the section only when nothing was suppressed. If a meeting on
today's calendar belongs to a suppressed deal, prep it anyway and say the stage
looks stale: the calendar is evidence about a deal that its `stage:` is not. No
`misc/` entry ever appears here: nothing suppresses them, so there is nothing to
disclose.

6. **Read-only by default.** The store is what this means: `~/quarterback/person.md`
   is a local file with one writer and no revision token, so creating it (**Who
   the brief is for**) and appending an answered ambiguity (step 2) are outside
   the protocol below and need none of it. Nothing about who the user is ever
   reaches the library. When the user answers a pending approval from step
   1b, resolve it under the same write protocol as a tick-off (below): tick the
   entry, append the resolution (`— confirmed <date>`, `— declined <date>`, or
   for a corrected role `— corrected <date>: <bucket>`), and in the same
   write apply what was confirmed — on a stage change set `stage:`; on a role,
   flip that person's People marker to `— confirmed <date>` (or move them where
   the user said, confirmed by their word — system.md → **People**). That is the
   one stage or role write this skill may ever make, and only on the user's
   explicit word in this conversation. When the user says they've done an item:
   - Re-read that entry's `memory.md` from the store immediately before writing
     (system.md → **Concurrency**), and compare its `revision:` with the one you read
     at step 0. This works identically in `misc/` — same protocol, same token, and
     `misc/` files have two writers, so it matters just as much there.
   - Move the item to Commitments/Done with today's date **on top of the copy you
     just re-read** — if `revision:` moved, someone wrote in the meantime, so the
     tick-off goes onto their version, never over it.
   - Write with `sharepoint_update_file`, setting `revision:` to (the revision in
     the copy you just re-read) + 1 and `updated:` to now (ISO-8601 UTC). Confirm
     2xx — a tick-off that did not land is invisible to the team. Always bump
     `updated:`: the concurrency protocol needs it, and it does not move what
     `/triage` fetches from — that is `last-triage-at:` on the root
     `triage-state.md`, which this skill never reads or writes and only `/triage`
     touches (system.md). A tick-off at any hour is safe.
   - If `revision:` is unchanged but the file's `lastModifiedDateTime`
     (`sharepoint_search`, not `read_resource`) moved, a human hand-edited it:
     stop and show the user rather than overwriting their edit.
