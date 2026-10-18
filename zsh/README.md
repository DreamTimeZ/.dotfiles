# Zsh

Modular zsh config with Powerlevel10k, Sheldon plugins, Atuin history, and fzf. `setup.sh` links `.zshrc`, `.zprofile`, `sheldon/plugins.toml`, and `config/atuin/config.toml`.

## Load Order

`.zshrc` sources `config/helpers.zsh`, then in order:

1. `exports.zsh`: environment and shell options
2. `plugins.zsh`: Sheldon plugins (`sheldon/plugins.toml`, per-tool setup in `sheldon/*.zsh`)
3. `modules.zsh`: every `modules/functions/NN-*.zsh` in numeric order, then any unprefixed `*.zsh` there
4. `keybindings.zsh`: see [Keybindings](docs/keybindings.md), or run `kb`
5. `aliases.zsh`
6. `local.zsh`: every `modules/local/*.zsh`, last, so it overrides anything above

## Functions

Run `zh` to browse and search every alias, function, export, and keybinding.

| Module | Commands |
| --- | --- |
| `00-core` | `notify`, `retry`, `confirm`, `mkdirp`, `scratch` |
| `05-clipboard` | `pbcopy` / `pbpaste` on Linux and WSL |
| `10-navigation` | `mkcd`, `dusage`, `ffind`, `fdir` |
| `15-network` | `ip-local`, `lan-scan`, `net-check`, `sniff`, `nscan` |
| `16-websearch` | `google`, `ghs`, `yt`, `so`, `scholar`, `semscholar`, `xarchive`, `pypi`, `npm-search`, `dockerhub` |
| `20-git` | `dirty`, `fbr`, `fgf` |
| `30-process` | `fpkill`, `fh` |
| `40-python` | `venv` |
| `45-tmux` | `dev` |
| `50-webserver` | `serve` |
| `55-media` | `compress-video` |
| `60-system` | `update`, `update_mise`, `update_sheldon`, `update_claude_skills`, `poweroff` (macOS) |
| `65-introspection` | `zh` |
| `70-services` | `ollama-start`, `ollama-stop`, `ollama-restart`, `ollama-status` |
| `75-knowledge` | `yt2note`, `ytt`, `ytc` |
| `80-colorization` | `grc` wrappers for `ping`, `dig`, `ps`, and others |

Functions that need an external tool (fzf, ffmpeg, ollama, yt-dlp, grc) are only defined when it is installed.

## Customization

Put machine-specific `.zsh` files in `config/modules/local/` (supplied by the private repo). See `example.zsh.template` there. `use_interactive_file_ops` makes `cp`, `mv`, and `rm` interactive for the session.

## Logging and Profiling

- `ZDOTFILES_LOG_LEVEL`: 0 silent, 1 error, 2 warn, 3 info. `.zprofile` sets 0, `.zshrc` sets 3.
- `source ~/.dotfiles/zsh/profile-zsh.zsh`: per-module startup timings
- `hyperfine 'zsh -i -c exit' --warmup 3`: total startup time
