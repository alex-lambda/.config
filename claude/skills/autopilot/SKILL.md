---
name: autopilot
description: Manage the Quarterback autonomous-triage cloud routine — inspect, test-run, reschedule, or repair the scheduled claude.ai routine that triages Read.ai meetings into the Deals SharePoint library and emails a daily digest. Use when the user says /autopilot, asks about quarterback automation, the triage routine, a missing digest, or wants to change what runs on its own.
---

# Autopilot

> **⚠️ Single-operator only — not yet cleared for the team.** On 2026-07-23 the
> user directed that triage must run with every machine of ours switched off, so
> the trigger stays **enabled** and the routine is authorized for unattended
> operation on the operator's own pipeline. Two guards make that survivable:
> stage changes and new deals are never written unattended — they are recorded
> under `## Pending human approvals` (system.md → **Stages**) and re-surfaced by
> `/nextstep` until answered — and the GitHub Actions **digest watchdog**
> (`.github/workflows/digest-watchdog.yml`) fails loudly on any weekday the
> routine fires without delivering its digest, so silence can no longer go
> unnoticed for days. Do **not** point the routine at the sales team yet: the
> remaining team-safety work (enforced single-writer/locking across concurrent
> human + routine triages, a skill release gate) is still open. Interactive
> `/triage` remains fully supported alongside.

Quarterback triage runs unattended as a claude.ai cloud routine. This skill is
the operating manual for that routine: what exists, how to check it, and how to
change it.

The routine executes `skills/triage/SKILL.md` (Autonomous mode) from a fresh
clone of master — **to change triage behavior, edit that skill and push to
master; never encode behavior in the trigger prompt.** The trigger prompt only
bootstraps (clone repo → follow skill → always email digest).

The clone supplies the skills, system documentation, glossary, and corrections
only. Deal memory lives in the `Deals` SharePoint library
(system.md → **System of record**), read and written through the Microsoft-365
connector. **Microsoft-365 is mandatory** — if
tenant admin consent is revoked the routine cannot triage at all, and the failure
must appear as a digest, not silence.

## What exists (created 2026-07-13)

- Trigger: `trig_019zoaHGhGsV5EWbsWjstEig` — "Quarterback Autonomous Triage"
- Schedule: cron `40 23 * * 0-4` **UTC** = 8:40 AM Asia/Tokyo, Mon–Fri
- Environment: `env_01Vv1KQqyGAqqUgcUyL18rf3` (formerly shared with the Notion
  calendar sync routine `trig_01DCCPUdU9uh3CtLXcCigPvb` — disabled 2026-07-22
  at the user's request; this trigger is now the environment's only active user)
- Model: `claude-opus-4-8`; `persist_session: false`
- Repo: `SkyVaultAI/quarterback` (private; moved from `Jonny9906/quarterback`
  July 2026 — old URL redirects, but access grants must name the new org repo).
  Trigger prompt updated 2026-07-22 to clone the new URL.
- Output channel: the daily brief emailed to Jonathan.Nguyen@skyv.ai, subject
  `Quarterback brief — <YYYY-MM-DD>`, sent EVERY run (silence = broken).
  Renamed 2026-07-23 from `Quarterback triage digest` when it became a
  personalized action list (triage skill → Autonomous mode) rather than a
  system report; the watchdog accepts both subjects.
- UI: https://claude.ai/code/routines

## Connector registry (mcp_connections entries need all three fields)

| Connector | connector_uuid | url |
|---|---|---|
| Microsoft-365 | `342ba3de-941e-47ef-8e40-4ada01d02834` | https://microsoft365.mcp.claude.com/mcp |
| Read AI | `981c5551-06d9-4c08-bb18-736a6f6c4a12` | https://api.read.ai/mcp |

Both needed connectors (Microsoft-365 and Read AI) are attached as of
2026-07-13. Note: `connector_uuid` is the account's **installed MCP server ID**,
not the connector-directory UUID. The `url` field may be omitted in an update —
the API resolves it from the `connector_uuid`. To find an unknown ID, add a
DIAGNOSTICS instruction to the trigger prompt so the runner session reports it
in the digest.

