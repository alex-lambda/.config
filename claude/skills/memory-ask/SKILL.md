---
name: memory-ask
description: Answer questions from the quarterback deal memory in the Deals SharePoint library — deals, meetings, emails, decisions, commitments, open loops. Use for questions like "where does the Acme deal stand", "what did we decide about X", "what do I owe", "who is waiting on us".
---

# Memory Ask

Answer questions by retrieving deal memory from the `Deals` SharePoint library.
System conventions: `~/quarterback/system.md`. Layout details remain in
`~/quarterback/README.md`.

## Procedure

0. **Read from the store.** Load `mcp__claude_ai_Microsoft_365__read_resource`,
   then list only the top level: `read_resource` on `file:///<driveId>/root` —
   `driveId` `b!l2R0y-p-LESRJrrr4BrlFoXlTVlDYktLvWdfbA8m3CVbj43emVdkSJngia29tzfQ`
   — for `deals/` and `misc/`, then each for its folder names. **Do not descend
   into any
   `communications/` folder** — routing runs off folder names and `memory.md`,
   nothing else. Read the `memory.md` of the entr(ies) the question is about: for a
   single-entry question just the one that matches by slug, reading another
   `memory.md` only when the slug is ambiguous. Each `memory.md`'s `## Documents`
   section is that deal's document index; a document (under `communications/`, or
   at the deal root for older ones — README → **Layout**) is opened by its path
   from there only when step 3 needs its exact text.

   The M365 connector is the only way in. If it is unavailable, stop and say so.

1. **Corrections first.** Read `~/quarterback/CORRECTIONS.md`. A correction
   overrides every lower-ranked source. Participants prove attendance only.
2. **memory.md next.** Identify the relevant deal(s); read `deals/<deal>/memory.md`
   from the store — it usually answers state, decisions, commitments, and people
   questions outright. Cross-deal questions: read every `memory.md` in **both**
   `deals/` and `misc/` and scan for key terms, synonyms, and names — a question
   about an insurer, an auditor or the office lease is answered from `misc/`
   (system.md → **Scope: external work**). `sharepoint_search`
   can suggest where to look, but confirm by reading the file.
3. **Documents for detail.** Open individual documents (listed in memory.md's
   Documents section) only when the question needs specifics — exact wording,
   who said what, full context of a decision. Never report anything under
   `Needs verification` or an equivalent label as fact. Provider-generated
   summaries/action items are not transcript quotes.
4. **Route by question type:**
   - "where does <deal> stand" → that memory.md's `stage:` + Summary + at-risk items
   - "what do I / does <person> owe" → grep `- [ ] <token>:` across memory.md
     files, resolving the name to a token first (**Who "I" is** below)
   - "what did we decide" → Decisions sections, then the source document
   - "who's waiting on us" → Open loops sections
   - "what don't we know about <deal>" → the Qualification checklist's `UNKNOWN` keys
   - "who can say yes" → People → Decisionmakers (Stakeholders can only block;
     anyone under **Unknown role** is exactly that — do not promote them to
     answer the question). Carry each entry's marker: a `confirmed` role is
     fact; a `proposed` one is answered with its caveat ("proposed, awaiting
     confirmation") — never present a proposed decisionmaker as settled

   **Stage never filters an answer.** Unlike `/nextstep`, which skips `closed-won`
   and `nurture` deals, memory-ask answers about any deal at any stage — a
   question about a lost deal is still a question. Report the stage alongside the
   answer, so "we owe them a quote" on a `nurture` deal reads as the dead
   obligation it is rather than as live work.
5. **Cite sources** as `deals/<deal>/<file>` paths so answers are checkable.
6. If nothing matches, say so explicitly and name the nearest deals/documents.
   Offer to triage the missing material (`/triage`).

## Who "I" is

"What do **I** owe" is a personal question, and the store cannot answer it: every
`memory.md` holds the whole team's commitments under bare first names. Read
`~/quarterback/person.md` for the asker's `owner-tokens:` (system.md → **Who the
brief is for**) before answering any question phrased in the first person — *what
do I owe, what's on my plate, who's waiting on me*.

Match a token exactly as filed, the same three ways `/nextstep` does: an
`- [ ] alex.lam:` line is theirs; another name's line is not; a bare
`- [ ] alex:` line where GLOSSARY.md → **Name collisions** lists that first name
is **ambiguous** and is answered as such — "two of these are filed `alex:`, which
on these deals is usually Alex Wang" — never silently counted as the asker's.
Answer the same way for a named third party ("what does Alex owe"): the collision
is in the store, not in who is asking.

**This skill never writes person.md and never runs the setup questions** — that
is `/nextstep`'s job, and one writer keeps the file simple. If the file is
missing or unfilled, answer anyway with the owners named ("`andy` owes 3,
`jonathan` 2") and say once that `/nextstep` will ask who they are and make the
first-person form work. A question is never refused for want of identity.

## Notes

- Search is keyword-based: retry with rephrased terms before concluding the
  memory lacks it.
- Commitment answers distinguish Open vs Done and include due dates.
