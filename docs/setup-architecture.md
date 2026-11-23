# Setup Architecture

Why the setup is bash and symlinks instead of a dotfile manager, and why package
categories are chosen per machine. Steps, options, and flags: [Installation Guide](installation.md).

## Decision: Shell-based setup over chezmoi

**2026-03-28.** Bash scripts, a declarative symlink map, and package lists by category
replaced manual `ln -sf` commands. chezmoi, yadm, and GNU stow were rejected.

chezmoi's value does not apply here:

- **No secrets in the repos, by design.** SSH keys, GPG subkeys, and API tokens are
  created per machine and never shared, so a compromised machine costs one revoked key.
  Encryption and password manager integration, chezmoi's strongest features, solve a
  problem this setup avoids.
- **No ciphertext beats any ciphertext.** An encrypted secret in a repo can be copied once
  and attacked offline indefinitely, or opened after a later key leak.
- **No extra dependency.** Linking (`setup.sh --link-only`, `link.sh`) needs only bash and
  standard Unix tools. Homebrew is needed only for packages. chezmoi is one more binary that
  must be installed first and keep working across OS upgrades.
- **Drift detection buys little.** With one user per machine, drift is rare and usually
  intentional. `chezmoi verify` pays off for fleets and teams.

Technical mismatches, not dealbreakers alone:

- **Copies, not symlinks.** chezmoi writes copies by default, and its symlink mode skips
  directories, executables, private files, and templates. This repo links whole
  directories (`karabiner`, `hammerspoon`) and scripts (`bin/`). Karabiner-Elements
  rewrites its own `karabiner.json`, which would need `chezmoi re-add` after every change,
  and a direct edit to a target makes the next `chezmoi apply` ask before overwriting it,
  unless made through `chezmoi edit` or followed by `chezmoi add`.
- **One source repo.** The private repo would become a `.chezmoiexternal` git-repo, whose
  files chezmoi leaves out of `chezmoi diff` and lists as unmanaged.
- **Layers become templates.** The private layers (below) turn into Go template
  conditionals scattered across files.
- **Mangled source tree.** `private_dot_ssh/config` instead of `ssh/config`.
- **Big-bang migration.** Hard to do incrementally.

The others:

- **yadm** makes `$HOME` itself the Git work tree: no `~/.dotfiles` directory, no second
  repo for the private split, and platform or host variants as filename suffixes instead
  of directory layers.
- **GNU stow** mirrors each package's tree into the target, so `nvim/init.lua` would have
  to move to `nvim/.config/nvim/init.lua`, and a rename such as `ghostty/config` to
  `~/.config/ghostty/config.ghostty` is impossible. It has no platform filter and adds
  nothing over `symlinks.conf`.

## Decision: Per-machine category selection, converge without pruning

**2026-11-21.** `setup.sh` saves the chosen categories in `~/.config/dotfiles/categories`
and every later run installs what that selection lacks. Giving categories replaces the
saved choice. Nothing is ever uninstalled.

- **Lists in the repo, choice on the machine.** The package lists are shared across
  machines, which subset a machine wants is not, so it stays out of both repos.
- **A re-run must not widen a subset.** Without a saved choice, re-running the one-liner
  or `setup.sh` would fall back to everything.
- **No automatic cleanup.** Pruning what a deselected category lists would also remove
  packages installed by hand.

## Structure

### Two repos, private layers

- `~/.dotfiles` (public): all tool configs.
- `~/.dotfiles-private` (private): sensitive and machine-specific overrides.

The private repo's `link.sh` links its files into the public repo's `local/` directories,
layer by layer: `shared/` > `<platform>/` (`macos/`, `linux/`, or `wsl/`) >
`machines/<hostname>/` (lowercase, if present). `setup.sh` runs it before installing
packages and creating home symlinks, so private packages and overrides exist by then.

Layers add files, they do not override each other: `link.sh` skips a target that already
exists, so a path present in two layers keeps the earlier layer's link. Only `--force`
lets the later layer replace it.

### Symlink chain

How a private override reaches `$HOME`, with the git identity as example:

```text
~/.dotfiles-private/shared/git/local/.gitconfig.local   [real file]
         |
         | link.sh (private -> public)
         v
~/.dotfiles/git/local/.gitconfig.local                  [symlink]
         |
         | setup.sh (public -> home)
         v
~/.gitconfig.local                                      [symlink]
         ^
         | included by
~/.gitconfig -> ~/.dotfiles/git/.gitconfig               [symlink]
```

### Components

| Path | Role |
|------|------|
| `bootstrap.sh` | Fresh machine: category selection, prerequisites, SSH key, Homebrew, clones, then `setup.sh` |
| `setup.sh` | Packages, private linking, home symlinks, post-install, `--doctor`. Safe to re-run |
| `symlinks.conf` | Home symlink map, one `source target [platform]` per line, platform `macos`, `linux`, or `wsl`. Plain text, no templating |
| `packages/` | A Brewfile per category, plus `apt.txt` and `apt.extra.txt` for Linux and WSL |
