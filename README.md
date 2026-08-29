# clay

Disposable [Claude Code](https://claude.com/claude-code) playgrounds.

The directory you run Claude Code in *is* the session — context, files,
conversation. A real repo is the wrong place for a quick idea, and a
hand-made temp folder is one you'll never find again.

`clay` gives every idea a fresh playground in one command. Throw it
away, keep it, or graduate it into a real project.

## Install

```sh
git clone https://github.com/alkait/clay.git ~/.clay 2>/dev/null || git -C ~/.clay pull
grep -q clay.sh ~/.${SHELL##*/}rc 2>/dev/null || echo 'source ~/.clay/clay.sh' >> ~/.${SHELL##*/}rc
```

Run it again anytime to upgrade. The second line finds your shell and
lands in `~/.zshrc` or `~/.bashrc` accordingly — clay works in both.
Playgrounds live in `~/clay`; set `CLAY_ROOT` to change that.

## The life of an idea

**Got an idea?** Start a session in a fresh playground:

```sh
clay
```

`clay -c` drops you back into the last one. Most ideas end here — unnamed
playgrounds are throwaways, and `clay --prune` sweeps them all away.

**Worth coming back to?** Give it a name, from inside the playground:

```sh
clay -r web-scraper
```

Named playgrounds persist: `--prune` never touches them, `clay -c
web-scraper` resumes the exact conversation — not just the files — and
`clay -cl` picks one from a menu (`clay -l` lists everything you have).
If it later turns out to be a dead end,
`clay -d web-scraper` deletes it, conversation and all.

**Outgrown the sandbox?** Graduate it into a real project:

```sh
clay -m ~/projects/web-scraper
```

The conversation history moves with it, so `claude --continue` from the
new location picks up right where you left off. From here on it's a normal
project — clay's work is done.

## A note on `--dangerously-skip-permissions`

clay launches sessions with permission prompts skipped: total autonomy is
the whole point of a playground, and an empty, disposable directory is the
one place that's low-stakes. The flag isn't scoped to the directory,
though — remove it from `clay.sh` if that tradeoff isn't for you.

## License

[MIT](LICENSE)
