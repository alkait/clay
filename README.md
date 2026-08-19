# cltmp

Disposable [Claude Code](https://claude.com/claude-code) scratch sessions, one command away.

```
$ cltmp
# → creates ~/Downloads/scratch-20260819-1430, cds into it,
#   and starts Claude Code there
```

## Why

Claude Code loads project context from wherever you launch it: `CLAUDE.md`
instructions, `.claude/settings.json` hooks and permissions, `.mcp.json`
servers. Run a quick experiment inside a real repo and you get contamination
in both directions — generated scratch files land in your project, and your
project's config shapes the experiment.

`cltmp` gives every throwaway session its own fresh, empty directory:

- **Isolation** — no project config leaks in, no scratch files leak out.
- **Low friction** — a disposable empty directory is the one place where
  skipping permission prompts is low-stakes, so sessions run uninterrupted.
- **Resumability** — `cltmp -c` jumps back into your most recent scratch
  session without you remembering which directory it was in.

## Install

Clone (or just copy `cltmp.zsh`) and source it from your shell config:

```sh
git clone https://github.com/alkait/cltmp.git ~/.cltmp
echo 'source ~/.cltmp/cltmp.zsh' >> ~/.zshrc   # or ~/.bashrc
```

Works in zsh and bash. It's a shell function (not a script) because it needs
to `cd` your current shell into the scratch directory.

## Usage

```sh
cltmp                     # new timestamped scratch session
cltmp regex-experiments   # named scratch dir instead of a timestamp
cltmp -c                  # resume the most recent scratch session
cltmp -m sonnet           # pick a model (case-insensitive)
cltmp -e high             # set reasoning effort
cltmp -s                  # keep normal permission prompts
cltmp --prune             # delete scratch dirs older than 14 days
cltmp --prune 30          # ...or older than 30 days
```

| Option | Description |
| --- | --- |
| `-c`, `--continue` | Resume the most recent scratch session |
| `-s`, `--safe` | Keep Claude Code's normal permission prompts |
| `-m`, `--model NAME` | Model to use |
| `-e`, `--effort LEVEL` | Reasoning effort |
| `--prune [DAYS]` | Delete `scratch-*` dirs older than DAYS (default 14) |
| `-h`, `--help` | Show help |

Scratch directories live in `~/Downloads` by default; set `CLTMP_ROOT` to
change that:

```sh
export CLTMP_ROOT="$HOME/scratch"
```

## A note on `--dangerously-skip-permissions`

By default, `cltmp` starts Claude Code with permission prompts disabled.
That's a deliberate tradeoff: scratch directories are empty and disposable,
so the usual reason for prompts (protecting a real project) doesn't apply,
and uninterrupted sessions are the whole point of a scratch pad.

Be aware the flag is not scoped to the directory — Claude can still act
anywhere on your system it decides to. If that tradeoff isn't for you, run
`cltmp -s` to keep normal prompts, or make safe mode your default with an
alias:

```sh
alias cltmp='cltmp -s'
```

## License

[MIT](LICENSE)
