# claude — Claude Code config

Live config lives in `~/.claude`; this directory is the version-controlled copy.

## Layout

| File | Installs to |
| --- | --- |
| `settings.json` | `~/.claude/settings.json` |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` (chmod +x) |
| `themes/catppuccin-mocha.json` | `~/.claude/themes/catppuccin-mocha.json` |
| `skills/*/SKILL.md` | `~/.claude/skills/*/SKILL.md` (hand-written skills) |
| `agents-skill-lock.json` | `~/.agents/.skill-lock.json` (41 mattpocock/skills, symlinked into `~/.claude/skills`) |

## Install on a new machine

```sh
mkdir -p ~/.claude/themes ~/.claude/skills
cp settings.json statusline-command.sh ~/.claude/
chmod +x ~/.claude/statusline-command.sh
cp themes/catppuccin-mocha.json ~/.claude/themes/
cp -R skills/. ~/.claude/skills/
```

Then in Claude Code:

- `/plugin marketplace add anthropics/claude-plugins-official`
- install `code-review`, `claude-md-management`, `frontend-design` (all three are
  installed but disabled in `settings.json` — they are kept for on-demand use)
- run the `setup-matt-pocock-skills` skill to restore the shared skill set from
  `mattpocock/skills`, then check it against `agents-skill-lock.json`

`statusline-command.sh` needs `jq` and truecolor terminal support.

## Notes

- `model` is `opus[1m]` (Opus 5, 1M context); `effortLevel` is `medium`;
  `permissions.defaultMode` is `auto`.
- The statusline prints `dir (branch) | model | NN% ctx` in Catppuccin Mocha pastels.
- Not tracked here: `~/.claude/projects/*/memory` (per-machine memory), sessions,
  caches, and plugin install caches.
