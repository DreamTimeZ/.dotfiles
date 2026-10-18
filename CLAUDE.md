# CLAUDE.md

## Commands
- `zsh -i -c 'whence -w <function>'` - Confirm a change loads with the full interactive config. In the Claude Code sandbox, `nice(5) failed` and `can't change option: zle` are expected noise.
- Symlink mappings live in `symlinks.conf`. Edit there instead of running `ln`: `setup.sh` creates parent dirs.

## Architecture
- Sheldon, mise, zoxide and atuin init output is cached in `~/.cache/zdotfiles-init/<name>.zsh`. Changing an init command's arguments does not invalidate it: delete that cache file.
- Karabiner-Elements rewrites `karabiner.json` in its own formatting on every settings change, so a GUI change can produce a formatting-only diff.
- Never commit machine-specific paths to the main configuration.
