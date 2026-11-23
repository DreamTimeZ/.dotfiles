# .dotfiles

Modular dotfiles for macOS, Linux, and Windows (WSL), installed and linked by one script.

## Install

Needs `bash`, `curl`, and a non-root user with sudo rights. Linux and WSL: Ubuntu or Debian.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/DreamTimeZ/.dotfiles/main/bootstrap.sh)"
```

It installs git and Homebrew, clones this repo to `~/.dotfiles`, and runs `setup.sh`, which installs packages and creates the symlinks. First it asks which package categories to install (Enter takes the default, everything on a fresh machine). Questions come in the first minutes and near the end, the long middle runs unattended.

Optional arguments after `--`:

| Append | Effect |
| --- | --- |
| `-- core cli` | Only these categories, no question. All: `core`, `cli`, `dev`, `extra`, `macos` |
| `-- -extra` | Every category except `extra` |
| `-- git@github.com:<owner>/<repo>.git` | Adds the private repo: sets up the SSH key `~/.ssh/github`, clones both repos over SSH. Categories may follow |

- Run it with `bash -c` as shown, never `curl | bash`: piped, it skips the category question and the private repo.
- Re-running finishes a half-done setup, with the saved categories as the default. It never pulls an existing `~/.dotfiles`: run `git -C ~/.dotfiles pull` first.
- Fresh Mac: skip Homebrew's advice to add its `shellenv` line to `~/.zprofile`. The linked `.zprofile` puts Homebrew on PATH itself.

Afterwards:

```bash
~/.dotfiles/setup.sh --doctor   # verify symlinks, tools, and permissions
~/.dotfiles/setup.sh --help     # every option, category, and symlink group
chsh -s /usr/bin/zsh            # Linux and WSL: setup.sh leaves the login shell unchanged
```

Without the private repo (`~/.dotfiles-private`, the machine-specific `local/` files), git has no user identity, Espanso stays unconfigured, and Hammerspoon uses its default mappings.

All options and steps: [Installation Guide](docs/installation.md). Design rationale: [Setup Architecture](docs/setup-architecture.md).

## Components

| Component | What it is | Docs |
| --- | --- | --- |
| Zsh | Modular config, Sheldon plugins, Powerlevel10k, autosuggestions, syntax highlighting, fzf-tab, zoxide, Atuin history | [Zsh](zsh/README.md), [Keybindings](zsh/docs/keybindings.md) |
| mise | Runtime versions for Python, Node, pnpm, uv (`mise/global.toml`) | |
| Neovim | Lua config, lazy.nvim, Treesitter, Telescope | [Neovim](nvim/neovim.md) |
| Tmux | `Ctrl+a` prefix, TPM plugins, session save and restore | [Cheatsheet](tmux/CHEATSHEET.md) |
| Git | Public `.gitconfig` that includes private `~/.gitconfig.local` | |
| SSH | Public config that includes private `~/.ssh/config.local`, keys added to the agent on first use (macOS Keychain) | |
| GPG | GnuPG and gpg-agent config | [GPG](gpg/README.md) |
| Ghostty | Terminal emulator (macOS), supersedes iTerm2 | [iTerm2 (legacy)](docs/iterm2.md) |
| Hammerspoon | macOS hotkeys, modals, and window management | [Hammerspoon](hammerspoon/README.md) |
| Karabiner | Keyboard remapping (macOS) | |
| Espanso | Text expansion (macOS, Linux, Windows) | [Espanso](espanso/README.md) |
| Nilesoft Shell | Windows context menu | [Nilesoft](nilesoft/README.md) |
| `bin/` | Scripts linked into `~/.local/bin`: `wifi-qr`, `gpg-backup`, `gpg-restore`, `api-keys-setup` (macOS) | [API keys](docs/api-keys-security.md) |

## Development

```bash
uv tool install pre-commit          # the hooks bring shellcheck, markdownlint, and node
pre-commit install                  # once per clone
pre-commit run --all-files          # lint everything, markdownlint --fix rewrites files
tests/test-bootstrap.sh             # bootstrap.sh against stubs, no network, temp HOME
tests/test-setup-selection.sh       # setup.sh category selection against stubs
tests/test-bootstrap-container.sh   # full run in ubuntu:24.04 amd64, needs Docker, slow on Apple Silicon
tests/test-bootstrap-container.sh --private <path>   # same, with a local copy of the private repo
```

CI runs both stub suites on Ubuntu (bash 5) and macOS (bash 3.2), plus the container test. Zsh tests: [Zsh](zsh/README.md#tests).

## License

[MIT](LICENSE)
