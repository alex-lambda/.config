# obsidian — Obsidian vault settings

Live config lives in `~/Documents/alexlam_obsidian/.obsidian`; this directory is the
version-controlled copy. Obsidian settings are per-vault, so these install into
whichever vault you open on the new machine.

## Layout

| File | Purpose |
| --- | --- |
| `app.json` | editor settings (auto-update links, attachments in `attachments/`) |
| `appearance.json` | active theme: AnuPpuccin |
| `core-plugins.json` | which core plugins are enabled |
| `graph.json` | graph view display and force settings |
| `themes/AnuPpuccin`, `themes/Catppuccin` | theme CSS + manifests |

## Install on a new machine

Close Obsidian (it rewrites these files on exit), then:

```sh
VAULT=~/Documents/alexlam_obsidian
mkdir -p "$VAULT/.obsidian"
cp -R app.json appearance.json core-plugins.json graph.json themes "$VAULT/.obsidian/"
```

## Notes

- Not tracked: `workspace.json` (open tabs, pane layout, recent files — per-machine
  state Obsidian regenerates) and `.DS_Store`.
- No community plugins or CSS snippets are installed.
- Core Sync is enabled; if the vault syncs via Obsidian Sync, settings sync can
  also carry these across once signed in.
