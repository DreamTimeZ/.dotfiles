# Installation Guide

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
git clone git@github.com:DreamTimeZ/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh --all
```

Works without the private repo. You get a functional shell, editor, and tools, but
without machine-specific configs. Add the private repo later and re-run:

```bash
git clone <private-repo-url> ~/.dotfiles-private
./setup.sh --link-only --force
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
./setup.sh --link-only --force # Recreate all symlinks
./setup.sh --packages-only     # Only install packages (no symlinks)
./setup.sh --doctor            # Check system health
./setup.sh --unlink            # Remove all managed symlinks
./setup.sh --dry-run --all     # Preview what would happen
```

### Package Categories

| Category | Contents |
|----------|----------|
| `core`   | zsh, git, tmux, sheldon, fzf, zoxide, atuin |
| `cli`    | bat, eza, fd, ripgrep, jq, yq, glow, tealdeer, grc |
| `dev`    | mise, lazygit, gh, neovim, gitleaks, uv, shellcheck, shfmt |
| `extra`  | hyperfine, scc, pandoc, yt-dlp, nmap |
| `macos`  | Hammerspoon, Karabiner Elements (macOS only) |

Package lists are in `packages/` (Brewfile format for brew, plain text for apt and cargo).

## Post-Install

`setup.sh` handles these automatically, but for reference:

- **Sheldon**: `sheldon lock --update` (zsh plugin lockfile)
- **TPM**: Cloned to `~/.tmux/plugins/tpm/`, press `prefix+I` in tmux to install plugins
- **Neovim**: `nvim --headless "+Lazy! sync" +qa` (plugin sync)
- **Permissions**: `~/.ssh` (700), `~/.gnupg` (700), config files (600)

## Espanso (Text Expansion)

Espanso configs come from the private repo. On macOS/Linux, symlinks are created
in `~/.config/espanso/`. On WSL, use `temporary-link.bat` from the private repo
to create Windows-side NTFS symlinks (run as admin).

## LaunchAgents (macOS)

```bash
mkdir -p ~/Library/LaunchAgents
for plist in ~/.dotfiles/launchagents/*.plist; do
    [ -f "$plist" ] || continue
    ln -sf "$plist" ~/Library/LaunchAgents/
    launchctl unload "$plist" 2>/dev/null || true
    launchctl load "$plist"
done
```

## Health Check

Run `./setup.sh --doctor` to verify:
- All expected symlinks exist and point to correct targets
- Required and recommended tools are installed
- Private repo is linked
- SSH/GPG directory permissions are correct
- Plugin managers are initialized

## Architecture

See [setup-architecture.md](setup-architecture.md) for the design rationale.

## Local Override Files

These files come from the private repo and are symlinked into `local/` directories:

- `git/local/.gitconfig.local` - Git user info (symlinked to `~/.gitconfig.local`)
- `ssh/local/config.local` - SSH hosts (symlinked to `~/.ssh/config.local`)
- `zsh/config/modules/local/*.zsh` - Shell functions, aliases, exports
- `hammerspoon/modules/hotkeys/config/local/*` - Hotkey mappings (macOS)
- `espanso/local/{config,match}/*` - Text expansion configs
- `nilesoft/local/*` - Context menu configs (Windows)
