# Installation Guide

Design rationale: [Setup Architecture](setup-architecture.md).

## Full Setup

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/DreamTimeZ/.dotfiles/main/bootstrap.sh)" -- <private-repo-url>
```

- `<private-repo-url>` is the SSH form, `git@github.com:<owner>/<repo>.git`. `DOTFILES_PRIVATE_URL` in the environment works instead.
- Run it with `bash -c` as shown, never `curl | bash`: with stdin not a terminal it skips the category question and the private repo.
- Category words may follow the URL and skip the question: `core cli`, or `-extra` for all but `extra` ([Category Selection](#category-selection)). The bootstrap rejects `setup.sh` options.
- To review the script first: `curl -fsSLO https://raw.githubusercontent.com/DreamTimeZ/.dotfiles/main/bootstrap.sh`, then `bash bootstrap.sh <private-repo-url>`.

What it does, in order:

1. Asks which package categories to install, unless given ([rules](#category-selection)).
2. Linux and WSL: apt-installs `build-essential procps curl file git openssh-client` if missing.
3. SSH key, only with a private URL, a terminal, and no `~/.dotfiles-private`: creates `~/.ssh/github` if missing (passphrase prompt), adds it to the ssh-agent (macOS Keychain on macOS), and pins GitHub's host key in `~/.ssh/known_hosts` after a fingerprint check. Unless GitHub already accepts an existing key, it prints the public key (copied to the clipboard on macOS), opens <https://github.com/settings/ssh/new>, waits for Enter, and checks access, offering retry or skip. Without a reachable ssh-agent it warns, and ssh asks for the passphrase at the check and at each clone.
4. Installs Homebrew if missing (on macOS this brings the Command Line Tools and git).
5. Clones both repos over SSH (an existing https clone of `~/.dotfiles` is switched to SSH). Without step 3, or after a skip, it clones only the public repo over https. Linux and WSL clone before step 4, since apt brought git.
6. Runs `~/.dotfiles/setup.sh`: the private repo's `link.sh` first, then packages, home symlinks, and [post-install](#post-install).

Questions come in the first minutes (the selection, the sudo password for apt on Linux and WSL, the key passphrase and GitHub page, the Homebrew installer's confirmation and password), then none for a long stretch. Near the end: on macOS the login password for each app with a system installer (Homebrew asks every time by design) and the App Store sign-in, and the private repo's post-install may ask a few.

Re-running the one-liner finishes a half-done setup, a subset install included: every step skips what exists, and the question returns with the saved choice as the default. It never pulls an existing `~/.dotfiles` (run `git -C ~/.dotfiles pull` first) and refuses to run as root.

macOS: skip the Homebrew installer's advice to add its `shellenv` line to `~/.zprofile`. The linked `~/.zprofile` already puts Homebrew on PATH. Appending would edit the repo file, or block the link if `~/.zprofile` is not linked yet.

## Minimal Setup (Without Private Repo)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/DreamTimeZ/.dotfiles/main/bootstrap.sh)"
```

Same steps without the SSH key, cloning only the public repo over https. Category words still work after `--`. Without the private repo, git has no user identity, Espanso stays unconfigured, and Hammerspoon uses its default mappings. To add it later, re-run with `-- <private-repo-url>`.

## Prerequisites

- `bash` and `curl`, as a non-root user with sudo rights
- macOS, or Ubuntu/Debian on Linux and WSL (`setup.sh` uses apt and dpkg)
- WSL: Windows Terminal recommended
- Full setup: a GitHub account with access to the private repo

The bootstrap installs git and [Homebrew](https://brew.sh), which every platform needs for the packages.

## Setup Options

```bash
cd ~/.dotfiles
./setup.sh                      # saved selection, else ask (default all)
./setup.sh --all                # all categories, saved
./setup.sh core cli             # only these (core,cli works too), saved
./setup.sh -extra               # all but extra, saved
./setup.sh --select             # ask again and save, install nothing
./setup.sh --select core,dev    # save without asking, install nothing
./setup.sh --skip gpg,bin       # leave out these symlink groups (repeatable)
./setup.sh --only shell,git,ssh # link only these groups (repeatable)
./setup.sh --link-only          # symlinks only
./setup.sh --packages-only      # packages only
./setup.sh --link-only --force  # replace files and symlinks at link targets
./setup.sh --doctor             # health check
./setup.sh --unlink             # remove all managed symlinks
./setup.sh --update             # update Claude skills
./setup.sh --dry-run            # show the plan and actions, never asks or saves
./setup.sh --help               # every option, category, and symlink group
```

- An existing file, or a symlink pointing elsewhere, at a link target is skipped with a warning. `--force` replaces both (no backup, also passed to the private `link.sh`), never a directory: remove that by hand.
- `setup.sh` installs what is missing. It never upgrades Homebrew packages (`brew bundle --no-upgrade`, the zsh function `update` does), and never uninstalls, deselecting a category included. The apt step on Linux does upgrade a listed package that has a newer candidate.

### Category Selection

- A word is a category, `all`, or `-<category>` to leave one out, case-insensitive, separated by spaces or commas. A first word starting with `-` starts from everything, otherwise from nothing.
- Outside macOS, `macos` is an error and `-macos` changes nothing.
- Without words: the saved selection, else one question on a terminal, else everything (not saved). `--dry-run` never asks.
- Words or an answer are saved per machine in `~/.config/dotfiles/categories` (under `XDG_CONFIG_HOME` if set).

### Package Categories

| Category | Purpose | Package list |
|----------|---------|--------------|
| `core`   | Shell, git, tmux, plugin manager, history, navigation | [`Brewfile.core`](../packages/Brewfile.core) |
| `cli`    | Modern CLI replacements, JSON/YAML tools, viewers, system monitors | [`Brewfile.cli`](../packages/Brewfile.cli) |
| `dev`    | Editor, runtimes, git and lint tooling | [`Brewfile.dev`](../packages/Brewfile.dev) |
| `extra`  | Benchmarking, code stats, document conversion, media (ffmpeg, yt-dlp), OCR, network and disk tools | [`Brewfile.extra`](../packages/Brewfile.extra) |
| `macos`  | Hammerspoon, Karabiner-Elements, espanso, plus macOS CLI tools (macOS only) | [`Brewfile.macos`](../packages/Brewfile.macos) |

Linux and WSL also install `apt.txt` (prerequisites) and, with `extra`, `apt.extra.txt` (ffmpeg and tesseract, whose `Brewfile.extra` entries are macOS-only). Installed on every package run whatever the selection: `apt.txt`, the espanso `.deb` (Linux amd64), and the private `packages/local/Brewfile` when present.

## Post-Install

By hand:

- tmux: press `prefix+I` to install the plugins (`setup.sh` only clones TPM).
- Linux and WSL: `chsh -s /usr/bin/zsh` (the apt-installed zsh, listed in `/etc/shells`). `setup.sh` leaves the login shell unchanged.

A full `setup.sh` run (not `--link-only` or `--packages-only`) ends with: `sheldon lock --update`, the TPM and Excalidraw diagram skill clones, `mise install`, the Excalidraw render pipeline, `nvim --headless "+Lazy! sync" +qa`, permissions (`~/.ssh` and `~/.gnupg` 700, their config files 600), then the private repo's `post-install.sh` when present.

## Espanso (Text Expansion)

Configs come from the private repo. Link targets and the manual WSL step: [Espanso README](../espanso/README.md). On Linux (not WSL) `setup.sh` installs the espanso `.deb` for the current session type (X11 or Wayland), on amd64 only (upstream publishes no other architecture, elsewhere it skips with a message). On Wayland it then grants espanso `cap_dac_override` (`sudo setcap`), as espanso's install docs require.

## Health Check

`~/.dotfiles/setup.sh --doctor` checks the managed symlinks (Espanso included), required and recommended tools, the private repo and its `link.sh`, mode 700 on `~/.ssh` and `~/.gnupg`, plugin managers, and mise tools. A symlink whose source is missing, like a `local/` file without the private repo, is skipped, not flagged.

## Local Override Files

The private repo's `link.sh` links these into the public repo's `local/` directories:

- `git/local/.gitconfig.local` - git user identity, linked to `~/.gitconfig.local`
- `ssh/local/config.local` - SSH hosts, linked to `~/.ssh/config.local`
- `ollama/local/server.json` - Ollama server settings (macOS), linked to `~/.ollama/server.json`
- `packages/local/Brewfile` - private packages (macOS)
- `zsh/config/local/zprofile.pre.zsh` - sourced at the start of `zsh/.zprofile`
- `zsh/config/modules/local/*.zsh` - shell functions, aliases, exports
- `hammerspoon/modules/hotkeys/config/local/*` - hotkey mappings (macOS)
- `espanso/local/{config,match}/*` - text expansion configs
- `nilesoft/local/*` - context menu configs (Windows)
