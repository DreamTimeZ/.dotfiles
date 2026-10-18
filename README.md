# .dotfiles

Modular dotfiles for macOS, Linux, and Windows (WSL), installed and linked by one script: `setup.sh`.

## Prerequisites

- git
- [Homebrew](https://brew.sh) on every platform: most packages install through it
- Linux and WSL: Ubuntu or Debian (`setup.sh` uses apt and dpkg)
- WSL: Windows Terminal recommended

`setup.sh` installs the rest, including zsh, tmux, and sheldon.

## Quick Install

```bash
git clone https://github.com/DreamTimeZ/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh --dry-run --all   # preview, changes nothing
./setup.sh --all
./setup.sh --doctor          # verify symlinks, tools, and permissions
```

To install only some package categories (`core`, `cli`, `dev`, `extra`, `macos`), pass them instead of `--all`. All symlinks are still created:

```bash
./setup.sh core cli dev
```

`./setup.sh --help` lists every option, category, and symlink group. Existing files at link targets are skipped with a warning. `--force` replaces files and symlinks without a backup, never directories.

On a fresh Mac, Homebrew's installer has you append its `shellenv` line to `~/.zprofile`. Delete that file before `./setup.sh --all` so the linked `.zprofile` takes its place. It puts Homebrew on `PATH` itself.

On Linux and WSL, `setup.sh` does not change the login shell. Afterwards, run `chsh -s /usr/bin/zsh` (the apt-installed zsh, listed in `/etc/shells`).

Full guide: [Installation Guide](docs/installation.md).

### Without the private repo

`setup.sh` works without `~/.dotfiles-private`, which supplies the machine-specific `local/` files: git user identity, private SSH hosts, shell modules, Hammerspoon hotkey mappings, and Espanso configs. Without it, git has no user identity, Espanso stays unconfigured, and Hammerspoon uses its default mappings. Clone it later and re-run `./setup.sh --all`.

## Components

| Component | What it is | Docs |
| --- | --- | --- |
| Zsh | Modular config, Powerlevel10k, autosuggestions, syntax highlighting, fzf-tab, zoxide, Atuin history | [Zsh](zsh/README.md), [Keybindings](zsh/docs/keybindings.md) |
| Sheldon | Declarative Zsh plugin manager (`zsh/sheldon/plugins.toml`) | [Zsh](zsh/README.md) |
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

## Documentation

- [Installation Guide](docs/installation.md): all options, package categories, local override files
- [Setup Architecture](docs/setup-architecture.md): design rationale for `setup.sh`, private repo layering, symlink chain

## Linting

Pre-commit hooks, configured in `.pre-commit-config.yaml`:

```bash
uv tool install pre-commit   # the only extra tool, the hooks bring shellcheck, markdownlint, and node
pre-commit install           # once per clone
pre-commit run --all-files   # lint everything
pre-commit autoupdate        # bump hook versions
```

- **Hygiene**: trailing whitespace, end-of-file, YAML/TOML/JSON syntax, merge and case conflicts, large files, private keys, shebang and executable-bit consistency.
- **Markdown** (`markdownlint-cli2 --fix`, rewrites files): rules in `.markdownlint.jsonc`, ignores in `.markdownlint-cli2.jsonc`. It skips `.claude/`, `CLAUDE*.md`, and `zsh/config/prompts/` (context files and AI prompt payloads, not docs).
- **Shell**: `shellcheck` on non-zsh shell scripts (`setup.sh`). Shellcheck cannot parse zsh, so zsh files get a `zsh -n` syntax check instead.

## License

[MIT License](LICENSE)
