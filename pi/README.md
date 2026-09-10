# pi

Config for [`pi`](https://www.npmjs.com/package/@earendil-works/pi-coding-agent),
the terminal coding agent I run alongside Claude Code. Live copy lives in
`~/.pi/agent/`; this directory is the version-controlled subset of it.

## Install

```sh
npm install -g @earendil-works/pi-coding-agent   # was 0.85.0
pi --version
```

Then copy this directory's contents into `~/.pi/agent/` and authenticate
(`auth.json` is written by pi itself — see "Not in here" below).

Extension packages listed in `settings.json` are fetched by pi; `npm/package.json`
records the versions that were resolved:

- `pi-mcp-adapter`, `pi-subagents`, `@juicesharp/rpiv-todo`,
  `pi-patty-bg-tasks`, `@ayulab/pi-rewind`

## Dependencies outside this repo

- **`ascii-image-converter`** — `extensions/alpha.ts` shells out to it. Required,
  not optional. (Arch: AUR.)
- **`../nvim/lua/alex/plugins/src_imgs/`** — alpha.ts reads its art from the
  *same* directory `alpha-nvim` uses, so pi and Neovim show matching splash
  screens. It resolves the path as `~/.config/nvim/lua/alex/plugins/src_imgs`.
  Keep nvim installed at that path, or edit `ASSET_DIR` in alpha.ts.
- **`assets/alpha/crop-border.py`** — stdlib-only PNG border cropper used to
  prepare those images. The per-image flag table in alpha.ts documents the exact
  invocation used for each one.

## skills/

`~/.pi/agent/skills/` is deliberately **not** in this repo. It is a directory of
symlinks pointing at `~/.agents/skills`, which Claude Code also reads via
`~/.claude/skills`. One source of truth, two agents. Recreate it after restoring
`~/.agents/skills`:

```sh
mkdir -p ~/.pi/agent/skills
for s in ~/.agents/skills/*/; do
  ln -sfn "$s" ~/.pi/agent/skills/"$(basename "$s")"
done
```

`settings.json` also points `skills` at `~/.claude/skills` for the same reason.

## Terminal requirements

pi uses Shift-Enter and Ctrl-Enter, which need the terminal to emit extended keys
(CSI-u). Under tmux that means:

```
set -g extended-keys on
set -g extended-keys-format csi-u
```

## Not in here (secrets and runtime state)

`auth.json`, `models-store.json`, `sessions/`, `run-history.jsonl`,
`pi-crash.log`, `catppuccin-tui-state.json`, `npm/node_modules/`. Never commit
any of these — `auth.json` and `models-store.json` hold live credentials.
