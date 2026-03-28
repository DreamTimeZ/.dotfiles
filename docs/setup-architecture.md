# Setup Architecture

## Decision: Shell-based setup over chezmoi

**Date:** 2026-03-28
**Status:** Accepted

## Context

The dotfiles system uses a two-repo architecture:
- `~/.dotfiles` (public) contains all tool configurations
- `~/.dotfiles-private` (private) contains sensitive and machine-specific overrides

Private configs are layered (`shared/` > `platform/` > `machines/hostname/`) and symlinked into the public repo's `local/` directories via `link.sh`. Public configs are then symlinked from `~/.dotfiles/` into `$HOME`.

The missing pieces were:
- Automated symlinks from public repo to `$HOME` (was manual `ln -sf` commands)
- Package installation with category selection
- System health checks

## Alternatives Considered

### chezmoi

**Advantages:**
- One-command bootstrap (`chezmoi init --apply`)
- Built-in encryption (age/gpg) and 17+ password manager integrations
- Drift detection (`chezmoi verify`), diagnostics (`chezmoi doctor`)
- `run_once_` scripts with state tracking
- Atomic file writes

**Why we did not adopt it:**

The decisive reasons (why chezmoi's value doesn't apply here):

- **We don't store secrets in dotfiles, by design.** API tokens, SSH keys, and GPG keys are generated per-device, never shared across machines. This means revocation is granular (one compromised machine = one revoked key), blast radius is smaller, and the audit trail is clear. chezmoi's encryption and password manager integration are its strongest differentiators, but they solve a problem we deliberately avoid.
- **Encrypted secrets are still less secure than no secrets.** Even with age/GPG encryption, the ciphertext is exfiltrable. If someone gets the repo, they have the encrypted blobs forever and can brute-force or wait for a key leak. Zero ciphertext beats any ciphertext. chezmoi's secret management is harm reduction for users who would otherwise commit tokens in plaintext. It is not a best practice.
- **Extra dependency with no payoff.** The current system depends on bash, ln, find, hostname, uname (present on every Unix system, always will be). chezmoi adds a Go binary that must be installed before anything else can be set up (chicken-and-egg on a fresh machine). Fewer dependencies means less breakage surface across OS upgrades and a longer-lived setup.
- **Drift detection is irrelevant here.** On a personal machine with one user, config drift is rare and usually intentional. `chezmoi verify` shines in fleet/team contexts, not single-user dotfiles.

Technical drawbacks (annoyances, not dealbreakers on their own):

- **Paradigm mismatch.** chezmoi copies files instead of symlinking. Programs that modify their own config (espanso, karabiner) would need `chezmoi re-add` after every change. With symlinks, changes are instant.
- **Two-repo is a second-class citizen.** chezmoi is designed for a single source repo. The public/private split works via `.chezmoiexternal` but files from the external repo show as "unmanaged" in `chezmoi diff`.
- **Layering has no direct equivalent.** Our `shared/ > platform/ > machine/` layering is structural and implicit. In chezmoi, this becomes scattered Go template conditionals across individual files.
- **Source directory is unreadable.** `private_dot_ssh/private_encrypted_id_rsa.tmpl` instead of `.ssh/id_rsa`. Formatters and linters (shellcheck, shfmt) choke on `{{ }}` template delimiters.
- **Editing friction.** Must use `chezmoi edit` or remember to `chezmoi add` after editing. Forget, and `chezmoi apply` overwrites your changes.
- **Big-bang migration.** The migration plan is 600+ lines. Hard to do incrementally.

**Zero performance difference.** Both approaches have zero shell startup overhead. chezmoi runs only at apply time. Our setup.sh runs only when invoked.

### yadm

**Why not:** yadm wraps Git around `$HOME` directly, which conflicts with the `~/.dotfiles/` directory pattern. Its alternates system (filename suffixes like `##os.linux`) is less expressive than our directory-based layering for the platform/machine override system. No external repo support for the public/private split.

### GNU stow

**Why not:** Directory structure doesn't match stow conventions (e.g., `nvim/init.lua` should map to `~/.config/nvim/init.lua`, not `~/nvim/init.lua`). Would need restructuring. Adds no value over the current symlink approach since it can't do templating, platform detection, or external repos.

## Solution: Enhanced shell-based setup

Three new files fill the gaps without introducing new tool dependencies:

### `setup.sh`
Single entry point for bootstrapping and managing dotfiles.
- Installs packages by category (interactive selection or flags)
- Creates symlinks from declarative config
- Runs `~/.dotfiles-private/link.sh` if the private repo exists
- Post-install tasks: sheldon lock, TPM, neovim plugins, permissions
- `--doctor` flag for health checks
- `--dry-run`, `--force`, `--unlink` for safe operation
- Idempotent (safe to run repeatedly)

### `symlinks.conf`
Declarative symlink map. Each line: `source  target  [platform_filter]`.
Plain text, auditable, no templating. Platform filter restricts to `macos`, `linux`, or `wsl`.

### `packages/`
Package lists by category (Brewfile format for brew, plain text for apt/cargo).
Categories: `core`, `cli`, `dev`, `extra`, `macos`.
`setup.sh` runs `brew bundle` for each selected category's Brewfile.

## Flow

```
Fresh machine:
  1. git clone <public-repo> ~/.dotfiles
  2. cd ~/.dotfiles && ./setup.sh --all
  3. (optional) git clone <private-repo> ~/.dotfiles-private
  4. (optional) ~/.dotfiles-private/link.sh --force

Existing machine:
  ./setup.sh --link-only        # just refresh symlinks
  ./setup.sh --doctor           # check health
  ./setup.sh dev extra          # add more packages
```

## Symlink chain

```
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
