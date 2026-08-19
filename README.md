# clay

Disposable [Claude Code](https://claude.com/claude-code) playgrounds.

```sh
clay
```

## Why

Claude Code loads project context from wherever you launch it: `CLAUDE.md`
instructions, `.claude/settings.json` hooks and permissions, `.mcp.json`
servers. Run a quick experiment inside a real repo and you get contamination
in both directions — generated throwaway files land in your project, and
your project's config shapes the experiment.

`clay` gives every throwaway session its own fresh, empty playground:

- **Isolation** — no project config leaks in, no throwaway files leak out.
  Anything a session creates stays neatly contained in its playground
  directory.
- **Low friction** — a disposable empty directory is the one place where
  skipping permission prompts is low-stakes, so sessions run uninterrupted.
- **Resumability** — `clay -c` drops you back into your last playground,
  `clay -cl` picks a kept one from a menu, and `clay -r` promotes a
  playground you want to keep and gives it a name.

## Install

Clone (or just copy `clay.zsh`) and source it from your shell config:

```sh
git clone https://github.com/alkait/clay.git ~/.clay
echo 'source ~/.clay/clay.zsh' >> ~/.zshrc   # or ~/.bashrc
```

Works in zsh and bash.

## Usage

```sh
clay                        # new timestamped playground
clay -c                     # resume the last-used playground
clay -c web-scraping-test   # resume a playground by name
clay -cl                    # pick a kept (renamed) playground from a menu
clay -r web-scraping-test   # keep the current playground under a real name
clay -l                     # list playgrounds, most recent first
clay --prune                # delete all unnamed playgrounds
```

Playgrounds live in `~/clay` by default (created on first use); set
`CLAY_ROOT` to change that:

```sh
export CLAY_ROOT="$HOME/playgrounds"
```

## Keeping a playground

Sometimes a throwaway session turns out to be worth keeping. Exit the
session, then, from inside the playground:

```sh
clay -r web-scraping-test
```

`clay -c web-scraping-test` later resumes the exact conversation — not
just the files — and named playgrounds are never touched by `--prune`.

## A note on `--dangerously-skip-permissions`

Total autonomy with no prompts is the whole point of a playground, and an
empty, disposable directory is the one place that's low-stakes. The flag
isn't scoped to the directory, though — remove it from `clay.zsh` if that
tradeoff isn't for you.

## License

[MIT](LICENSE)