**The known-good set for this trigger is exactly M365 + Read AI. Attach nothing
else.** Incident 2026-07-14→22 (two compounding failures):
(a) a Gmail connector (uuid `62be957f-5161-40ab-96f2-69dac411bcda`) with
broken OAuth ("insufficient authentication scopes", verified interactively) was
attached to the trigger 07-14 — removed from both routines 2026-07-22; verify a
connector interactively (one cheap tool call) before ever attaching it.
(b) after removing it, sessions STILL produced nothing: a minimal probe trigger
(one Sonnet session, one outlook_send_mail, same environment — see "Plumbing
test (safe to delete)", `trig_01565iqb6KEdoHjSKj8NmiwQ`, disabled) also died
silently, proving `env_01Vv1KQqyGAqqUgcUyL18rf3` itself fails to provision.
Prime suspect: the environment's GitHub repository association went stale when
the repo moved from Jonny9906 to the SkyVaultAI org mid-July — the exact
silence boundary. Environment provisioning errors are visible ONLY in the
claude.ai UI; nothing at the trigger API level distinguishes "ran and died"
from "never provisioned" (`last_fired_at` advances and a session id is issued
either way). The probe-trigger technique is the API-side maximum: if a
one-email probe on the same environment is silent, stop debugging prompts and
connectors — the fix is in the environment settings.

**Root cause confirmed 2026-07-23:** `gh api /orgs/SkyVaultAI/installations`
returns an empty list — **no GitHub App of any kind is installed on the
SkyVaultAI org**, so no claude.ai environment can be granted the moved repo at
all. The Claude GitHub App's original installation sits on the personal
Jonny9906 account, which an org repo is not covered by. The fix is two human
browser steps, in order (no API path exists — GitHub requires the web flow for
app installs, and the local `gh` token cannot manage them):
1. Install the Claude GitHub App on the org: https://github.com/apps/claude →
   Install → choose **SkyVaultAI** → grant **quarterback** (only-select-repos is
   fine).
2. At https://claude.ai/code/routines edit "Quarterback Autonomous Triage" and
   add `SkyVaultAI/quarterback` under **Repositories**, save, then **Run now**
   and watch for the brief (search Outlook for `Quarterback brief`).

**Local-runner dead end (probed 2026-07-23, don't re-derive):** a headless
`claude -p` session on the operator's Mac loads the M365/Read.ai connector tools
but every call is denied ("permission not granted by user") — claude.ai
connector permissions do not carry into headless runs without an explicit
allowlist, and a laptop-resident runner fails the requirement that triage work
with our machines off. The cloud routine is the primary by design; do not build
a launchd/cron fallback.

## Operating it

Load the API tool first: ToolSearch `select:RemoteTrigger`.

- **Inspect:** `{action: "get", trigger_id: "trig_019zoaHGhGsV5EWbsWjstEig"}` —
  check `last_fired_at`, `next_run_at`, `enabled`.
- **Test-run:** `{action: "run", trigger_id: ...}` — confirm the brief
  arrives (search Outlook for `Quarterback brief`). A test run is a
  **real triage** — it writes to SharePoint but creates no email (recaps are on
  hold — no sends, no drafts; see triage §4b). Safe by design, but there is no
  `git revert`; say so before firing one for a health check.
- **Reschedule / disable:** `{action: "update", trigger_id: ..., body:
  {cron_expression: "..."}}` or `{enabled: false}`. Cron is UTC (Tokyo = UTC+9).
  No delete action — disable instead.
- **Prompt changes:** `update` with a full `job_config` replacement. Preserve the
  hard rules: no mail sends or drafts (recaps are composed into the digest only;
  triage §4b hold), no
  deletes/moves/renames in the SharePoint library, no CORRECTIONS.md writes,
  digest always sent.

## When the digest is missing (health playbook)

0. You may already have been told: the **digest watchdog**
   (`.github/workflows/digest-watchdog.yml`, weekday mornings ~12:10 Tokyo)
   fails its run — and GitHub emails the failure — whenever no digest arrived in
   the hours after a scheduled fire. A red `digest-watchdog` run is this
   playbook's entry point; a green one means the digest landed and the problem
   is elsewhere.
1. `get` the trigger — enabled? `last_fired_at` recent?
2. **Fired repeatedly but total silence (no digest, no partial writes) → suspect
   a broken connector first.** Diff `mcp_connections` against the known-good set
   (M365 + Read AI, registry above) — anything extra, or recently added per
   `updated_at`, is the prime suspect. Verify each attached connector
   interactively with one cheap tool call (e.g. Gmail `list_labels`); an auth
   error interactively means the runner session dies at bootstrap, before the
   model runs. Remove the broken connector via `update` with the known-good
   `mcp_connections`, then test-run. (This was the 2026-07-14→22 outage.)
3. Connectors healthy but still total silence → **probe the environment**:
   create a throwaway trigger on the same `environment_id` (disabled, far-future
   cron, M365 only, prompt = send one email to Jonathan), fire it with `run`,
   wait ~5 min. Probe silent too → the environment fails to provision (stale
   GitHub repo association is the known cause — see the incident note above);
   the error is visible only at https://claude.ai/code, in the routine's run
   history / environment settings. Fix the environment's repository there
   (SkyVaultAI/quarterback), then Run now.
4. Fired but no digest, connectors healthy, probe works → run died mid-flight.
   Check the run at https://claude.ai/code/routines, or fire a test run and watch.
5. Clone failure: the routine cannot clone the private repo
   `SkyVaultAI/quarterback`. The digest usually names this as
   `GitHub access to this repository is not enabled for this session` and may
   suggest `add_repo`, but scheduled-runner sessions do not necessarily expose
   that tool. Fix it in the routine configuration instead: open
   https://claude.ai/code/routines, edit "Quarterback Autonomous Triage", add
   `SkyVaultAI/quarterback` in the routine's **Repositories** section, confirm
   the selected GitHub account/app installation has access to the private repo
   (the Claude GitHub App may need installing on the SkyVaultAI org first),
   save, then Run now. Dead ends confirmed 2026-07-13 (don't retry): the runner
   has no `add_repo` tool and the local `gh` OAuth token cannot manage GitHub App
   installations. The grant is human-only unless the RemoteTrigger API tool is
   available in the current debugging session.
6. Second candidate: M365 admin consent revoked or library moved. Verify by
   reading `file:///<driveId>/root` yourself — if that fails for you, it fails
   for the routine.
7. Recap replies and reports still flow to the mailbox regardless; a broken
   routine loses no data, only processing. Run `/triage` interactively as a
   stopgap.

## One-time setup still open (as of 2026-07-23)

- [x] Attach the **Read AI** connector — DONE 2026-07-13 via RemoteTrigger update.
- [x] Remove the broken **Gmail** connector from both routines — DONE 2026-07-22
      (see the incident note in the connector registry).
- [x] Point the trigger prompt at `SkyVaultAI/quarterback` — DONE 2026-07-22.
- [x] Digest watchdog in GitHub Actions — DONE 2026-07-23
      (`.github/workflows/digest-watchdog.yml`; reuses the attachment worker's
      Graph identity, so it needed no new admin setup).
- [ ] **Install the Claude GitHub App on the SkyVaultAI org** —
      https://github.com/apps/claude → Install → SkyVaultAI → grant
      `quarterback`. Human/browser only; verified absent 2026-07-23 (the org has
      zero app installations). Nothing downstream works until this lands.
- [ ] Add `SkyVaultAI/quarterback` to the routine's repository access in
      https://claude.ai/code/routines (possible only after the app install),
      then **Run now** — the remaining blocker to full triage; until then every
      fire dies at provisioning with no digest (and the watchdog stays red).
- [ ] Watch the first unblocked run's digest for its SharePoint write results.
- [ ] Optional: re-authenticate the Gmail connector in claude.ai settings if
      Gmail fallback search is ever wanted again — verify with a cheap call
      before re-attaching it to any trigger.
- [ ] Optional: Teams admin center → Meetings → Meeting policies → enable
      transcription + auto-start. Gives identity-reliable transcripts for every
      meeting, immune to Read.ai's 5-report quota.
