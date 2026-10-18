# Installation Guide

Design rationale: [Setup Architecture](setup-architecture.md).

## Full Setup

Clone both repos, then run setup:

```bash
git clone git@github.com:DreamTimeZ/.dotfiles.git ~/.dotfiles
git clone <private-repo-url> ~/.dotfiles-private
cd ~/.dotfiles
./setup.sh --all
```

This installs all packages, links private configs into the public repo, creates home
symlinks, and initializes plugin managers. The private repo must be cloned first so
that local overrides (git user identity, SSH hosts, shell aliases) are available when
symlinks are created.

## Minimal Setup (Without Private Repo)

```bash
git clone https://github.com/DreamTimeZ/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh --all
```

Works without the private repo. You get a functional shell, editor, and tools, but
without machine-specific configs. Add the private repo later and re-run:

```bash
git clone <private-repo-url> ~/.dotfiles-private
./setup.sh --all
```

## Prerequisites

- **git** (to clone the repositories)
- **[Homebrew](https://brew.sh)** (required for package installation on all platforms)

## Setup Options

```bash
./setup.sh                     # Interactive: choose package categories
./setup.sh --all               # Full setup (all packages + symlinks)
./setup.sh core cli            # Install specific categories only
./setup.sh --link-only         # Only create symlinks (no packages)
./setup.sh --link-only --force # Replace existing files and symlinks, never directories (no backup)
./setup.sh --packages-only     # Only install packages (no symlinks)
./setup.sh --doctor            # Check system health
./setup.sh --unlink            # Remove all managed symlinks
./setup.sh --dry-run --all     # Preview what would happen
```

### Package Categories

| Category | Purpose | Package list |
|----------|---------|--------------|
| `core`   | Shell, git, tmux, plugin manager, history, navigation | [`Brewfile.core`](../packages/Brewfile.core) |
| `cli`    | Modern CLI replacements, JSON/YAML tools, viewers, system monitors | [`Brewfile.cli`](../packages/Brewfile.cli) |
| `dev`    | Editor, runtimes, git and lint tooling | [`Brewfile.dev`](../packages/Brewfile.dev) |
| `extra`  | Benchmarking, code stats, document conversion, media (ffmpeg, yt-dlp), OCR, network and disk tools | [`Brewfile.extra`](../packages/Brewfile.extra) |
| `macos`  | Hammerspoon, Karabiner-Elements, espanso, plus macOS CLI tools (macOS only) | [`Brewfile.macos`](../packages/Brewfile.macos) |

The Brewfiles are the source of truth for each category. `apt.txt` holds Ubuntu/Debian system prerequisites, `cargo.txt` the Rust packages.

## Post-Install

Manual steps:

- `setup.sh` only clones TPM, so press `prefix+I` in tmux to install the tmux plugins.
- Linux and WSL: `setup.sh` does not change the login shell. Run `chsh -s /usr/bin/zsh` (the apt-installed zsh, listed in `/etc/shells`).

`setup.sh` does the rest: `sheldon lock --update`, `nvim --headless "+Lazy! sync" +qa`, and
permissions (`~/.ssh` and `~/.gnupg` 700, their config files 600).

## Espanso (Text Expansion)

Espanso configs come from the private repo. Link targets per platform, and the
manual WSL step, are in the [Espanso README](../espanso/README.md).

## Health Check

Run `./setup.sh --doctor` to verify:

- All expected symlinks exist and point to correct targets
- Required and recommended tools are installed
- Private repo is linked
- SSH/GPG directory permissions are correct
- Plugin managers are initialized

## Local Override Files

These files come from the private repo and are symlinked into `local/` directories:

- `git/local/.gitconfig.local` - Git user info (symlinked to `~/.gitconfig.local`)
- `ssh/local/config.local` - SSH hosts (symlinked to `~/.ssh/config.local`)
- `zsh/config/modules/local/*.zsh` - Shell functions, aliases, exports
- `hammerspoon/modules/hotkeys/config/local/*` - Hotkey mappings (macOS)
- `espanso/local/{config,match}/*` - Text expansion configs
- `nilesoft/local/*` - Context menu configs (Windows)
