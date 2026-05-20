---
name: dotfiles-git
description: For git operations on files tracked by Leon's dotfiles bare repo — paths under `$HOME` such as `~/.config/`, `~/.claude/`, `~/.local/bin/`, `~/install.sh`, `~/README.md` — use `git dotfiles <subcommand>` instead of plain `git <subcommand>`. The repo is bare at `~/personal/.dotfiles` with `$HOME` as the work tree, so plain `git` cannot find a `.git/` and will either error out or walk up into an unrelated repo. Translate mechanically: same args, same flags. Does NOT apply to git operations in regular projects (any directory with its own `.git/`, e.g. `~/work/*`, `~/personal/projects/*`, cloned repos) — those use plain `git` as normal. The trigger condition is the file path being under a tracked dotfiles location, not the mere mention of "commit" or "git".
---

# Using `git dotfiles`

Leon's dotfiles live in a bare repo at `~/personal/.dotfiles` with `$HOME` as the work tree. The alias is:

```
dotfiles = !git --git-dir=$HOME/personal/.dotfiles --work-tree=$HOME
```

For files tracked by this repo, replace `git <subcommand>` with `git dotfiles <subcommand>` — same args, same flags. If unsure whether a file is tracked, check from `$HOME` with `git dotfiles ls-files | grep <path>`.

Files in a regular project (with its own `.git/`) use plain `git` as usual.
